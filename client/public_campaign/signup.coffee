Template.public_signup.helpers
	name: ->
	    user = Meteor.user()
	    if user
	      user.profile.name.split(" ")[0]
	    else
	      ''
	sender: ->
    	Sharings.findOne(type: 'email')?.senderName || "Someone"

Template.public_signup.events
	'click #guest-account': (e) ->
		Session.set "STEP", "public_welcome"
	'click #signup-account': (e) ->
		Router.go "signup_account"
