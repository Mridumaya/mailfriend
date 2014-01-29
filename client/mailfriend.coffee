Template.invite_friends.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name
    else
      ''

Template.invite_friends.events
  'click .add-google-oauth': (e) ->
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
        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log err if err
    )

Template.contact_list.helpers
  contacts: ->
    contacts = Contacts.find().fetch()
    _.sortBy contacts, (c) -> -c.uids.length
  messages: ->
    @uids.length

Template.contact_list.events
  'click tr.contact': (e) ->
    $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('icon-ok')

  'click button.selectAll': (e) ->
    selectAll = $(e.currentTarget)
    if $(selectAll).toggleClass('selected').hasClass('selected')
      $(selectAll).text('Unselect All')
      $('tr.contact').addClass('info').find('.icon i').addClass('icon-ok')
    else
      $(selectAll).text('Select All')
      $('tr.contact').removeClass('info').find('.icon i').removeClass('icon-ok')

