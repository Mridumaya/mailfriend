Meteor.methods
  loadContacts: (user_id) ->
    return if @userId isnt user_id
    syncMail user_id
    console.log 'loadContacts'