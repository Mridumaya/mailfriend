Meteor.methods
  createCampaign:(userId, subject, body, search_tags, recipients) ->
    # Generate slug
    slug = URLify2 subject

    # Now check if the same slug used already
    count = Campaigns.find(slug: slug, user_id: userId).count()
    if count > 0
      slug += "-" + count.toString()

    campaign_id = Campaigns.insert user_id: userId, subject: subject,body: body, search_tags: search_tags, recipients: recipients, slug: slug, created_at: new Date(), email_sent: 'no'
    return campaign_id

  updateCampaign:(campaignId, userId, subject, body, search_tags, recipients) ->
    # Generate slug
    slug = URLify2 subject

    # Now check if the same slug used already
    campaigns = Campaigns.find(slug: slug, user_id: userId)
    # console.log campaigns
    count = campaigns.count()
    # console.log count
    if count > 0 and campaigns._id isnt campaignId
      slug += "-" + count.toString()

    # console.log slug

    Campaigns.update({ _id: campaignId }, {$set: { user_id: userId, subject: subject, body: body, search_tags: search_tags, recipients: recipients, slug: slug } })

  markCampaignSent:(campaignId, userId) ->
    Campaigns.update({ _id: campaignId }, {$set: { email_sent: 'yes' } })

  deleteCampaign: (campaignId) ->
    console.log 'Delete a campaign' + campaignId
    Campaigns.remove({_id: campaignId})

  addSentUsersToCampaign:(campaignId, sent_to) ->
    Campaigns.update({ _id: campaignId }, {$addToSet: { sent_to: { $each: sent_to} } } )
