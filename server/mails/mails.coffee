Fiber = Npm.require("fibers")
Meteor.methods
  syncAllMails: ->
    user_ids = Meteor.users.find({}, {fields: {_id: 1}}).fetch()
    console.log user_ids
    _.each user_ids, (user) ->
      syncMail user._id
      Meteor.call 'loadGContacts', user._id, true

  # load contact from gmail header
  loadContacts: (user_id, force = false) ->
    return if @userId isnt user_id and !force
    syncMail user_id
    console.log 'loadContacts: ', user_id
    Meteor.call 'loadGContacts', user_id, true

  # load contact from google contacts
  loadGContacts: (user_id, force = false) ->
    return if @userId isnt user_id and !force
    user = Meteor.users.findOne 'services.google': {$exists: true}, _id: user_id
    throw new Meteor.Error '404', "user not found: (#{user_id})" unless user

    opts =
        email: user.services.google.email
        consumerKey: Meteor.settings.google.api
        consumerSecret: Meteor.settings.google.secret
        token: user.services.google.accessToken
        refreshToken: user.services.google.refreshToken
    gcontacts = new GoogleContacts opts
    gcontacts.refreshAccessToken opts.refreshToken, (err, accessToken) ->
      if err
        console.log 'gcontact.refreshToken, ', err
        return false
      else
        console.log 'gcontact.access token success!'
        gcontacts.token = accessToken
        gcontacts.getContacts (err, contacts) ->
          if err
            console.log err 
            # Do what you want to do with contacts
          else
            console.log 'loadGContacts: ', opts.email, ":", contacts.length
            Fiber ->
              uniqueContacts = _.uniq contacts, (c) -> c.email.trim()
              _.each uniqueContacts, (c) ->
                email = c.email.trim()
                name = c.name.trim()
                if name is email
                  name = ''
                  from = email
                else
                  from = name + ' <' + email + '>'

                contact = Contacts.findOne email: email, user_id: user._id
                if contact
                  updateopts = {source: 'gcontact'}
                  if name
                    updateopts.name = name
                    updateopts.from = from
                  Contacts.update contact._id, {$set: updateopts}
                else
                  Contacts.insert
                    from: from
                    email: email
                    name: name
                    user_id: user._id
                    source: 'gcontact'
            .run()