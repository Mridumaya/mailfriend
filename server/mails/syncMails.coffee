parseContacts = (contacts) ->
  _.map contacts, (c) ->
    from = c.from?[0]
    matchResult = from.match(/<(.+)>/)
    email = if matchResult
       matchResult[1] 
    else
      from
    name = from.match(/(.+)</)?[1].trim() if matchResult
    return {
      from: from
      uid: c.uid
      email: email
      name: name
    }

addContacts = (contacts, user_id) ->
  parsedContacts = parseContacts(contacts)
    # console.log contacts
  groupedContacts = _.groupBy parsedContacts, (c) -> c.email
  insertContacts = _.map groupedContacts, (v, k) ->
    return {
      from: v[0].from
      email: k
      name: _.find(v, (c)->c.name)?.name
      uids: _.pluck(v, 'uid')
    }

  Fiber = Npm.require("fibers")
  Fiber ->
    dbContacts = Contacts.find({user_id: user_id}, {fields: {email: true}}).fetch()
    existEmails = _.pluck dbContacts, 'email'
    contacts = _.filter insertContacts, (c) -> !_.contains(existEmails, c.email)
    _.each contacts, (c)->
      Contacts.insert(_.extend(c, {user_id: user_id}))
    console.log insertContacts.length
  .run()


@syncMail = (user_id) ->
  # find user
  user = Meteor.users.findOne 'services.google': {$exists: true}, _id: user_id
  return user unless user
  console.log user.services.google

  xoauth2gen = XOauth2.createXOAuth2Generator
                user: user.services.google.email
                clientId: Meteor.settings.google.id
                clientSecret: Meteor.settings.google.secret
                refreshToken: user.services.google.refreshToken
  xoauth2gen.getToken (err, token) ->
    if err
      console.error '[SyncMail] get xoauth2gen token error: ', err, xoauth2gen.options.user
    else
      imapServer = new Imap({
        xoauth2: token
        host: 'imap.gmail.com'
        port: 993
        tls: true
        tlsOptions:
          rejectUnauthorized: false
      })
      imapServer.once 'ready', ->
        imapServer.getBoxes (err, boxes) -> console.log "[MailSync]: boxes ", boxes

        imapServer.openBox "INBOX", true, (err, box) ->
        # imapServer.openBox "Sent Messages", true, (err, box) ->
          if err
            console.log('[LoadGmail]: Open InBox error', err)
            do imapServer.end
            return
          console.log 'total messages in INBOX: ', box.messages.total

            # fetch latest 1000 header of mails.
          if box.messages.total > 1000
            range = (box.messages.total - 1000) + ":*"
          else
            range = "1:*"
          allContacts = []
          f = imapServer.seq.fetch range,
            bodies: 'HEADER.FIELDS (FROM TO)',
            struct: true
          f.on 'message', (msg, seqno) ->
            prefix = '(#' + seqno + ') '
            contact = {}
            msg.on 'body', (stream, info) ->
              buffer = ''
              stream.on 'data', (chunk) -> buffer += chunk.toString('utf8')
              stream.once 'end', ->
                contact = Imap.parseHeader(buffer)

            msg.once 'attributes', (attrs) -> contact.uid = attrs.uid
            msg.once 'end', -> allContacts.push contact

          f.once 'error', (err) -> console.log('Fetch error: ' + err)
          f.once 'end', ->
            addContacts(allContacts, user._id)
            console.log('Done fetching all messages!')
            imapServer.end()

      imapServer.once 'end', -> console.log '[SyncMail] imapserver end!!\n\n'
      imapServer.once 'error', (err) -> console.log '[SyncMail] imapserver error: ', err
      imapServer.connect()