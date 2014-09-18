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
      uid: {uid: c.uid, date: c.date}
      email: nameAndEmail.email
      name: nameAndEmail.name
    }

addContacts = (contacts, user_id, searchQ) ->
  console.log "addContacts: ", contacts.length, " searchQ: ", searchQ
  parsedContacts = parseReveivedContacts(contacts)
  groupedContacts = _.groupBy parsedContacts, (c) -> c.email
  insertContacts = _.map groupedContacts, (v, k) ->
    return {
      from: v[0].from
      email: k
      name: _.find(v, (c)->c.name)?.name || ''
      uids: _.pluck(v, 'uid')
    }
  console.log "addContacts: ", contacts.length, " searchQ: ", searchQ
  Fiber = Npm.require("fibers")
  Fiber ->
    dbContacts = Contacts.find({user_id: user_id}, {fields: {uids: true}}).fetch()
    existEmails = _.pluck dbContacts, 'email'
    contacts = _.filter insertContacts, (c) -> !_.contains(existEmails, c.email)
    if contacts isnt null
      _.each contacts, (c)->
        Contacts.update {email: c.email, user_id: user_id},
          {
            $set: {uids: c.uids}
            $addToSet: {searchQ: searchQ}
          },
          (err, num) ->
            console.log err if err
            Contacts.insert(_.extend(c, {user_id: user_id, searchQ: [searchQ]})) unless num
    console.log insertContacts.length
  .run()

parseSentContacts = (contacts) ->
  _.map contacts, (c) ->
    from = c.to?[0]
    nameAndEmail = splitNameAndEmail from
    return {
      from: from
      uid: {uid: c.uid, date: c.date}
      email: nameAndEmail.email
      name: nameAndEmail.name
    }

closeServer = (imapServer, session_id) ->
  console.log 'Closing imapServer'
  Fiber = Npm.require("fibers")
  Fiber ->
    console.log 'Removing Session id from search status'
    SearchStatus.remove {session_id: session_id}
  .run()
  do imapServer.end

addSentContact = (contacts, user_id) ->
  subContacts = []
  if contacts isnt null
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
    if contacts isnt null
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

fetchMails = (imapServer, user, session_id, box, isSentBox, searchQ = '') ->
  # fetch latest 2000 header of mails.
  if user.profile?.isLoadAll
    MAX_MESSAGES = 100*1000
  else
    MAX_MESSAGES = 2000

  if box.messages.total > MAX_MESSAGES
    range = (box.messages.total - MAX_MESSAGES) + ":*"
  else
    range = "1:*"

  if searchQ
    console.log "[SyncMail] 3. search Q: ", searchQ
    orSearchQ = searchQ.replace /\ /g, ' OR '
    imapServer.search [['X-GM-RAW', "-in:draft (#{orSearchQ})"]], (err, results) ->
      if err
        console.log('[LoadGmail]: Open InBox error', err)
        closeServer imapServer, session_id
        return
      range = results.slice(-MAX_MESSAGES)
      if range.length > 0
        console.log range.length
        fetchAllMails(imapServer, user, session_id, box, range, false, searchQ)
      else
        console.log 'result-range', results, range
        closeServer imapServer, session_id
  else
    console.log "[SyncMail] 3. fetch message"
    fetchAllMails(imapServer, user, session_id, box, range, isSentBox, searchQ)

fetchAllMails = (imapServer, user, session_id, box, range, isSentBox, searchQ) ->
  console.log '[SyncMail] 4. fetch ALL message: ', searchQ
  allContacts = []
  f = imapServer.fetch range,
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

    msg.once 'attributes', (attrs) ->
      contact.uid = attrs.uid
      contact.date = attrs.date
    msg.once 'end', ->
      # console.log contact.to, ' - ', contact.from
      if isSentBox
        if contact.to
          contact.to = contact.to[0].split(',')
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
      closeServer imapServer, session_id
    else
      addContacts(allContacts, user._id, searchQ)
      if searchQ
        closeServer imapServer, session_id
      else
        syncSentBox(imapServer, user, session_id)



syncInbox = (imapServer, user, session_id, searchQ = '') ->
  #imapServer.openBox 'INBOX', true, (err, box) ->
  imapServer.openBox '[Gmail]/All Mail', true, (err, box) ->
    if err
      console.log('[LoadGmail]: Open InBox error', err)
      closeServer imapServer, session_id
      return
    console.log 'total messages in #INBOX: ', box.messages.total, " ", searchQ
    fetchMails(imapServer, user, session_id, box, false, searchQ)

syncSentBox = (imapServer, user, session_id) ->
  imapServer.getBoxes (err, boxes) ->
    boxname = ''
    _.each boxes['[Gmail]']?.children, (v, k) ->
      if _.contains v?.attribs, '\\Sent'
        boxname = '[Gmail]' +  v.delimiter + k
    if boxname
      imapServer.openBox boxname, true, (err, box) ->
        if err
          console.log('[LoadGmail]: Open InBox error', err)
          closeServer imapServer, session_id
          return
        console.log "total messages in ##{boxname}: ", box.messages.total
        fetchMails(imapServer, user, session_id, box, true)
    else
    if user.profile?.isLoadAll
      closeServer imapServer, session_id

@syncMail = (user_id, session_id, searchQ = '') ->
  # find user
  user = Meteor.users.findOne 'services.google': {$exists: true}, _id: user_id
  return unless user
  # console.log user.services.google.email
  # console.log Meteor.settings.google.api
  # console.log Meteor.settings.google.secret

  xoauth2gen = XOauth2.createXOAuth2Generator
                user: user.services.google.email
                clientId: Meteor.settings.google.api
                clientSecret: Meteor.settings.google.secret
                refreshToken: user.services.google.refreshToken
  xoauth2gen.getToken (err, token) ->
    if err
      console.error "[SyncMail-(#{user.services.google.email})] get xoauth2gen token error: ", err, xoauth2gen.options.user
      Fiber = Npm.require("fibers")
      Fiber ->
        console.log 'Removing Session id from search status'
        SearchStatus.remove {session_id: session_id}
      .run()
    else
      console.log "[SyncMail-(#{user.services.google.email})] 1. got xoauth2gen"
      imapServer = new Imap({
        xoauth2: token
        host: 'imap.gmail.com'
        port: 993
        tls: true
        # debug: console.log
        tlsOptions:
          rejectUnauthorized: false
      })
      imapServer.once 'ready', ->
        console.log "[SyncMail-(#{user.services.google.email})] 2. connected imap ", searchQ
        syncInbox(imapServer, user, session_id, searchQ)
      imapServer.once 'end', ->
        console.log "[SyncMail-(#{user.services.google.email})] imapServer end!!\n\n"
        Fiber = Npm.require("fibers")
        Fiber ->
          console.log 'Removing Session id from search status'
          SearchStatus.remove {session_id: session_id}
        .run()
      imapServer.once 'error', (err) ->
        console.log "[SyncMail-(#{user.services.google.email})] imapServer error: ", err
        Fiber = Npm.require("fibers")
        Fiber ->
          console.log 'Removing Session id from search status'
          SearchStatus.remove {session_id: session_id}
        .run()
      imapServer.connect()
