Db = require 'db'
Dom = require 'dom'
Event = require 'event'
Form = require 'form'
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

	if !Page.state.peek(0)
		Page.state.set 0, Db.shared.peek('roundcounter')

	Obs.observe !->
		roundId = +Page.state.get(0)
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
			backgroundColor: '#333'
			borderTop: 'solid 1px #666'
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
			Db.shared.iterate 'winners', (winner) !->
				renderFootItem +winner.key(), winner.get()
			, (winner) ->
				-winner.key()
			###

renderFootItem = (roundId, winner) !->

	Dom.div !->
		Dom.style
			display: 'inline-block'
			position: 'relative'
			padding: '6px 8px'
			background: if +Page.state.get(0) == roundId then '#666' else ''

		if winner
			Ui.avatar Plugin.userAvatar(winner),
				style:
					margin: 0
					display: 'inline-block'
		else
			Dom.div !->
				Dom.style
					display: 'inline-block'
					background: "url(#{getPhotoUrl()}) 50% 50% no-repeat"
					backgroundSize: 'cover'
					width: '38px'
					height: '38px'
					backgroundRepeat: 'no-repeat'
					borderRadius: '38px'
					border: '1px solid #aaa'

		Event.renderBubble [roundId], style:
			position: 'absolute'
			top: '15px'
			left: '24px'

		###
		Dom.div !->
			Dom.style
				textAlign: 'center'
				fontSize: '70%'
				margin: '2px 0 0'
			Dom.text '3d ago'
		###
		Dom.onTap !->
			Page.state.set 0, roundId


	###
			Ui.bigImg Plugin.resourceUri('unknown.jpg'), !->
				Dom.style
					display: 'inline-block'
					margin: '5px 2px'
				if state.get() == Db.shared.get 'roundcounter'
					Dom.style
						border: "3px #{Plugin.colors().highlight} solid"
						width: '34px'
						height: '34px'
						borderRadius: '19px'
				else
					Dom.style
						border: '0.8px rgb(170,170,170) solid'
						width: '38px'
						height: '38px'
						borderRadius: '19px'
				r = Db.shared.get 'roundcounter'
				if r != parseInt(state.get())
					Dom.onTap !->
						state.set r
						Page.scroll 0

				Dom.div !->
					Dom.text tr("CUR")
					Dom.onTap !->
						Page.state.set 0, maxId
	###



renderPending = (roundId) !->
	renderTitle tr("%1 of the %2", Db.shared.get('settings', 'title'), periodname())

	Dom.div !->
		Dom.style
			maxWidth: '300px'
			margin: '0px auto'
		Dom.div !->
			Dom.text Db.shared.get 'settings', 'description'
			Dom.style
				textAlign: 'center'
		renderPicture roundId

		personalVote = Obs.create(0|Db.personal.get 'vote')
		Obs.observe !->
			if personalVote.get()
				Dom.div !->
					Dom.style
						margin: '10px'
						borderBottom: '1px solid #666'
						borderTop: '1px solid #666'

					Form.box !->
						Dom.style fontSize: '125%', paddingRight: '56px'
						Dom.text tr("Voted for")
						v = personalVote.get()
						Dom.div !->
							Dom.style color: (if v then 'inherit' else '#aaa')
							Dom.text (if v then Plugin.userName(v) else tr("Nobody"))
						if personalVote.get()
							Ui.avatar Plugin.userAvatar(v), style: position: 'absolute', right: '6px', top: '50%', marginTop: '-20px'
						Dom.onTap !->
							selectMemberModal personalVote, (v) !->
								Server.sync 'vote', v, !->
									Db.personal.set 'vote', v

			else
				Ui.bigButton !->
					Dom.text "Vote now!"
				, !->
					selectMemberModal personalVote, (v) !->
						Server.sync 'vote', v, !->
							Db.personal.set 'vote', v

	Dom.div !->
		Dom.style
			textAlign: 'center'
			fontSize: '0.9em'
			color: '#969696'
			marginBottom: '20px'
			marginTop: '10px'

		Time.deltaText (Db.shared.get 'voteclose'),[
			10*24*60*60, 7*24*60*60, "%1 week|s remaining"
			40*60*60, 24*60*60, "%1 day|s remaining"
			60*60, 60*60, "%1 hour|s remaining"
			40, 60, "%1 minute|s remaining"
			10, 9999, "almost no time"
		]

