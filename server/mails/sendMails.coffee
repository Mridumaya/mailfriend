Meteor.methods
  'sendMail': ->
    user = Meteor.users.findOne({_id: this.userId, 'services.google': {$exists: true}})
    throw new Meteor.Error '404', "sendMail user not found" unless user

    from = user.services.google.email
    transportOptions = {
        auth: {
            XOAuth2: {
                user: from,
                clientId: Meteor.settings.google.id,
                clientSecret: Meteor.settings.google.secret,
                refreshToken: user.services.google.refreshToken,
                accessToken: Meteor.settings.google.accessToken,
                timeout: 3600
            }
        }
    }

    transport = Nodemailer.createTransport "Gmail", transportOptions

    mailOptions =
      from: from
      to: "longliangyou@gmail.com"
      subject: "Test: Hello world!"
      text: "Plaintext body"

    transport.sendMail mailOptions, (error, responseStatus)->
      if(!error)
        console.log(responseStatus.message) # response from the server
        console.log(responseStatus.messageId) # Message-ID value used
      transport.close()