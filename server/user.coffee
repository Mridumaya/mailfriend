Meteor.methods
  create_user: (profile) ->
    existingUser = Meteor.users.findOne({"emails.address": profile.email})
    if !existingUser
      autoUsername = Meteor.call('build_unique_username_by_email', profile.email)
      profile.username = autoUsername
      userId = Accounts.createUser(profile)

      #Send Verification Mail
      #Following Line will generate email verification token
      #It will not send mail as we have set the MAIL_URL env
      # Accounts.sendVerificationEmail userId

      #Get User Details
      user = Meteor.users.findOne ({_id: userId})
      body = "Hello " + user.profile.first_name + "<br>"
      body += "To verify your account email, simply click the link below.<br>"
      body += Meteor.absoluteUrl() + "verify-email/" + user.customVerificationCode + "<br>"
      # body += Meteor.absoluteUrl() + "verify-email/" + user.services.email.verificationTokens[0].token + "<br>"
      body += "Thanks<br>"

      subject = "Verify your email address on " + Meteor.absoluteUrl()
      Meteor.call "sendMailUsingMandrill", subject, body, user.emails[0].address
    else
      throw new Meteor.Error(403, 'Email already exist.')

    return {first_name: profile.profile.first_name, last_name: profile.profile.last_name, username: profile.username, email: profile.email, userId: createdUser?._id}

  edit_user: (profile) ->
    createdUser = Meteor.users.findOne({_id: profile.userId})
    if createdUser
      Meteor.users.update({_id: profile.userId}, $set: { "profile.first_name": profile.first_name, "profile.last_name": profile.last_name, "profile.name": profile.name } )
    else
      throw new Meteor.Error(403, 'User do not exists')

  verifyEmailCode: (code) ->
    user = Meteor.users.findOne({"customVerificationCode":code})
    if not user
      return {reason: "Wrong verification code"}
    else
      Meteor.users.update({_id: user._id}, $set: { "customVerified": true, "emails": [{"address": user.emails[0].address, "verified": true}] })
      console.log user
      return false
    # console.log user.services.email.verificationTokens
    #code

  checkIfEmailVerified: (email) ->
    user = Meteor.users.findOne({ emails: { $elemMatch: { address: email } } })
    console.log user
    user.customVerified