renderWinner = (roundId) !->
	log 'renderWinner', roundId
	diff = (Db.shared.get 'roundcounter') - roundId
	if not (Db.shared.get 'votesopen')
		diff += 1
	if diff > 1
		timetext = diff + ' ' + (periodname undefined, true) + ' ago'
	else
		timetext = if (Db.shared.get 'settings', 'period') == 'day' then 'yesterday' else 'last ' + periodname()

	winner = Db.shared.get 'winners', roundId
	if winner
		renderTitle Plugin.userName(winner), tr("%1 of %2", Db.shared.get('settings', 'title'), timetext)
		
		Dom.div !->
			Dom.style
				maxWidth: '300px'
				margin: '0px auto'
			renderPicture roundId
			Dom.div !->
				Dom.style
					textAlign: 'center'
				Dom.text Db.shared.get 'settings', 'description'
	else
		renderTitle tr("Unfortunately"), tr("No votes have been cast %1.", timetext)

		Dom.div !->
			Dom.style
				maxWidth: '300px'
				margin: '0px auto'
			renderPicture null

selectMemberModal = (value, handleChange) !->
	Modal.show tr("Vote for"), !->
		Dom.style width: '80%'
		Dom.div !->
			Dom.style
				maxHeight: '40%'
				overflow: 'auto'
				_overflowScrolling: 'touch'
				backgroundColor: '#eee'
				margin: '-12px'

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

hallOfFame = (state) !->
	if Db.shared.get 'winners'
		Dom.h2 !->
			Dom.text tr("Previous winners")

		if Db.shared.get 'votesopen'
			Ui.bigImg Plugin.resourceUri('unknown.jpg'), !->
				Dom.style
					display: 'inline-block'
					margin: '5px 2px'
				if state.get() == Db.shared.get 'roundcounter'
					Dom.style
						border: "3px #{Plugin.colors().highlight} solid"
						width: '34px'
						height: '34px'
						borderRadius: '19px'
				else
					Dom.style
						border: '0.8px rgb(170,170,170) solid'
						width: '38px'
						height: '38px'
						borderRadius: '19px'
				r = Db.shared.get 'roundcounter'
				if r != parseInt(state.get())
					Dom.onTap !->
						state.set r
						Page.scroll 0

		Db.shared.iterate 'winners', (winner) !->
			w = winner.get()
			r = parseInt(winner.key())
			Ui.avatar Plugin.userAvatar(w),
				style:
					display: 'inline-block'
					margin: '5px 2px'
					border: if r is state.get() then "3px #{Plugin.colors().highlight} solid" else 'none'
				onTap: !->
					state.set r
					Page.scroll 0

		, (item) ->
			if +item.key()
				return -item.key()

		# Ui.item !->
		# 	Dom.text tr("Hall of Fame")
		# 	Dom.onTap !->
		# 		Modal.show 'Hall of Fame', hallOfFameModal

hallOfFameModal = !->
	Dom.div !->
		Dom.style
			margin: '10px 0px'
		Dom.text tr('The previous winners of this award:')

	Db.shared.observeEach 'winners', (winner)!->
		diff = (Db.shared.get 'roundcounter') - winner.key()
		Ui.item !->
			Ui.avatar Plugin.userAvatar(winner.get())

			Dom.div !->
				Dom.text Plugin.userName winner.get()

				if diff > 1
					timetext = diff + ' ' + (periodname undefined, true) + ' ago'
				else
					timetext = if (Db.shared.get 'settings', 'period') == 'day' then 'yesterday' else 'last ' + periodname()
				Dom.div !->
					Dom.style
						paddingRight: '50px'
						fontSize: '0.9em'
						color: '#999'
						textAlign: 'right'
					Dom.text timetext

	, (item) !->
		if +item.key()
			return -item.key()

