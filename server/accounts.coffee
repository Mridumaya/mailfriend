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
    user
  else
    console.log "accounts.coffee: "
    #console.log user
    console.log options
    user.profile = options.profile
    user
)