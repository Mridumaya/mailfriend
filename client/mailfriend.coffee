Template.invite_friends.rendered = ->
  if Meteor.user()
    $(this.find('.add-google-oauth')).prop('disabled', true)
  else
    $(this.find('.add-google-oauth')).prop('disabled', false)

Template.invite_friends.events
  'click .add-google-oauth': (e) ->
    $(e.currentTarget).prop('disabled', true)
    Meteor.loginWithGoogle({
      requestPermissions: ["https://mail.google.com/", # imap
                           "https://www.googleapis.com/auth/userinfo.profile", # profile
                           "https://www.googleapis.com/auth/userinfo.email", # email
                           "https://www.google.com/m8/feeds/" # contacts
                         ]
      requestOfflineToken: true
      forceApprovalPrompt: true
    }, (err) ->
      $(e.currentTarget).prop('disabled', false)
    )