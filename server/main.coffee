Meteor.startup ->
  switch Meteor.absoluteUrl()
    when "http://localhost:3000/"
      googleOauth =
        url: Meteor.absoluteUrl()
        id: "641565285402-b7u0f11mjhsuapuhthn3ntqn1u4jpbpp.apps.googleusercontent.com"
        secret: "quILGppmE6wJGcmULASCvAmF"
    when "http://mailfriend.meteor.com/"
      googleOauth =
        url: Meteor.absoluteUrl()
        id: "1082152336799-raue9st6ro4j1flt6fs8jcl6e2pdch6s.apps.googleusercontent.com"
        secret: "tCMyRbEI3jibBaQM9B7TkEcs"
  Meteor.settings.google = googleOauth
  console.log Meteor.settings
  # first, remove configuration entry in case service is already configured
  Accounts.loginServiceConfiguration.remove service: "google"
  Accounts.loginServiceConfiguration.insert
    service: "google"
    clientId: Meteor.settings.google.id
    secret: Meteor.settings.google.secret