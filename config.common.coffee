{tr} = require 'i18n'

exports.getDefault = ->
	period: 'week'
	topics:
		1: {name: tr('Player'), descr: tr('Smooth talker with a healthy reproductive drive.'), photo: 'player.jpg'}
		2: {name: tr('Hero'), descr: tr('Accomplishes great things for the collective.'), photo: 'hero.jpg'}
		3: {name: tr('Disappointment'), descr: tr('We had such great hopes for this one.'), photo: 'disappointment.jpg'}
		4: {name: tr('Beggar'), descr: tr('Always ‘borrowing’, never sharing.'), photo: 'beggar.jpg'}
		5: {name: tr('Grumpy'), descr: tr('Terrible temper! Approach at your own risk.'), photo: 'grumpy.jpg'}
		6: {name: tr('Princess'), descr: tr('Too frail to even look at. Careful!'), photo: 'princess.jpg'}
		7: {name: tr('Ghost'), descr: tr('Rarely seen. Might not even exist at all.'), photo: 'ghost.jpg'}
		8: {name: tr('Zombie'), descr: tr('Could perhaps use a little more sleep.'), photo: 'zombie.jpg'}
		9: {name: tr('Pig'), descr: tr('Eats and drinks whatever it comes across.'), photo: 'pig.jpg'}
		10: {name: tr('Yoda'), descr: tr('Riddles, this one talks in.'), photo: 'yoda.jpg'}

exports.periodTime = (period) ->
	{
		minute: 60
		day: 24*3600
		week: 7*24*3600
		month: 30*24*3600
	}[period]

exports.voteTime = (period) ->
	{
		minute: 30
		day: 1800
		week: 6*3600
		month: 24*3600
	}[period]

exports.awardName = (what,period) ->
	if period=="day"
		tr "%1 of the Day", what
	else if period=="month"
		tr "%1 of the Month", what
	else if period=="minute"
		tr "%1 of the Minute", what
	else
		tr "%1 of the Week", what

