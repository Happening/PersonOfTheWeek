Comments = require 'comments'
Config = require 'config'
Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Form = require 'form'
Icon = require 'icon'
Loglist = require 'loglist'
Modal = require 'modal'
Obs = require 'obs'
Page = require 'page'
Photo = require 'photo'
App = require 'app'
Server = require 'server'
Time = require 'time'
Ui = require 'ui'
{tr} = require 'i18n'


renderTimeLeft = (time) !->
	Time.deltaText time, [
		60*60, 60*60, "%1 hour|s left"
		40, 60, "%1 minute|s left"
		10, 9999, "almost out of time"
	]


renderVoteNow = (current) !->
	userId = App.userId()
	Dom.section !->
		Dom.style Box: "top", padding: '12px'
		renderImage current?.photo, 80

		Dom.div !->
			Dom.style
				Flex: 1
				marginLeft: '12px'
				textAlign: 'right'
			Dom.h3 !->
				Dom.style margin: 0
				Dom.text Config.awardName(current.name, getPeriod())
			Dom.div current.descr
			if Db.shared.get('votes',userId)
				Dom.div !->
					Dom.style fontWeight: 'bold', marginTop: '5px'
					Dom.text tr 'Voting... '
					renderTimeLeft current.endTime
					Dom.text tr "!"
			else
				Ui.button !->
					Dom.style textAlign: 'center', marginRight: 0, display: 'inline-block'
					Dom.text tr "Vote now!"
					Dom.div !->
						Dom.style fontSize: '80%'
						renderTimeLeft current.endTime
		Dom.onTap !->
			selectMemberModal current.name, Db.shared.peek('votes',userId)


renderNewVote = !->
	Ui.top !->
		Dom.style padding: 0
		Dom.div !->
			Dom.style padding: 12
			Dom.h3 tr "Start a new vote..."

		Dom.div !->
			Dom.overflow() # horizontal scrolling
			Dom.style Box: "top"

			periodTime = Config.periodTime(getPeriod())

			Db.shared.iterate 'cfg', 'topics', (opt) !->
				Dom.div !->
					Dom.style
						minWidth: "100px"
						width: "100px"
						textAlign: "center"
						padding: "0 10px 10px 10px"
					renderImage opt.get('photo'), 100
					awardName = Config.awardName(opt.get('name'), getPeriod())
					Dom.div !->
						Dom.text awardName
					Dom.div !->
						Dom.style color: '#999', fontSize: '85%'
						Dom.text opt.get('descr')
					Dom.onTap !->
						Modal.confirm tr("Are you sure you want to know who is %1?",awardName), !->
							Server.sync 'start', opt.key(), !->
								Db.shared.set 'current', opt.get()
			, (opt) -> # filter and sort
				if Obs.timePassed periodTime + (0 | Db.shared.peek("last", opt.get('name')))
					999*Math.random()


periodCache = null # cannot change; cache it!
getPeriod = ->
	periodCache ||= Db.shared.get('cfg','period')


exports.render = !->

	unless getPeriod() # should only happen for dev group
		return Dom.text tr "Not configured yet."

	if showRound = Page.state.get 0
		return renderRoundPage showRound

	if current = Db.shared.get('current')
		renderVoteNow current
	else
		renderNewVote()

	negRoundMax = Obs.create()
	Obs.observe !->
		negRoundMax.set -(Db.shared.get('roundMax')||0)

	Loglist.render negRoundMax, -1, (round) !->
		renderRound -round


renderRoundPage = (num) !->
	Event.showStar tr "this award's messages"
	renderRound num, true
	Comments.enable store: ['comments',num]


renderRound = (num,inPage) !->
	return unless round = Db.shared.get 'rounds', num
	Form.row !->
		Dom.style Box: "middle"
		Ui.avatar App.userAvatar round.winner, size: 42
		Dom.div !->
			Dom.style textAlign: "center", margin: '0 8px', Flex: 1
			Time.deltaText round.endTime
			Dom.h3 !->
				Dom.style margin: 0, color: (if Event.isNew(round.endTime) then '#5b0' else 'inherit')
				Dom.text tr "%1 is %2", App.userName(round.winner), Config.awardName(round.name,getPeriod())
				Event.renderBubble [num], style: margin: '-3px 0 0 8px'
		renderImage round.photo, 42
		if !inPage
			Dom.onTap !->
				Page.nav [num]


renderImage = (photo, size, icon, onTap) !->
	if photo
		url = if photo.indexOf('/')>=0 then photo else Photo.url(photo, size*1.5)
		Dom.div !->
			Dom.style
				width: size+'px'
				height: size+'px'
				backgroundImage: "url(#{url})"
				backgroundSize: 'cover'
				backgroundPosition: '50% 50%'
				borderRadius: (size/2)+'px'
			Dom.onTap onTap if onTap
	else
		Icon.render data: (icon||'award4'), style: { display: 'block' }, size: size, onTap: onTap


