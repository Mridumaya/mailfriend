Template.publicLayout.helpers
  stepIsSignup: ->
  	Session.equals('STEP', "public_signup")
  stepIsWelcome: ->
    Session.equals('STEP', "public_welcome")
  stepIsSearchQ: ->
    Session.equals('STEP', "public_searchq")
  stepIsContactList: ->
    Session.equals('STEP', "public_contact_list")
  stepIsConfirm: ->
    Session.equals('STEP', "public_confirm")