renderTitle = (title, subTitle) !->
	Dom.div !->
		Dom.style
			textAlign: 'center'
			fontWeight: 'bold'
			fontSize: '2em'
		Dom.text title

	if subTitle
		Dom.div !->
			Dom.style
				textAlign: 'center'
				fontWeight: 'bold'
				fontSize: '1.2em'

			Dom.text subTitle


exports.renderSettings = !->
	# Once the rounds have been started, do not allow changing
	if Db.shared
#		if Plugin.userIsAdmin()
#			Dom.h3 !->
#				Dom.text tr("Admin Options")
#			Ui.item !->
#				Dom.text "Start new round now!"
#				Dom.onTap !->
#					Server.sync 'startRound'
#			Ui.item !->
#				Dom.text "End round now!"
#				Dom.onTap !->
#					Server.sync 'endRound'
		if Db.shared.get 'nextround'
			return Dom.text tr("Interested in a different award? You can add another Award plugin!")

	period = Obs.create(if Db.shared then Db.shared.get 'settings', 'period' else 'month')
	selected = Obs.create(false)
	settings = Obs.create()

	Obs.observe !->
		p = Form.hidden 'period', period.get()
		p.value period.get()
		Form.box !->
			Dom.style
				fontSize: '125%'
				paddingRight: '56px'
				borderTop: '1px solid #ddd'
				borderBottom: '1px solid #ddd'
			Dom.text "Vote every"
			Dom.div periodname(period.get())
			Dom.onTap !->
				Modal.show tr('Vote every'), !->
					periods = [
						['day', tr("Day")]
						['week', tr("Week")]
						['month', tr("Month")]
					]
					Dom.div !->
						Dom.style margin: '-12px'
						for p in periods
							Ui.item !->
								if p[0] == period.get()
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
									period.set vp
									Modal.remove()
				, undefined, ['cancel', tr("Cancel")]

		Form.label tr("Select award")
		s = selected.get()
		templates.forEach (template) !->
			Ui.item !->
				Dom.style
					position: 'relative'
					height: '60px'

				Dom.div !->
					Dom.style
						marginRight: '10px'
						width: '50px'
						height: '50px'
						minWidth: '50px'
						borderRadius: '25px'
						background: "url(#{Plugin.resourceUri(template.photo)}) 50% 50% no-repeat"
						backgroundSize: '50px'
					if selected.get() == template.id
						Dom.div !->
							Dom.style
								backgroundColor: 'rgba(220,220,220,0.7)'
								marginTop: '-5px'
								width: '50px'
								height: '50px'
								borderRadius: '25px'
							Dom.div !->
								Dom.style
									position: 'relative'
									width: '50px'
									textAlign: 'center'
									marginTop: '5px'
									fontSize: '35px'
									color: 'black'
								Dom.text '✔'
				Dom.div !->
					Dom.style Flex: 1
					Dom.text template.display
					Dom.div !->
						Dom.style
							fontStyle: 'italic'
							fontSize: '80%'
							fontWeight: 'normal'
							color: '#aaa'
						Dom.text template.description

				Dom.onTap !->
					settings.set('title', template.title)
					settings.set('description', template.description)
					settings.set('photo', template.photo)
					selected.set(template.id)

		customCollapsed = Obs.create(true)
		Ui.item !->
			Dom.style
				position: 'relative'
				minHeight: if customCollapsed.get() then '60px' else '120px'
				marginBottom: '25px'

			if customCollapsed.get()
				Dom.span !->
					Dom.style color: Plugin.colors().highlight
					Dom.text "+ Create your own"
			else
				cte = cde = undefined
				photo = Photo.unclaimed 'titlephoto'
				if photo
					photoguid = photo.claim()
					settings.set 'photoguid', photoguid
					settings.set 'thumb', photo.thumb

				Dom.div !->
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
					if settings.get 'thumb'
						photourl = settings.get 'thumb'
						backgroundsize = 'cover'
					else
						photourl = Plugin.resourceUri 'addphoto.png'
						backgroundsize = '20px'
					Dom.style
						background:  "url(#{photourl}) 50% 50% no-repeat"
						backgroundSize: backgroundsize
					Dom.onTap !->
						Photo.pick null, null, 'titlephoto'

				Dom.div !->
					Dom.style Flex: 1
					Dom.div !->
						cte = Form.input
							name: 'customtitle'
							text: 'Title'
					Form.condition ->
						tr("A title is required") if cte.value() == '' && selected.get() == 'custom'
					Dom.div !->
						cde = Form.text
							name: 'customdescription'
							text: 'Description'
							autogrow: false
					Form.condition ->
						tr("A description is required") if cde.value() == '' && selected.get() == 'custom'

				if selected.get() == 'custom'
					Dom.div !->
						Dom.style
							position: 'absolute'
							left: '21px'
							top: '15px'
							fontSize: '35px'
							color: 'black'
						Dom.text '✔'
				else if cte.value() == '' and cde.value() == ''
						customCollapsed.set true

			Dom.onTap !->
				customCollapsed.set false
				selected.set 'custom'

		Form.condition ->
			tr("A selection is required") if !selected.get()

		Obs.observe !->
			th = Form.hidden 'title'
			ph = Form.hidden 'photo'
			dh = Form.hidden 'description'
			ch = Form.hidden 'usecustom'
			gh = Form.hidden 'photoguid'
			th.value settings.get 'title'
			ph.value settings.get 'photo'
			dh.value settings.get 'description'
			gh.value settings.get 'photoguid'
			ch.value selected.get() == 'custom'

