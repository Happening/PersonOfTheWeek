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
Plugin = require 'plugin'
Server = require 'server'
Social = require 'social'
Time = require 'time'
Ui = require 'ui'
{tr} = require 'i18n'
		
exports.render = !->

	unless period = Db.shared.get('cfg','period')
		# should only happen for dev group
		Dom.text tr "Not configured yet."
		return
	userId = Plugin.userId()

	Dom.section !->
		Dom.style Box: "middle center"
		
		current = Db.shared.get('current')

		renderImage current?.photo, 34, 'fastforward'

		Dom.div !->
			Dom.style
				Flex: 1
				marginLeft: '12px'
			if current
				Dom.h4 tr "who should be..."
				Dom.h3 Config.awardName(current.what, period) + '?'
				if !current.votes?[userId]
					Ui.button tr "Vote now!"

				Time.deltaText current.endTime, [
					60*60, 60*60, "%1 hour|s remaining"
					40, 60, "%1 minute|s remaining"
					10, 9999, "almost no time"
				]
			else
				Dom.h3 tr "Start a new vote..."
		
		Dom.onTap !->
			if current
				selectMemberModal()
			else
				selectTopicModal()

			
	###

	if !Page.state.peek(0)
		Page.state.set 0, Db.shared.peek('roundcounter')

	Obs.observe !->
		roundId = +Page.state.get(0)
		Page.state.set 'isMain', true
		Event.showStar tr("this round")

		if roundId is Db.shared.get('roundcounter')
			Event.markRead [] # clear top-level events (left by previous versions of the plugin)

		if roundId is Db.shared.get('roundcounter') and Db.shared.get('votesopen')
			renderPending roundId
		else
			renderWinner roundId
		
		Dom.div !->
			Dom.style margin: '25px 0 0'
			Social.renderComments
				path: [roundId]
				closed: roundId isnt Db.shared.get('roundcounter')
				render: (comment) !->
					if comment.s
						Dom.div !->
							Dom.style margin: '6px 0 6px 56px', fontSize: '70%'

							Dom.span !->
								Dom.style color: '#999'
								Time.deltaText comment.t
								Dom.text " • "

							Dom.text comment.c
						return true # We're rendering these type of comments

	Page.setFooter !->
		maxId = Db.shared.get('roundcounter')
		return if maxId is 1

		Dom.style
			boxShadow: '0 1px 6px rgba(0, 0, 0, 0.4)'
			backgroundColor: '#fff'
			margin: '8px 8px 12px 8px'
			borderRadius: '2px'
			whiteSpace: 'nowrap'
			color: '#aaa'

		Dom.overflow()
		Dom.div !->
			Dom.style Box: "inline middle center"

			#Obs.observe !->
			#	if !Db.shared.get('winners', maxId)
			#		renderFootItem maxId # no winner of current round yet

			# iterate over all rounds, show those with comments and/or a winner...
			for roundId in [maxId..1] then do (roundId) !->
				if roundWinner = Db.shared.get 'winners', roundId
					renderFootItem roundId, roundWinner
				else if roundId is maxId or Db.shared.get('comments', roundId, 'max')
					renderFootItem roundId

	###


renderImage = (photo, size, icon) !->
		if photo
			Dom.div !->
				Dom.style
					width: size+'px'
					height: size+'px'
					backgroundImage: Photo.url(photo)
					backgroundSize: 'cover'
		else
			Icon.render data: icon, style: { display: 'block' }, size: size


selectTopicModal = (value, handleChange) !->
	period = Db.shared.get('cfg','period')
	Modal.show tr("Start a vote for"), !->
		Dom.style width: '80%'
		Dom.div !->
			Dom.style
				maxHeight: '40%'
				backgroundColor: '#eee'
				margin: '-12px'
			Dom.overflow()

			repeatTime = Plugin.time() - Config.periodTime(period)

			Db.shared.iterate 'cfg', 'topics', (opt) !->
				Ui.item !->
					renderImage opt.get('photo'), 24, 'award4'
					Dom.div !->
						Dom.text opt.get('name')
						Dom.div !->
							Dom.style color: '#999', fontSize: '85%'
							Dom.text opt.get('descr')
					Dom.onTap !->
						Modal.remove()
			, (opt) -> # sort
				last = Db.shared.peek("topics", opt.key(), "last")
				if !last || last < repeatTime
					opt.peek('name')
	, null
	, ['cancel', tr("Cancel")]

selectMemberModal = (value, handleChange) !->
	Modal.show tr("Vote for"), !->
		Dom.style width: '80%'
		Dom.div !->
			Dom.style
				maxHeight: '40%'
				backgroundColor: '#eee'
				margin: '-12px'
			Dom.overflow()

			Plugin.users.iterate (user) !->
				Ui.item !->
					Ui.avatar user.get('avatar')
					Dom.text user.get('name')

					if +user.key() is +value.get()
						Dom.style fontWeight: 'bold'

						Dom.div !->
							Dom.style
								Flex: 1
								padding: '0 10px'
								textAlign: 'right'
								fontSize: '150%'
								color: Plugin.colors().highlight
							Dom.text "✓"

					Dom.onTap !->
						handleChange user.key()
						value.set user.key()
						Modal.remove()
	, (choice) !->
		if choice is 'clear'
			handleChange ''
			value.set ''
	, if value.get() then ['cancel', tr("Cancel"), 'clear', tr("Clear")] else ['cancel', tr("Cancel")]


