Meteor.methods
  createCampaign:(userId, subject, body, search_tags) ->
    campaign_id = Campaigns.insert user_id: userId, subject: subject,body: body, search_tags: search_tags, created_at: new Date(), email_sent: 'no'
    return campaign_id

  updateCampaign:(campaignId, userId, subject, body, search_tags) ->
    Campaigns.update({ _id: campaignId }, {$set: { user_id: userId, subject: subject, body: body, search_tags: search_tags } })

  markCampaignSent:(campaignId, userId) ->
    Campaigns.update({ _id: campaignId }, {$set: { email_sent: 'yes' } })

  deleteCampaign: (campaignId) ->
    console.log 'Delete a campaign' + campaignId
    Campaigns.remove({_id: campaignId})

  addSentUsersToCampaign:(campaignId, sent_to) ->
    Campaigns.update({ _id: campaignId }, {$addToSet: { sent_to: { $each: sent_to} } } )
