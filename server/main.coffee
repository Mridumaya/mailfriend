Meteor.startup ->
  GlobalConfiguration.init()

Meteor.methods
  loadAllGmails: (userId, isLoadAll) ->
    Meteor.users.update userId, {$set: {'profile.isLoadAll': isLoadAll}}, (err, num) ->
      syncMail(userId) if isLoadAll and !err

  searchContacts: (searchQuery, userId = '') ->
    userId = userId || @userId
    Meteor.users.update userId, {$addToSet: {'profile.searchQuerys': searchQuery}}, (err, num) ->
      if err
        console.log err
      else
        syncMail(userId, searchQuery)

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
