initialize = true

Template.public_welcome.rendered = ->
  mixpanel.track("visits step 1 page", { });
  if(initialize)
    $('#own_message').wysihtml5({"image":false, "font-styles": false});
    initialize = false;

Template.public_welcome.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name.split(" ")[0]
    else
      ''
  own_message: ->
    if Session.get("OWN_MESS") is 'undefined'
      Session.set "OWN_MESS", ""
    Session.get "OWN_MESS"

  mail_title: ->
    Session.get "MAIL_TITLE"

  orig_message: ->
    Session.get "ORIG_MESS"

  sender: ->
    Sharings.findOne(type: 'email')?.senderName || "Someone"

Template.public_welcome.events
  'click .welcome-to-searchq': (e) ->
    mixpanel.track("logs in", { });
    console.log new Date()
    button = $(e.currentTarget)
    $(button).prop('disabled', true)
    Meteor.loginWithGoogle({
      requestPermissions: ["https://mail.google.com/", # imap
                           "https://www.googleapis.com/auth/userinfo.profile", # profile
                           "https://www.googleapis.com/auth/userinfo.email", # email
                           "https://www.google.com/m8/feeds/" # contacts
                         ]
      requestOfflineToken: true
      forceApprovalPrompt: true
    }, (err) ->
      $(button).prop('disabled', false)
      unless err
        Meteor.subscribe 'contacts', Meteor.userId(), ->
          console.log 'SUBSCRIBED_CONTACTS: ', Contacts.find({}).count(), new Date()
          
        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log err if err
          #Session.set "ORIG_MESS", $("#original_message").val() || $("#original_message").html()
          Session.set "OWN_MESS", $("#own_message").val() 
          Session.set "MAIL_TITLE", $("#subject").val() 
          Session.set "STEP", "public_searchq" 
    )
