Config = require 'config'
Db = require 'db'
Event = require 'event'
Photo = require 'photo'
Plugin = require 'plugin'
Timer = require 'timer'
{tr} = require 'i18n'


exports.onInstall = (config) !->
	defaults = require('config').getDefault()
	if config
		if !config.period
			config.period = defaults.period
		if !config.topics
			config.topics = defaults.topics
	else
		config = defaults
	onConfig(config)


exports.client_start = (topicId) !->
	if !Db.shared.get('current') and (period = Db.shared.get 'cfg','period') and (topic = Db.shared.get 'cfg', 'topics', topicId)
		time = Config.voteTime(period)
		topic.by = Plugin.userId()
		topic.endTime = Plugin.time() + time
		Db.shared.set 'current', topic
		Timer.set time*1000, 'close'
		Event.create
			text: tr("%1 election started by %2!", Config.awardName(topic.name,period), Plugin.userName())


exports.client_vote = (topic, vote) !->
	if Db.shared.get('current','name')==topic
		Db.shared.set 'votes', Plugin.userId(), vote


ucfirst = (str) ->
	str.substr(0,1).toUpperCase() + str.substr(1)

exports.onUpgrade = !->
	log 'onUpgrade'

exports.onConfig = onConfig = (config) !->
	for id,topic of config.topics
		if !topic.name
			delete config.topics[id]
		else if topic.guid
			topic.name = ucfirst(topic.name)
			topic.descr = ucfirst(topic.descr) if topic.descr
			delete config.topics[id]
			guid = topic.guid
			delete topic.guid
			Photo.claim guid, [id,topic]

	if !!Db.shared and (oldPeriod = Db.shared.get('cfg','period'))
		# changing period is not allowed
		config.period = oldPeriod

	Db.shared.set 'cfg', config


exports.onPhoto = (info, [id,topic]) !->
	topic.photo = info.key
	Db.shared.set 'cfg', 'topics', id, topic


exports.getTitle = ->
	if period = Db.shared.get 'cfg', 'period'
		Config.awardName(tr("Person"), period)


exports.close = !->
	current = Db.shared.get 'current'
	
	votes = {}
	for fromUser,toUser of Db.shared.get('votes')
		votes[toUser] = (votes[toUser]||Math.random()) + 1

	winner = 0
	for toUser, cnt of votes
		if !winner or cnt > votes[winner]
			winner = toUser

	Db.shared.set 'votes', null
	Db.shared.set 'current', null

	log 'winner',winner,current
	return unless winner
	current.winner = winner
	round = Db.shared.incr 'roundMax'
	Db.shared.set 'rounds', round, current
	Db.shared.set 'last', current.name, Plugin.time()

	name = Config.awardName(current.name, Db.shared.get('cfg','period'))
	Event.create
		text: tr('%1 is %2!', Plugin.userName(winner), name)
		# default path, so they always get cleared

