splitNameAndEmail = (nameAndEmail) ->
  matchResult = nameAndEmail.match(/<(.+)>/)
  email = if matchResult
     matchResult[1] 
  else
    nameAndEmail
  name = nameAndEmail.match(/(.+)</)?[1].trim() if matchResult
  return {email: email, name: name}

parseReveivedContacts = (contacts) ->
  _.map contacts, (c) ->
    from = c.from?[0]
    nameAndEmail = splitNameAndEmail from
    return {
      from: from
      uid: c.uid
      email: nameAndEmail.email
      name: nameAndEmail.name
    }

addContacts = (contacts, user_id) ->
  parsedContacts = parseReveivedContacts(contacts)
    # console.log contacts
  groupedContacts = _.groupBy parsedContacts, (c) -> c.email
  insertContacts = _.map groupedContacts, (v, k) ->
    return {
      from: v[0].from
      email: k
      name: _.find(v, (c)->c.name)?.name || ''
      uids: _.pluck(v, 'uid')
    }

  Fiber = Npm.require("fibers")
  Fiber ->
    dbContacts = Contacts.find({user_id: user_id}, {fields: {uids: true}}).fetch()
    existEmails = _.pluck dbContacts, 'email'
    contacts = _.filter insertContacts, (c) -> !_.contains(existEmails, c.email)
    _.each contacts, (c)->
      Contacts.update {email: c.email, user_id: user_id},
        {
          $set: {uids: c.uids}
        },
        (err, num) ->
          console.log err if err
          Contacts.insert(_.extend(c, {user_id: user_id})) unless num
    console.log insertContacts.length
  .run()

parseSentContacts = (contacts) ->
  _.map contacts, (c) ->
    from = c.to?[0]
    nameAndEmail = splitNameAndEmail from
    return {
      from: from
      uid: c.uid
      email: nameAndEmail.email
      name: nameAndEmail.name
    }

addSentContact = (contacts, user_id) ->
  subContacts = []
  _.each contacts, (c) ->
    if c.to.length is 1
      subContacts.push c
  console.log contacts.length, ':', subContacts.length
  parsedContacts = parseSentContacts subContacts
  groupedContacts = _.groupBy parsedContacts, (c) -> c.email
  insertContacts = _.map groupedContacts, (v, k) ->
    return {
      from: v[0].from
      email: k
      name: _.find(v, (c)->c.name)?.name || ''
      sent_uids: _.pluck(v, 'uid')
    }

  Fiber = Npm.require("fibers")
  Fiber ->
    dbContacts = Contacts.find({user_id: user_id}, {fields: {sent_uids: true}}).fetch()
    existEmails = _.pluck dbContacts, 'email'
    contacts = _.filter insertContacts, (c) -> !_.contains(existEmails, c.email)
    _.each contacts, (c)->
      Contacts.update {email: c.email, user_id: user_id},
        {
          $set: {sent_uids: c.sent_uids}
        },
        (err, num) ->
          console.log err if err
          Contacts.insert(_.extend(c, {user_id: user_id})) unless num
    console.log insertContacts.length
  .run()

fetchMails = (imapServer, user, box, isSentBox = false) ->
  # fetch latest 2000 header of mails.
  MAX_MESSAGES = 2000
  if box.messages.total > MAX_MESSAGES
    range = (box.messages.total - MAX_MESSAGES) + ":*"
  else
    range = "1:*"
  allContacts = []
  f = imapServer.seq.fetch range,
    bodies: 'HEADER.FIELDS (FROM TO CC BCC)',
    struct: true
  f.on 'message', (msg, seqno) ->
    # prefix = '(#' + seqno + ') '
    contact = {}
    msg.on 'body', (stream, info) ->
      buffer = ''
      stream.on 'data', (chunk) -> buffer += chunk.toString('utf8')
      stream.once 'end', ->
        contact = Imap.parseHeader(buffer)

    msg.once 'attributes', (attrs) -> contact.uid = attrs.uid
    msg.once 'end', ->
      # console.log contact.to.join(','), ' - ', user.services.google.email
      if isSentBox
        if contact.to
          allContacts.push contact unless contact.to.join('').match(/reply/i)
      else
        to = contact.to
        if to?.join(',').indexOf(user.services.google.email) != -1
          allContacts.push contact unless contact.from.join('').match(/reply/i)

  f.once 'error', (err) -> console.log('Fetch error: ' + err)
  f.once 'end', ->
    console.log allContacts.length
    if isSentBox
      addSentContact(allContacts, user._id)
      imapServer.end()
    else
      addContacts(allContacts, user._id)
      syncSentBox(imapServer, user)

syncInbox = (imapServer, user) ->
  imapServer.openBox 'INBOX', true, (err, box) ->
    if err
      console.log('[LoadGmail]: Open InBox error', err)
      do imapServer.end
      return
    console.log 'total messages in INBOX: ', box.messages.total
    fetchMails(imapServer, user, box)


syncSentBox = (imapServer, user) ->
  imapServer.getBoxes (err, boxes) -> 
    boxname = ''
    _.each boxes['[Gmail]']?.children, (v, k) -> 
      if _.contains v?.attribs, '\\Sent'
        boxname = '[Gmail]' +  v.delimiter + k
    if boxname
      imapServer.openBox boxname, true, (err, box) ->
        if err
          console.log('[LoadGmail]: Open InBox error', err)
          imapServer.end()
          return
        console.log "total messages in #{boxname}: ", box.messages.total
        fetchMails(imapServer, user, box, true)
    else
      imapServer.end()

@syncMail = (user_id) ->
  # find user
  user = Meteor.users.findOne 'services.google': {$exists: true}, _id: user_id
  return user unless user
  console.log user.services.google.email
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
        syncInbox(imapServer, user)
        # syncSentBox(imapServer, user)
      imapServer.once 'end', -> console.log '[SyncMail] imapServer end!!\n\n'
      imapServer.once 'error', (err) -> console.log '[SyncMail] imapServer error: ', err
      imapServer.connect()