
@GoogleAccountChecker =
  checkGoogleApi: ()->
    Meteor.call 'checkGoogleApi', (err, result) ->
      if err
        console.log 'checkGoogleApi', err
      else
        Session.set('GOOGLE_API', !!result)


