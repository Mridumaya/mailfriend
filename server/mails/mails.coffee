Meteor.methods
  loadContacts: (user_id, force = false) ->
    return if @userId isnt user_id and !force
    syncMail user_id
    console.log 'loadContacts: ', user_id