Meteor.publish 'contacts', (user_id) ->
  if user_id and (user_id is @userId)
    Contacts.find({user_id: @userId}, {fields: {from: 0}})

Meteor.publish 'sharings', ->
  Sharings.find()

Meteor.publish 'allcampaigns', ->
  Campaigns.find()

Meteor.publish 'campaigns', (user_id) ->
  if user_id and (user_id is @userId)
    Campaigns.find({user_id: @userId})

Meteor.publish 'messages', ->
  Messages.find()

Meteor.publish 'search_status', ->
  SearchStatus.find()

Meteor.publish 'publicCampaigns', (user_id, slug) ->
  if user_id and slug
    Campaigns.find({user_id: user_id, slug: slug})
