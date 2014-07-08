Accounts.config
  sendVerificationEmail: false
  forbidClientAccountCreation: true

Accounts.onCreateUser( (options,user)->

  #console.log user
  if user.services.google
    accessToken = user.services.google.accessToken

    result = Meteor.http.get('https://www.googleapis.com/oauth2/v3/userinfo',
      header:
        'User-Agent': 'Meteor MailFriend/1.0'
      params:
        access_token: accessToken
    )

    if (result.error)
      throw result.error

    console.log result.data

    profile = _.pick(result.data, 'name','given_name','family_name','profile','picture','email','email_verified','birthdate','gender','locale','hd')

    user.profile = profile
    user.loggedInWithGoogle = true
    user.introPagesDone = {'feature_select': false, 'new_campaign_first': false, 'new_campaign_second': false, 'list_campaign': false, 'inbox': false}
    user
  else
    user.customVerified = false
    user.loggedInWithGoogle = false
    user.customVerificationCode = Random.hexString(20).toLowerCase()
    user.introPagesDone = {'feature_select': false, 'new_campaign_first': false, 'new_campaign_second': false, 'list_campaign': false, 'inbox': false}
    console.log "accounts.coffee: "
    #console.log user
    console.log options
    user.profile = options.profile
    user
)
