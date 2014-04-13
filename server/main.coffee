initGoogleOauth = ->
  service = Accounts.loginServiceConfiguration.findOne service: 'google', domain: Meteor.absoluteUrl()
  if service
    googleOauth = id: service.clientId, secret: service.secret
    Meteor.settings.google = googleOauth

Meteor.startup ->
  initGoogleOauth()

Meteor.methods
  'initGoogleOauth': (id, secret, updateCode) ->
    check(id, String)
    check(secret, String)
    googleOauth = id: id, secret: secret
    switch Meteor.absoluteUrl()
      when "http://localhost:3000/"
        googleOauth =
          id: "641565285402-b7u0f11mjhsuapuhthn3ntqn1u4jpbpp.apps.googleusercontent.com"
          secret: "quILGppmE6wJGcmULASCvAmF"
    #   when "http://mailfriend.meteor.com/"
    #     googleOauth =
    #       id: "1082152336799-raue9st6ro4j1flt6fs8jcl6e2pdch6s.apps.googleusercontent.com"
    #       secret: "tCMyRbEI3jibBaQM9B7TkEcs"

    Meteor.settings.google = googleOauth

    Accounts.loginServiceConfiguration.remove service: "google"
    Accounts.loginServiceConfiguration.insert
      service: "google"
      clientId: Meteor.settings.google.id
      secret: Meteor.settings.google.secret
      domain: Meteor.absoluteUrl()



  'checkGoogleApi': ->
    !!Accounts.loginServiceConfiguration.findOne({service: 'google', domain: Meteor.absoluteUrl()})



  'loadAllGmails': (userId, isLoadAll) ->
    Meteor.users.update userId, {$set: {'profile.isLoadAll': isLoadAll}}, (err, num) ->
      syncMail(userId) if isLoadAll and !err



  'searchContacts': (searchQuery, userId = '') ->
    userId = userId || @userId
    Meteor.users.update userId, {$addToSet: {'profile.searchQuerys': searchQuery}}, (err, num) ->
      if err
        console.log err
      else
        syncMail(userId, searchQuery)

  'checkPassword': (userId, password) ->
    console.log userId + ", " + password
    return true

  'createCampaign':(userId, subject, body, search_tags) ->
    console.log "inserted server"
    campaign_id = Campaigns.insert user_id: userId, subject: subject,body: body, search_tags: search_tags, created_at: new Date()

  "create_user": (profile) ->
    existingUser = Meteor.users.findOne({"emails.address": profile.email})
    if !existingUser
      autoUsername = Meteor.call('build_unique_username_by_email', profile.email)
      profile.username = autoUsername
      userId = Accounts.createUser(profile)

      #Send Verification Mail
      #Following Line will generate email verification token
      #It will not send mail as we have set the MAIL_URL env
      Accounts.sendVerificationEmail userId

      #Get User Details
      user = Meteor.users.findOne ({_id: userId})
      body = "Hello " + user.profile.first_name + "<br>"
      body += "To verify your account email, simply click the link below.<br>"
      body += Meteor.absoluteUrl() + "verify-email/" + user.services.email.verificationTokens[0].token + "<br>"
      body += "Thanks<br>"

      subject = "Verify your email address on " + Meteor.absoluteUrl()
      Meteor.call "sendMailUsingMandrill", subject, body, user.emails[0].address
    else
      throw new Meteor.Error(403, 'Email already exist.')

    createdUser = Meteor.users.findOne({username: profile.username})
    return {first_name: profile.profile.first_name, last_name: profile.profile.last_name, username: profile.username, email: profile.email, userId: createdUser?._id}

  "edit_user": (profile) ->
    createdUser = Meteor.users.findOne({_id: profile.userId})
    if createdUser
      Meteor.users.update({_id: profile.userId}, $set: { "profile.first_name": profile.first_name, "profile.last_name": profile.last_name, "profile.name": profile.name } )
    else
      throw new Meteor.Error(403, 'User do not exists')


  "build_unique_username_by_email": (email) ->
    username = email.substring(0, email.indexOf('@')).replace('.', '_')
    uniqueUsername = username
    index = 0
    while true
      user = Meteor.users.findOne({"username":uniqueUsername})
      if not user
        return uniqueUsername
      else
        index = index + 1
        uniqueUsername = username + '_' + index