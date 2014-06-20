Meteor.methods
  createCampaign:(userId, subject, body, search_tags, recipients) ->
    # Generate slug
    slug = URLify2 subject

    # Now check if the same slug used already
    count = Campaigns.find(slug: slug, user_id: userId).count()
    if count > 0
      slug += "-" + count.toString()

    campaign_id = Campaigns.insert user_id: userId, subject: subject,body: body, search_tags: search_tags, recipients: recipients, slug: slug, created_at: new Date(), sent: 'no'
    return campaign_id

  updateCampaign:(campaignId, userId, subject, body, search_tags, recipients) ->
    # Generate slug
    slug = URLify2 subject

    # Now check if the same slug used already
    count = Campaigns.find(slug: slug, user_id: userId).count()
    if count > 0
      # Check if the slug was used at the same campaign
      campaign = Campaigns.findOne({_id: campaignId})
      if campaign.slug isnt slug
        slug += "-" + count.toString()

    Campaigns.update({ _id: campaignId }, {$set: { user_id: userId, subject: subject, body: body, search_tags: search_tags, recipients: recipients, slug: slug } })

  markCampaignSent:(campaignId) ->
    Campaigns.update({ _id: campaignId }, {$set: { sent: 'yes', sent_on: new Date() } })

  deleteCampaign: (campaignId) ->
    console.log 'Delete a campaign' + campaignId
    Campaigns.remove({_id: campaignId})

  addSentUsersToCampaign:(campaignId, sent_to) ->
    Campaigns.update({ _id: campaignId }, {$addToSet: { sent_to: { $each: sent_to} } } )
