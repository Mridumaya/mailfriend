Deps.autorun ->
  if Meteor.userId()
    Meteor.subscribe 'contacts', Meteor.userId(), ->
      console.log 'SUBSCRIBED_CONTACTS:', Contacts.find({}).count()
      Session.set('SUBSCRIBED_CONTACTS', true)
      console.log new Date()

  if Session.equals('GOOGLE_API', false)
    $('#google-api-modal')?.modal(backdrop: 'static', keyboard: false)
    $('#google-api-modal')?.find('.client-id').focus()
  else
    $('#google-api-modal')?.modal('hide')

@checkGoogleApi = ->
  Meteor.call 'checkGoogleApi', (err, result) ->
    if err
      console.log 'checkGoogleApi', err
    else
      Session.set('GOOGLE_API', !!result)

Session.setDefault("GOOGLE_API", true)
Meteor.startup ->
  checkGoogleApi()