showAwardSetting = (opt,newThumbs,onTap) !->
	Ui.item !->
		Dom.onTap onTap
		Dom.style
			position: 'relative'
			height: '60px'

		url = newThumbs[opt.key()]
		if !url
			url = opt.get('photo')
			if url
				url = Photo.url(url,200)

		Dom.div !->
			Dom.style
				marginRight: '10px'
				width: '50px'
				height: '50px'
				minWidth: '50px'
				borderRadius: '25px'
				background: "url(#{url}) 50% 50% no-repeat" if url
				backgroundSize: '50px'
		Dom.div !->
			Dom.style Flex: 1
			Dom.text opt.get('name') || tr('Add an award')
			Dom.div !->
				Dom.style
					fontStyle: 'italic'
					fontSize: '80%'
					fontWeight: 'normal'
					color: '#aaa'
				Dom.text opt.get('descr') || ''

exports.renderSettings = !->
	# Once the rounds have been started, do not allow changing
	if !Db.shared or !Db.shared.get('cfg','period')
		periodO = Obs.create 'week'
		Form.addObs 'period', periodO
		Form.box !->
			Dom.style
				fontSize: '125%'
				paddingRight: '56px'
				borderTop: '1px solid #ddd'
				borderBottom: '1px solid #ddd'
			Dom.text "Award period"
			Dom.div Config.awardName("Person",periodO.get())
			Dom.onTap !->
				Modal.show tr('Award period'), !->
					periods = [
						['day', Config.awardName('Person','day')]
						['week', Config.awardName('Person','week')]
						['month', Config.awardName('Person','month')]
					]
					Dom.div !->
						Dom.style margin: '-12px'
						for p in periods
							Ui.item !->
								if p[0] == periodO.get()
									Dom.style fontWeight: 'bold'
									Dom.div !->
										Dom.style
											position: 'absolute'
											width: '50px'
											right: '-10px'
											marginTop: '1px'
											fontSize: '150%'
											color: Plugin.colors().highlight
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
			editAwardSetting opt, newThumbs
		else
			showAwardSetting opt, newThumbs, !->
				e = {}
				e[opt.key()] = true
				editing.set e
		maxId.set(+opt.key()) if +opt.key() > maxId.peek()
	, (opt) -> +opt.key()

	# Auto add an empty item when there are none, or when the last item is complete.
	Obs.observe !->
		opt = topics.get(maxId.get())
		log maxId.get(), opt
		if !opt || (opt.name && opt.descr)
			topics.set maxId.incr(), {}

	Form.addObs 'topics', topics

editAwardSetting = (opt,newThumbs) !->
	Ui.item !->
		Dom.style
			position: 'relative'
			marginBottom: '25px'

		Dom.div !-> # photo
			Dom.style
				position: 'relative'
				verticalAlign: 'top'
				marginRight: '10px'
				border: 'dashed 2px #aaa'
				borderRadius: '25px'
				height: '50px'
				width: '50px'
				minHeight: '50px'
				minWidth: '50px'

			if photo = Photo.unclaimed 'img'+opt.key()
				opt.set 'guid', photo.claim()
				opt.set 'photo', null
				newThumbs[opt.key()] = photo.thumb

			backgroundsize = 'cover'
			url = newThumbs[opt.key()]
			if !url
				url = opt.get('photo')
				if url
					url = Photo.url(url,200)
				else
					url = Plugin.resourceUri 'addphoto.png'
					backgroundsize = '20px'

			Dom.style
				background:  "url(#{url}) 50% 50% no-repeat"
				backgroundSize: backgroundsize
			Dom.onTap !->
				Photo.pick null, null, 'img'+opt.key()

		Dom.div !->
			Dom.style Flex: 1
			Dom.div !->
				Dom.style Box: "middle"
				Form.input
					text: 'Award Title'
					value: opt.peek('name') || ''
					onChange: (v) !-> opt.set 'name', v
					flex: true
				Icon.render
					style: marginLeft: "12px"
					data: 'trash'
					onTap: !-> opt.set(null)

			Dom.div !->
				Form.text
					style: paddingTop: 0
					text: 'Description'
					value: opt.peek('descr') || ''
					onChange: (v) !-> opt.set 'descr', v
					rows: 1

getPhotoUrl = ->
	if key = Db.shared.get('settings', 'photo', 'key')
		Photo.url key, 250
	else if key = Db.shared.get('settings', 'photo')
		Plugin.resourceUri(key)
	else
		Plugin.resourceUri('unknown.jpg')

renderPicture = (roundId) !->
	Dom.div !->
		Dom.style
			margin: '15px auto'
			width: '250px'
		if winner = Db.shared.get('winners', roundId)
			Ui.avatar Plugin.userAvatar(winner),
				style:
					height: '250px'
					width: '250px'
					borderRadius: '250px'
					border: '1px solid #aaa'
					boxShadow: '0 2px 8px #aaa'
				size: 250
		else
			Dom.div !->
				Dom.style
					background: "url(#{getPhotoUrl()}) 50% 50% no-repeat"
					backgroundSize: 'cover'
					width: '250px'
					height: '250px'
					backgroundRepeat: 'no-repeat'
					borderRadius: '125px'
					boxShadow: '0 2px 8px #aaa'
					border: '1px solid #aaa'
		

