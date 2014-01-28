Deps.autorun ->
  if Meteor.userId()
    Meteor.subscribe 'contacts', Meteor.userId(), ->
      console.log 'SUBSCRIBED_CONTACTS:', Contacts.find({}).count()
      Session.set('SUBSCRIBED_CONTACTS', true)
      console.log new Date()