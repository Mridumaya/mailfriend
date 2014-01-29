Meteor.methods
  'sendMail': (subject, body, to) ->
    check(subject, String)
    check(body, String)
    check(to, [String])

    user = Meteor.users.findOne({_id: @userId, 'services.google': {$exists: true}})
    throw new Meteor.Error '404', "sendMail user not found" unless user

    email = user.services.google.email
    transportOptions = {
        auth: {
            XOAuth2: {
                user: email,
                clientId: Meteor.settings.google.id,
                clientSecret: Meteor.settings.google.secret,
                refreshToken: user.services.google.refreshToken,
                accessToken: Meteor.settings.google.accessToken,
                timeout: 3600
            }
        }
    }
    console.log 'send mail to ', to
    transport = Nodemailer.createTransport "Gmail", transportOptions

    from = "#{user.services.google.name} <#{from}>"
    mailOptions =
      from: from
      to: to
      subject: subject
      text: body

    transport.sendMail mailOptions, (error, responseStatus)->
      if(!error)
        console.log(responseStatus.message) # response from the server
        console.log(responseStatus.messageId) # Message-ID value used
      transport.close()