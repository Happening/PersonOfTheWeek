Db = require 'db'
Dom = require 'dom'
# Nav = require 'nav'
Modal = require 'modal'
Obs = require 'obs'
Plugin = require 'plugin'
Page = require 'page'
Photo = require 'photo'
Server = require 'server'
Time = require 'time'
Ui = require 'ui'
Form = require 'form'
{tr} = require 'i18n'

Dom.css
	'.titleHeader':
		textAlign: 'center'
		fontWeight: 'bold'
		fontSize: '2em'
	'.titleSubheader':
		textAlign: 'center'
		fontWeight: 'bold'
		fontSize: '1.2em'
	'.timeremaining':
		fontSize: '0.9em'
		color: '#969696'
		marginBottom: '20px'
		marginTop: '10px'
	'.memberselect':
		margin: '10px'
		borderBottom: '1px solid #666'
		borderTop: '1px solid #666'
	'.templatepicture':
		marginRight: '10px'
		width: '50px'
		height: '50px'
		minWidth: '50px'
		borderRadius: '25px'
	'.templateitem':
		position: 'relative'
		height: '60px'
	'.templatedescription tr':
		fontStyle: 'italic'
		fontSize: '80%'
		fontWeight: 'normal'
		color: '#aaa'
	'.addpicture':
		position: 'relative'
		verticalAlign: 'top'
		marginRight: '10px'
		border: 'dashed 2px #aaa'
		borderRadius: '25px'
		height: '50px'
		width: '50px'
		minHeight: '50px'
		minWidth: '50px'

exports.render = !->
	if (Db.shared.get 'votesopen') && (Db.shared.get 'voteclose') - Plugin.time() > 0
		pendingPage()
	else
		resultsPage()
	
	require('social').renderComments 'votecomments'
	
	if Db.shared.get 'winners'
		Dom.h2 !->
			Dom.text tr("Previous rounds")
		Ui.item !->
			Dom.text tr("Hall of Fame")
			Dom.onTap !->
				Modal.show 'Hall of Fame', hallOfFame

pendingPage = !->
	Dom.div !->
		Dom.cls 'titleSubheader'
		Dom.text tr('who will be')
	Dom.div !->
		Dom.cls 'titleHeader'
		Dom.text Db.shared.get 'settings', 'title'
	Dom.div !->
		Dom.cls 'titleSubheader'
		Dom.text tr("of the ") + periodname()
	winnerPicture()
	Dom.div !->
		Dom.text Db.shared.get 'settings', 'description'
		Dom.style
			textAlign: 'center'

	personalVote = Obs.create(0|Db.personal.get 'vote')
	Dom.div !->
		Dom.cls "memberselect"
		selectMember
			name: 'vote'
			title: tr("Voted for")
			value: personalVote.func()
			selectTitle: tr("Vote for")
			onSave: (v) !->
				Server.sync 'vote', v, !->
					Db.personal.set 'vote', v
	Dom.div !->
		Dom.cls "timeremaining"
		Dom.text tr("Votes are closing ")
		Time.deltaText (Db.shared.get 'voteclose')

resultsPage = !->
	if Db.shared.get 'winners', (Db.shared.get 'roundcounter')
		Dom.h1 tr("The results are in!")
		Dom.div !->
			Dom.cls 'titleHeader'
			Dom.text Plugin.userName Db.shared.get 'winners', (Db.shared.get 'roundcounter')
		Dom.div !->
			Dom.cls 'titleSubheader'
			Dom.text Db.shared.get 'settings', 'title'
			Dom.text tr(" of the ") + periodname()

		winnerPicture()
		Dom.div !->
			Dom.style
				textAlign: 'center'
			Dom.text Db.shared.get 'settings', 'description'

		winningstreak = 0
		for m, w of Db.shared.get 'winners'
			if parseInt(w) == Plugin.userId()
				winningstreak++
			else
				winningstreak = 0

		if winningstreak > 1
			Dom.div !->
				Dom.style
					textAlign: 'center'
					marginTop: '10px'
				Dom.text tr("#{winningstreak} wins in a row!")
	else
		Dom.h1 tr("Unfortunately...")
		Dom.text tr("No votes have been cast during the last round.")
	
	Dom.div !->
		Dom.cls 'timeremaining'
		Dom.text tr("The next round will begin ")
		Time.deltaText (Db.shared.get 'nextround')