selectMemberModal = (topic,oldId) !->
	choose = (newId) !->
		Server.sync 'vote', topic, newId, !->
			Db.shared.set 'votes', App.userId(), newId
	Modal.show tr("Vote for"), !->
		App.users.iterate (user) !->
			Ui.item !->
				Ui.avatar user.get('avatar')
				Dom.text user.get('name')

				if +user.key() is oldId
					Dom.style fontWeight: 'bold'

					Dom.div !->
						Dom.style
							Flex: 1
							padding: '0 10px'
							textAlign: 'right'
							fontSize: '150%'
							color: App.colors().highlight
						Dom.text "✓"

				Dom.onTap !->
					choose +user.key()
					Modal.remove()
	, (choice) !->
		if choice is 'clear'
			choose null
	, if oldId then ['cancel', tr("Cancel"), 'clear', tr("Clear")] else ['cancel', tr("Cancel")]


exports.renderSettings = !->
	# Once the rounds have been started, do not allow changing
	if !Db.shared or !Db.shared.get('cfg','period')
		periodO = Obs.create 'week'
		Form.addObs 'period', periodO
		Form.row !->
			Dom.style
				borderBottom: '1px solid #ddd'
			Dom.div !-> Dom.text "Award period"
			Dom.div Config.awardName("Person",periodO.get())
			Dom.onTap !->
				Modal.show tr('Award period'), !->
					periods = [
						['day', Config.awardName('Person','day')]
						['week', Config.awardName('Person','week')]
						['month', Config.awardName('Person','month')]
					]
					for p in periods
						Ui.item !->
							if p[0] == periodO.get()
								Dom.style fontWeight: 'bold'
								Dom.div !->
									Dom.style
										position: 'absolute'
										right: '12px'
										marginTop: '-4px'
										fontSize: '150%'
										color: App.colors().highlight
									Dom.text '✔'
							Dom.text p[1]
							vp = p[0]
							Dom.onTap !->
								periodO.set vp
								Modal.remove()
				, undefined, ['cancel', tr("Cancel")]

	config = (Db.shared.get('cfg') if Db.shared) || require('config').getDefault()

	editing = Obs.create {}
	topics = Obs.create(config.topics || {})
	maxId = Obs.create 0
	newThumbs = {}

	topics.iterate (opt) !->
		if editing.get opt.key()
			renderSettingsEditAward opt, newThumbs
		else
			renderSettingsShowAward opt, newThumbs, !->
				e = {}
				e[opt.key()] = true
				editing.set e
		maxId.set(+opt.key()) if +opt.key() > maxId.peek()
	, (opt) -> +opt.key()

	# Auto add an empty item when there are none, or when the last item is complete.
	Obs.observe !->
		opt = topics.get(maxId.get())
		if !opt || opt.name
			topics.set maxId.incr(), {}

	Form.addObs 'topics', topics


renderSettingsShowAward = (opt,newThumbs,onTap) !->
	Ui.item !->
		Dom.onTap onTap
		Dom.style
			position: 'relative'
			height: '60px'

		photo = newThumbs[opt.key()]
		if !photo
			photo = opt.get('photo')

		renderImage photo, 50
		Dom.div !->
			Dom.style Flex: 1, marginLeft: '12px'
			Dom.text opt.get('name') || tr('Add an award')
			Dom.div !->
				Dom.style
					fontStyle: 'italic'
					fontSize: '80%'
					fontWeight: 'normal'
					color: '#aaa'
				Dom.text opt.get('descr') || ''


renderSettingsEditAward = (opt,newThumbs) !->
	Ui.item !->
		Dom.style
			position: 'relative'
			marginBottom: '25px'

		if photo = Photo.unclaimed 'img'+opt.key()
			opt.set 'guid', photo.claim()
			opt.set 'photo', null
			newThumbs[opt.key()] = photo.thumb

		backgroundsize = 'cover'
		photo = newThumbs[opt.key()] || opt.get('photo')
		renderImage photo, 50, 'addphoto', !->
			Photo.pick null, null, 'img'+opt.key()

		Dom.div !->
			Dom.style Flex: 1, marginLeft: '12px'
			Dom.div !->
				Dom.style Box: "middle"
				Form.input
					text: 'Award Title'
					value: opt.peek('name') || ''
					onChange: (v) !-> opt.set 'name', v
					flex: true
				Icon.render
					style: marginLeft: "12px"
					data: 'delete'
					onTap: !-> opt.set(null)

			Dom.div !->
				Form.text
					style: paddingTop: 0
					text: 'Description'
					value: opt.peek('descr') || ''
					onChange: (v) !-> opt.set 'descr', v

