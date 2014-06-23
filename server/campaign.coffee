Meteor.methods
  # campaigns -----------------------------------------------------------------------------------------------------------------------------
  
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

  # inbox ------------------------------------------------------------------------------------------------------------------------------

  getSenderName: (senderId) ->
    user = Meteor.users.findOne({_id: senderId})
    name = user.profile.name

    return [name, senderId]

  getSenderProfilePicture: (senderId) ->
    user = Meteor.users.findOne({_id: senderId})
    picture = user.profile.picture

    if picture
      return [picture, senderId]
    else
      return ['/images/default_user.jpg', senderId]

  getMessageTags: (campaignId) ->
    campaign = Campaigns.findOne({_id: campaignId})
    tags = campaign.search_tags

    return [tags, campaignId]   

# common functions ------------------------------------------------------------------------------------------------------------------------

  formatDate: (created, campaignId) ->
    weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

    curr_date = new Date()
    curr_monthday = curr_date.getDate()
    curr_day = weekdays[curr_date.getDay()]
    curr_month = months[curr_date.getMonth()]
    curr_year = curr_date.getFullYear()

    created_hours = created.getHours()
    created_minutes = created.getMinutes()

    if created_minutes < 10
      created_minutes = '0' + created_minutes

    if created_hours > 11
      ampm = 'pm'
    else
      ampm = 'am'  

    if created_hours > 12
      created_hours -= 12      

    created_time = created_hours + ':' + created_minutes + ampm
    created_monthday = created.getDate()
    created_day = weekdays[created.getDay()]
    created_month = months[created.getMonth()]
    created_year = created.getFullYear()

    # console.log created
    # console.log created_year + ' ' + created_month + ' ' + created_day + ' ' + created_time + ' ' + created_monthday

    formated = created_day + ' ' + created_time

    if curr_year is created_year
      if curr_month is created_month
        if curr_monthday is created_monthday
          formated = 'Today ' + created_time
        else if curr_month - 1 is created_monthday
          formated = 'Yesterday ' + created_time
        else formated += ', ' + created_month + ' ' + created_monthday
      else
        formated += ', ' + created_month + ' ' + created_monthday
    else
      formated += ', ' + created_month + ' ' + created_monthday + ' ' + created_year

    return [formated, campaignId]