selectMember = (opts) !->
	opts ||= {}
	[handleChange, initValue] = Form.makeInput opts, (v) -> 0|v

	value = Obs.create(initValue)
	Form.box !->
		Dom.style fontSize: '125%', paddingRight: '56px'
		Dom.text opts.title||tr("Selected member")
		v = value.get()
		Dom.div !->
			Dom.style color: (if v then 'inherit' else '#aaa')
			Dom.text (if v then Plugin.userName(v) else tr("Nobody"))
		if v
			Ui.avatar Plugin.userAvatar(v), !->
				Dom.style position: 'absolute', right: '6px', top: '50%', marginTop: '-20px'

		Dom.onTap !->
			Modal.show opts.selectTitle||tr("Select member"), !->
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
			, ['cancel', tr("Cancel"), 'clear', tr("Clear")]

hallOfFame = !->
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

exports.renderSettings = !->
	# Once the rounds have been started, do not allow changing
	if Db.shared
		# if Plugin.userIsAdmin()
		# 	Dom.h3 !->
		# 		Dom.text tr("Admin Options")
		# 	Ui.item !->
		# 		Dom.text "Start new round now!"
		# 		Dom.onTap !->
		# 			Server.sync 'startRound'
		# 	Ui.item !->
		# 		Dom.text "End round now!"
		# 		Dom.onTap !->
		# 			Server.sync 'endRound'
		return if Db.shared.get 'nextround'

	period = Obs.create(if Db.shared then Db.shared.get 'settings', 'period' else 'week')
	customCollapsed = Obs.create(true)
	selected = Obs.create(false)
	settings = Obs.create()

	Obs.observe !->
		s = selected.get()
		for opts in templates
			Obs.observe !->
				Ui.item !->
					Dom.cls 'templateitem'

					Dom.div !->
						Dom.cls 'templatepicture'
						Dom.style
							background: "url(#{Plugin.resourceUri(opts.photo)}) 50% 50% no-repeat"
							backgroundSize: '50px'
						if selected.get() == opts.id
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
						Dom.cls 'templatedescription'
						Dom.text opts.display
						Dom.tr opts.description


					t = opts.title
					d = opts.description
					p = opts.photo
					i = opts.id
					Dom.onTap !->
						settings.set('title', t)
						settings.set('description', d)
						settings.set('photo', p)
						selected.set(i)

		Ui.item !->
			Obs.observe !->
				Dom.style
					position: 'relative'
					minHeight: if customCollapsed.get() then '60px' else '120px'
				
				if customCollapsed.get()
					Dom.text "+ Create your own"
				else
					cte = cde = undefined
					photo = Photo.unclaimed 'titlephoto'
					if photo
						photoguid = photo.claim()
						if Photo.url photoguid
							settings.set 'photoguid', photoguid
							settings.set 'thumb', photo.thumb

					Dom.div !->
						Dom.cls 'addpicture'
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
							Photo.pick undefined, false, 'titlephoto'

					Dom.div !->
						Dom.div !->
							Dom.style
								width: '100%'
							cte = Form.input
								name: 'customtitle'
								text: 'title'
						Form.condition ->
							tr("Required field") if cte.value() == '' && selected.get() == 'custom'
						Dom.div !->
							cde = Form.text
								name: 'customdescription'
								text: 'description'
								autogrow: false
						Form.condition ->
							tr("Required field") if cde.value() == '' && selected.get() == 'custom'

					if selected.get() == 'custom'
						Dom.div !->
							Dom.style
								position: 'absolute'
								left: '0px'
								top: '5px'
								fontSize: '15px'
								color: 'black'
							Dom.text '✔'
					else if cte.value() == '' and cde.value() == ''
							customCollapsed.set true
			Dom.onTap !->
				customCollapsed.set false
				selected.set 'custom'

		Form.label tr("Vote once every")
		p = Form.hidden 'period', period.get()
		p.value period.get()
		Ui.item !->
			Dom.text periodname period.get()
			Dom.onTap !->
				Modal.show !->
					Ui.item !->
						Dom.text tr("day")
						Dom.onTap !->
							period.set 'day'
							Modal.remove()
					Ui.item !->
						Dom.text tr("week")
						Dom.onTap !->
							period.set 'week'
							Modal.remove()
					Ui.item !->
						Dom.text tr("month")
						Dom.onTap !->
							period.set 'month'
							Modal.remove()

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

