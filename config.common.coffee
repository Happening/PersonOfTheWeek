{tr} = require 'i18n'

exports.getDefault = ->
	period: 'week'
	topics:
		1: {name: tr('Panda'), descr: tr('Too lazy to reproduce, and thus doomed to extinction.'), photo: 'panda.jpg'},
		2: {name: tr('Grizzly'), descr: tr('Terrible temper! Approach at your own risk.'), photo: 'grizzly.jpg'}
		3: {name: tr('Peacock'), descr: tr('This vain creature truly believes that it\'s awesome.'), photo: 'peacock.jpg'}
		4: {name: tr('Puppy'), descr: tr('Young, playful, foolish. Awww... cute!'), photo: 'pup.jpg'}
		5: {name: tr('Snail'), descr: tr('Thinking and working fast just isn\'t for everybody.'), photo:'snail.jpg'}
		6: {name: tr('Donkey'), descr: tr('Often very wrong, but way too stubborn to admit it.'), photo:'donkey.jpg'}
		7: {name: tr('Mole'), descr: tr('Almost never seen.'), photo:'mole.jpg'}
		8: {name: tr('Owl'), descr: tr('Sleeps during the day.'), photo:'owl.jpg'}
		9: {name: tr('Pig'), descr: tr('Eats and drinks whatever it comes across.'), photo:'pig.jpg'}
		10: {name: tr('Rabbit'), descr: tr('Known for its legendary drive to reproduce.'), photo:'rabbit.jpg'}

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

