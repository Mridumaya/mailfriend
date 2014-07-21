initialize = true
Template.public_edit.rendered = ->
  mixpanel.track("visits step 1 page", { });

  menuitemActive()

  if (initialize)
    $('#own_message').wysihtml5({"image":false, "font-styles": false});
    # initialize = false;


Template.public_edit.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name.split(" ")[0]
    else
      ''
  own_message: ->
    message = Session.get("OWN_MESS")
    if message is undefined
      return '';
    else
      return message

  mail_title: ->
    title = Session.get "MAIL_TITLE"
    title.replace('Forwarded message: ', '')

  orig_message: ->
    message = Session.get "ORIG_MESS"
    message = message.replace(/style="color:rgb\(150, 150, 150\)"/g, '')

  sender_public: ->
    sender = Session.get("senderId")

    Meteor.call 'getSenderName', sender, (e, resp) ->
      console.log e if e

      name = resp[0]
      senderId = resp[1]
      Session.set('name' + senderId, name)

    name = Session.get('name' + sender)

    return name

  sender: ->
    sender = Session.get("senderId")

    Meteor.call 'getSenderName', sender, (e, resp) ->
      console.log e if e

      name = resp[0]
      senderId = resp[1]
      Session.set('name' + senderId, name)

    name = Session.get('name' + sender) + "'s"

    if sender is Meteor.user()._id
      name += ' (my)'

    return name

  is_public: ->
    is_public = Session.get('public')

    if is_public is 'yes'
      return true
    else
      return false


Template.public_edit.events
  'click .welcome-to-searchq': (e) ->
    e.preventDefault()
    mixpanel.track("logs in", { });

    console.log new Date()

    button = $(e.currentTarget)
    $(button).prop('disabled', true)

    # if user is already logged in
    if !!Meteor.user()
        Meteor.subscribe 'contacts', Meteor.userId(), ->
          console.log 'SUBSCRIBED_CONTACTS: ', Contacts.find({}).count(), new Date()

        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log err if err
          #Session.set "ORIG_MESS", $("#original_message").val() || $("#original_message").html()
          Session.set "OWN_MESS", $("#own_message").val()
          Session.set "MAIL_TITLE", $("#subject").val()
          # Session.set "STEP", "public_searchq"

          is_public = Session.get('public')
          if is_public is 'yes'
            Router.go("publicsearchcontacts")
          else
            Router.go("searchcontacts")

    # login user
    else
      Meteor.loginWithGoogle({
        requestPermissions: [
          "https://mail.google.com/", # imap
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
          Meteor.call 'updateLastLogin', (err) ->
            false  
          Meteor.call 'loadContacts', Meteor.userId(), (err) ->
            console.log err if err
            #Session.set "ORIG_MESS", $("#original_message").val() || $("#original_message").html()
            Session.set "OWN_MESS", $("#own_message").val()
            Session.set "MAIL_TITLE", $("#subject").val()
            # Session.set "STEP", "public_searchq"

            Session.set('GOOGLE_LOGIN', true)

            is_public = Session.get('public')
            if is_public is 'yes'
              Router.go("publicsearchcontacts")
            else
              Router.go("searchcontacts")
      )
