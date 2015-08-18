{tr} = require 'i18n'

exports.getDefault = ->
	period: 'week'
	topics:
		1: {name: tr('Panda'), descr: tr('Too lazy to reproduce, and thus doomed to extinction.'), photo: 'panda.jpg'},
		2: {name: tr('Grizzly'), descr: tr('A bear with a terrible temper. Approach at your own risk.'), photo: 'grizzly.jpg'}
		3: {name: tr('Peacock'), descr: tr('A vain bird that loves to show everyone just how awesome it is.'), photo: 'peacock.jpg'}
		4: {name: tr('Puppy'), descr: tr('Young, playful, foolish. But at end of day, just very cute.'), photo: 'pup.jpg'}
		5: {name: tr('Snail'), descr: tr('Not everyone can think and work that fast.'), photo:'snail.jpg'}
		6: {name: tr('Donkey'), descr: tr('Extremely stupid, but too stubborn to admit it.'), photo:'donkey.jpg'}
		7: {name: tr('Meerkat'), descr: tr('Very paranoid. Probably with good reason.'), photo:'meerkat.jpg'}
		8: {name: tr('Mole'), descr: tr('Almost never seen.'), photo:'mole.jpg'}
	optionMax: 8


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

