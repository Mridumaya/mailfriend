Meteor.startup ->

  googleOauth =
    id: "641565285402-b7u0f11mjhsuapuhthn3ntqn1u4jpbpp.apps.googleusercontent.com"
    secret: "quILGppmE6wJGcmULASCvAmF"

  Meteor.settings.google = googleOauth

  # first, remove configuration entry in case service is already configured
  Accounts.loginServiceConfiguration.remove service: "google"
  Accounts.loginServiceConfiguration.insert
    service: "google"
    clientId: Meteor.settings.google.id
    secret: Meteor.settings.google.secret
