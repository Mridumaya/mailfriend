Future = Npm.require('fibers/future')

Meteor.methods
  'sendMail': (subject, body, to) ->
    check(subject, String)
    check(body, String)
    check(to, [String])

    console.log subject
    console.log body
    console.log to

    user = Meteor.users.findOne({_id: @userId, 'services.google': {$exists: true}})
    throw new Meteor.Error '404', "sendMail user not found" unless user

    console.log Meteor.settings.google.api
    console.log Meteor.settings.google.secret

    from = user.services.google.email
    transportOptions = {
        auth: {
            XOAuth2: {
                user: from,
                clientId: Meteor.settings.google.api,
                clientSecret: Meteor.settings.google.secret,
                refreshToken: user.services.google.refreshToken,
                accessToken: Meteor.settings.google.accessToken,
                timeout: 3600
            }
        }
    }
    console.log 'send mail to ', to.join(';')
    console.log transportOptions

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

      console.log mailOptions

      transport.sendMail mailOptions, (error, responseStatus)->
        if(!error)
          console.log(responseStatus.message) # response from the server
          console.log(responseStatus.messageId) # Message-ID value used
        else
          console.log error

        onComplete(error, responseStatus)

      return future

    Future.wait(futures)
    transport.close()

    Contacts.update({email: {$in: to}, user_id: user._id}, {$inc: {sends: 1}}, multi: true)

  'sendMailUsingMandrill': (subject, body, to) ->
    #check(subject, String)
    #check(body, String)
    #check(to, [String])

    console.log subject
    console.log body
    console.log to
    Mandrill = Meteor.require 'mandrill-api'

    mandrill_client = new Mandrill.Mandrill '_Au4j-G5FADK0MFj_jZPGg'
    options =
        "message" :
            #"html": "<p>Example HTML content</p>"
            "html": body
            "text": body
            "subject": subject
            "from_email": "no-reply@mailfriend.com"
            "from_name": "Mailfriend Registration"
            "to":[
                "email": to
                #"name": "Recipient Name"
            ]
            "headers":
                "Reply-To": "no-reply@mailfriend.com"
            "important": false
            "track_opens": null
            "track_clicks": null
            "auto_text": null
        #"async": false
        #"ip_pool": "Main Pool"
        #"send_at": "10-10-2013"

    response = Meteor.sync (done) ->
        mandrill_client.messages.send options, (result) ->
            console.log(result)
            done null, result
        ,(err)->
            console.log(err)
            done err, null
    response.result || response.err
