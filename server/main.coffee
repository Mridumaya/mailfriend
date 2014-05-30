initGoogleOauth = ->
  service = Accounts.loginServiceConfiguration.findOne service: 'google', domain: Meteor.absoluteUrl()
  if service
    googleOauth = id: service.clientId, secret: service.secret
    Meteor.settings.google = googleOauth

Meteor.startup ->
  initGoogleOauth()
  # GlobalConfiguration.init() # temporarily commented out, have to find solution how to load settings on startup

Meteor.methods
  initGoogleOauth: (id, secret, updateCode) ->
    check(id, String)
    check(secret, String)
    googleOauth = id: id, secret: secret
    # switch Meteor.absoluteUrl()
      # when "http://localhost:3000/"
    if (Meteor.absoluteUrl() is "http://localhost:3000/")
      googleOauth =
        id: "641565285402-b7u0f11mjhsuapuhthn3ntqn1u4jpbpp.apps.googleusercontent.com"
        secret: "quILGppmE6wJGcmULASCvAmF"
    else 
      googleOauth =
        id: "759067463478-sqi1pvnlfphm9e0d1dheaac1pg62h3t6.apps.googleusercontent.com"
        secret: "-_1PIq-ylbZbr49Ro5FSdheY"

    # when "http://mailfriend.meteor.com/"
    # googleOauth =
    # id: "1082152336799-raue9st6ro4j1flt6fs8jcl6e2pdch6s.apps.googleusercontent.com"
    # secret: "tCMyRbEI3jibBaQM9B7TkEcs"

    Meteor.settings.google = googleOauth

    Accounts.loginServiceConfiguration.remove service: "google"
    Accounts.loginServiceConfiguration.insert
      service: "google"
      clientId: Meteor.settings.google.id
      secret: Meteor.settings.google.secret
      domain: Meteor.absoluteUrl()

  checkGoogleApi: ->
    !!Accounts.loginServiceConfiguration.findOne({service: 'google', domain: Meteor.absoluteUrl()})

  loadAllGmails: (userId, isLoadAll) ->
    Meteor.users.update userId, {$set: {'profile.isLoadAll': isLoadAll}}, (err, num) ->
      syncMail(userId) if isLoadAll and !err

  searchContacts: (searchQuery, session_id, userId = '') ->
    userId = userId || @userId
    Meteor.users.update userId, {$addToSet: {'profile.searchQuerys': searchQuery}}, (err, num) ->
      if err
        console.log err
      else
        syncMail(userId, session_id, searchQuery)

  checkPassword: (userId, password) ->
    console.log userId + ", " + password
    return true

  build_unique_username_by_email: (email) ->
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
