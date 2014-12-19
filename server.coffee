Db = require 'db'
Event = require 'event'
Photo = require 'photo'
Plugin = require 'plugin'
Timer = require 'timer'
{tr} = require 'i18n'

exports.onInstall = (config) !->
	if config?
		onConfig config

exports.onConfig = onConfig = (config) !->
	if config?
		if config.usecustom == "true"
			Db.shared.set 'settings', 'title', config.customtitle
			Db.shared.set 'settings', 'description', config.customdescription
			Photo.claim config.photoguid
		else
			Db.shared.set 'settings', 'title', config.title
			Db.shared.set 'settings', 'description', config.description
			Db.shared.set 'settings', 'photo', config.photo
	
	if config.period
		if config.period == 'day'
			voteperiod = 3600 * 4
			totalperiod = 3600 * 24
		else if config.period == 'week'
			voteperiod =  3600 * 24
			totalperiod = 3600 * 24 * 7
		else
			voteperiod = 3600 * 24 * 3
			totalperiod = 3600 * 24 * 30 # Approximately one month
		
		Db.shared.set 'settings', 'period', config.period
		Db.shared.set 'settings', 'voteperiod', voteperiod
		Db.shared.set 'settings', 'totalperiod', totalperiod

	if not Db.shared.get 'nextround'
		exports.start()

exports.getTitle = ->
	settings = Db.shared.get 'settings'
	name = settings.title + tr(' of the ') + periodname (settings.period)

exports.onPhoto = (info) !->
	Db.shared.set 'settings', 'photo', info

exports.client_endRound = !->
	if Plugin.userIsAdmin()
		exports.close()

exports.client_startRound = !->
	if Plugin.userIsAdmin()
		exports.start()

exports.close = !->
	votes = {}
	settings = Db.shared.get 'settings'
	roundnumber = Db.shared.get 'roundcounter'
	for uid in Plugin.userIds()
		v = Db.personal(uid).get('vote')
		if v then votes[v] = (0|votes[v]) + 1
		Db.personal(uid).set('vote', 0)
	
	winner = 0
	for uid, numvotes of votes
		if !Plugin.userName(uid) then continue
		if winner == 0 || numvotes > votes[winner]
			winner = uid

	if winner > 0
		Db.shared.set 'winners', roundnumber, winner

	Db.shared.set 'votesopen', false

	name = settings.title + tr(' of the ') + periodname (Db.shared.get 'settings', 'period')
	Event.create
		unit: 'vote'
		text: tr('The winner for ')+name+tr(' is in!')
		new: ['all']

	# Add a comment as a divider between old and new comments
	if Db.shared.get 'comments', roundnumber
		lastcomment = Db.shared.get 'comments', roundnumber, (Db.shared.get 'comments', roundnumber, 'max'), 'u'
		if lastcomment != 0
			winnername = if winner > 0 then (Plugin.userName winner) else tr('Nobody')
			addComment winnername + tr(' won the award!')

exports.client_vote = (v) !->
	if (Db.shared.get 'votesopen')
		uid = Plugin.userId()
		Db.personal(uid).set('vote', v)

exports.start = !->
	settings = Db.shared.get 'settings'
	voteperiod = Db.shared.get 'settings', 'voteperiod'
	totalperiod = Db.shared.get 'settings', 'totalperiod'

	Timer.cancel()
	Timer.set voteperiod*1000, 'close'
	Timer.set Math.round(voteperiod*1000*0.7), 'votereminder'
	Timer.set totalperiod*1000, 'start'

	if voteperiod >= 86400
		newvoteclose = Math.floor(Plugin.time()/86400) * 86400 + voteperiod
		nextround = Math.floor(Plugin.time()/86400) * 86400 + totalperiod
	else
		newvoteclose = Math.floor(Plugin.time() + voteperiod)
		nextround = Math.floor(Plugin.time() + totalperiod)

	Db.shared.set 'nextround', nextround
	Db.shared.set 'voteclose', newvoteclose
	Db.shared.set 'votesopen', true
	Db.shared.set 'roundcounter', (0|Db.shared.get 'roundcounter') + 1

	name = settings.title + tr(' of the ') + periodname (Db.shared.get 'settings', 'period')
	Event.create
		unit: 'vote'
		text: tr('The votes for ')+name+tr(' have been opened!')
		include: ['all']

exports.votereminder = !->
	settings = Db.shared.get 'settings'
	name = settings.title + tr(' of the ') + periodname (Db.shared.get 'settings', 'period')

	include = []
	for userId in Plugin.userIds() when !Db.personal(userId).get 'vote'
		include.push userId

	Event.create
		unit: 'vote'
		text: tr('Do not forget to vote for ')+name+'!'
		include: include

periodname = (period) !->
	if period == 'day'
		return tr('day')
	else if period == 'week'
		return tr('week')
	else if period == 'month'
		return tr('month')

addComment = (comment) !->
	comment =
		t: 0|Plugin.time()
		u: 0
		s: true
		c: comment

	comments = Db.shared.createRef("comments", Db.shared.get 'roundcounter')
	max = comments.incr 'max'
	comments.set max, comment
