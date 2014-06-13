Meteor.publish 'contacts', (user_id) ->
  if user_id and (user_id is @userId)
    Contacts.find({user_id: @userId}, {fields: {from: 0}}).fetch()

Meteor.publish 'sharings', ->
  Sharings.find().fetch()

Meteor.publish 'campaigns',(user_id) ->
  if user_id and (user_id is @userId)
    Campaigns.find({user_id: @userId}).fetch()

Meteor.publish 'publicCampaigns', (user_id, slug) ->
  Campaigns.find({user_id: user_id, slug: slug}).fetch()

Meteor.publish 'messages', ->
  Messages.find().fetch()

Meteor.publish 'search_status', ->
  SearchStatus.find().fetch()
