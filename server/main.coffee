Meteor.startup ->
  GlobalConfiguration.init()


Meteor.methods
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

# Meteor.headly.config({
#   facebook: (data) ->
#     tags = '<meta property="og:image" content="http://jacint.meteor.com/images/logo.png"/>'
#     tags += '<meta property="og:title" content="Pollen"/>'
#     tags += '<meta property="og:url" content="http://jacint.meteor.com"/>'
#     tags += '<meta property="og:site_name" content="Pollen"/>'
#     tags += '<meta property="og:type" content="website"/>'

#     return tags

#   twitter: (data) ->
#     return '<meta name="twitter:card" content="summary">'
# })
