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