Meteor.methods
  createCampaign:(userId, subject, body, search_tags) ->
    #Generate Slug
    slug = URLify2 subject

    #Now check is the same slug used already
    count = Campaigns.find(slug: slug, user_id: userId).count()
    slug += "-" + count.toString() if count > 0

    campaign_id = Campaigns.insert user_id: userId, subject: subject, slug: slug,body: body, search_tags: search_tags, created_at: new Date()
    return campaign_id

  updateCampaign:(campaignId, userId, subject, body, search_tags) ->
    Campaigns.update({ _id: campaignId }, {$set: { user_id: userId, subject: subject, body: body, search_tags: search_tags } })

  deleteCampaign: (campaignId) ->
    console.log 'Delete a campaign' + campaignId
    Campaigns.remove({_id: campaignId})

  addSentUsersToCampaign:(campaignId, sent_to) ->
    Campaigns.update({ _id: campaignId }, {$addToSet: { sent_to: { $each: sent_to} } } )
