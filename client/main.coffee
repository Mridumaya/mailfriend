Deps.autorun ->
  console.log 'Subscribing to messages.'
  Meteor.subscribe 'messages', ->
    console.log 'Messages Subscribed :', new Date

  if Meteor.user() isnt null && Meteor.user().profile isnt undefined
    Meteor.subscribe 'user_messages', Meteor.user().profile.email

  if Meteor.userId()
    Session.set('SUBSCRIBED_CONTACTS', false)
    Session.set('STEP', "welcome")

    Meteor.subscribe 'contacts', Meteor.userId(), ->
      console.log 'SUBSCRIBED_CONTACTS: ', Contacts.find({}).count(), new Date()
      Session.set('SUBSCRIBED_CONTACTS', true)

  if Session.equals('GOOGLE_API', false)
    $('#google-api-modal')?.modal(backdrop: 'static', keyboard: false)
    $('#google-api-modal')?.find('.client-id').focus()
  else
    $('#google-api-modal')?.modal('hide')

  Session.set('SUBSCRIBED_SHARINGS', false)
  Meteor.subscribe 'sharings', ->
    Session.set('SUBSCRIBED_SHARINGS', true)
    console.log 'SUBSCRIBED_SHARINGS: ', new Date

  Meteor.subscribe 'search_status'

Session.setDefault("GOOGLE_API", true)

Meteor.startup ->
  Session.set "OWN_MESS", ""
  GoogleAccountChecker.checkGoogleApi()
  SelectedEmails.remove()