periodname = (period, multiple) !->
	if !period
		period = Db.shared.get 'settings', 'period'

	if period == 'day'
		return if multiple then tr('days') else tr('day')
	else if period == 'week'
		return if multiple then tr('weeks') else tr('week')
	else
		return if multiple then tr('months') else tr('month')


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
		

templates = [
	{title: tr('Panda'), display: tr('The Panda'), description: tr('Too lazy to reproduce, and thus doomed to extinction.'), photo: 'panda.jpg', id: 1},
	{title: tr('Grizzly'), display: tr('The Grizzly'), description: tr('A bear with a terrible temper. Approach at your own risk.'), photo: 'grizzly.jpg', id: 2}
	{title: tr('Peacock'), display: tr('The Peacock'), description: tr('A vain bird that loves to show everyone just how awesome it is.'), photo: 'peacock.jpg', id: 3}
	{title: tr('Puppy'), display: tr('The Puppy'), description: tr('Young, playful, foolish. But at the end of the day, just very cute.'), photo: 'pup.jpg', id: 4}
	{title: tr('Snail'), display: tr('The Snail'), description: tr('Not everyone can think and work that fast.'), photo:'snail.jpg', id: 5}
	# http://www.publicdomainpictures.net/view-image.php?image=104751&picture=banana-slug
	{title: tr('Donkey'), display: tr('The Donkey'), description: tr('Extremely stupid, but too stubborn to admit it.'), photo:'donkey.jpg', id: 6}
	# http://www.publicdomainpictures.net/view-image.php?image=45660&picture=donkey-in-the-meadow&large=1
	{title: tr('Meerkat'), display: tr('The Meerkat'), description: tr('Very paranoid. Probably with good reason.'), photo:'meerkat.jpg', id: 7}
	# http://www.publicdomainpictures.net/view-image.php?image=101843&picture=closeup-of-meerkat-face
	{title: tr('Mole'), display: tr('The Mole'), description: tr('Almost never seen.'), photo:'mole.jpg', id: 8}
	# http://www.publicdomainpictures.net/view-image.php?image=41195&picture=white-tiger
]