photoOrTemplateUrl = (url) !->
	opts = if opts then opts else {}
	picture = ''
	if url
		picture = Plugin.resourceUri url
	else if Db.shared.get 'settings', 'photo'
		if Db.shared.get 'settings', 'photo', 'type'
			picture = Photo.url Db.shared.get('settings', 'photo', 'key'), 250
		else
			picture = Plugin.resourceUri Db.shared.get 'settings', 'photo'
	else
		picture = Plugin.resourceUri('unknown.jpg')
	return picture

winnerPicture = !->
	Dom.div !->
		Dom.style
			margin: '15px auto'
			width: '250px'
		if Db.shared.get 'votesopen'
			Dom.div !->
				Dom.cls "winnerpicture"
				picture = photoOrTemplateUrl()
				Dom.style
					background: "url(#{picture}) 50% 50% no-repeat"
					backgroundSize: 'cover'
					width: '250px'
					height: '250px'
					backgroundRepeat: 'no-repeat'
					borderRadius: '125px'
		else
			first = Db.shared.get 'winners', (Db.shared.get 'roundcounter')
			Ui.avatar Plugin.userAvatar(first), undefined, 250

templates = [
	{title: tr('Panda'), display: tr('The Panda'), description: tr('Too lazy to reproduce, and thus doomed to extinction.'), photo: 'panda.jpg', id: 1},
	{title: tr('Grizzly'), display: tr('The Grizzly'), description: tr('A bear with a terrible temper. Approach at your own risk.'), photo: 'grizzly.jpg', id: 2}
	{title: tr('Peacock'), display: tr('The Peacock'), description: tr('A vain bird that loves to show everyone just how awesome it is.'), photo: 'peacock.jpg', id: 3}
	{title: tr('Puppy'), display: tr('The Puppy'), description: tr('Young, playful, foolish. But at the end of the day, just very cute.'), photo: 'pup.jpg', id: 4}
	{title: tr('Slug'), display: tr('The Slug'), description: tr('Not everyone can think and work that fast.'), photo:'slug.jpg', id: 5}
	# http://www.publicdomainpictures.net/view-image.php?image=104751&picture=banana-slug
	{title: tr('Donkey'), display: tr('The Donkey'), description: tr('Extremely stupid, but too stubborn to admit it.'), photo:'donkey.jpg', id: 6}
	# http://www.publicdomainpictures.net/view-image.php?image=45660&picture=donkey-in-the-meadow&large=1
	{title: tr('Meerkat'), display: tr('The Meerkat'), description: tr('Very paranoid. Probably with good reason.'), photo:'meerkat.jpg', id: 7}
	# http://www.publicdomainpictures.net/view-image.php?image=101843&picture=closeup-of-meerkat-face
	{title: tr('Mole'), display: tr('The Mole'), description: tr('Almost never seen.'), photo:'mole.jpg', id: 8}
	# http://www.publicdomainpictures.net/view-image.php?image=41195&picture=white-tiger
]
