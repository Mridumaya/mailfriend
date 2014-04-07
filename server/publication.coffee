Meteor.publish 'contacts', (user_id) ->
  if user_id and (user_id is @userId)
    Contacts.find {user_id: @userId}, {fields: {from: 0}}

Meteor.publish 'sharings', ->
  Sharings.find()

Meteor.publish 'campaigns',(user_id) ->
  if user_id and (user_id is @userId)
    Campaigns.find({user_id: @userId})
