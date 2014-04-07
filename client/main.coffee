Deps.autorun ->
  if Meteor.userId()
    Session.set('SUBSCRIBED_CONTACTS', false)
    Session.set("STEP", "feature_select")
    Meteor.subscribe 'contacts', Meteor.userId(), ->
      console.log 'SUBSCRIBED_CONTACTS: ', Contacts.find({}).count(), new Date()
      Session.set('SUBSCRIBED_CONTACTS', true)

    Meteor.subscribe 'campaigns', Meteor.userId(), ->
      console.log 'All campaigns'


  if Session.equals('GOOGLE_API', false)
    $('#google-api-modal')?.modal(backdrop: 'static', keyboard: false)
    $('#google-api-modal')?.find('.client-id').focus()
  else
    $('#google-api-modal')?.modal('hide')

  Session.set('SUBSCRIBED_SHARINGS', false)
  Meteor.subscribe 'sharings', ->
    Session.set('SUBSCRIBED_SHARINGS', true)
    console.log 'SUBSCRIBED_SHARINGS: ', new Date


Session.setDefault("GOOGLE_API", true)

Meteor.startup ->
  GoogleAccountChecker.checkGoogleApi()
  SelectedEmails.remove()