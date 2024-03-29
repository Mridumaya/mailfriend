Future = Npm.require('fibers/future')

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
    console.log 'send mail to ', to.join(';')
    transport = Nodemailer.createTransport "Gmail", transportOptions

    from = "#{user.services.google.name} <#{from}>"

    futures = _.map to, (toEmail) ->
      future = new Future()
      onComplete = future.resolver()

      mailOptions =
        from: from
        to: toEmail
        subject: subject
        html: body
        generateTextFromHTML: true

      transport.sendMail mailOptions, (error, responseStatus)->
        if(!error)
          console.log(responseStatus.message) # response from the server
          console.log(responseStatus.messageId) # Message-ID value used
        onComplete(error, responseStatus)

      return future

    Future.wait(futures)
    transport.close()

    Contacts.update({email: {$in: to}, user_id: user._id}, {$inc: {sends: 1}}, multi: true)