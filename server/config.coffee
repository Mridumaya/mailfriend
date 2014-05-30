@GlobalConfiguration = {
    init: ->
        if(Meteor.settings != undefined)
            Meteor.log.info 'Starting server with following settings'
            console.log Meteor.settings

        Meteor.log.info 'Calling GlobalConfiguration init.'
        this.initGoogleOauth()

    initGoogleOauth: ->
        if(!this.checkGoogleApi() && Meteor.settings.google != undefined)
            Meteor.log.info 'Setting Google API keys.'
            ServiceConfiguration.configurations.remove service: "google"
            ServiceConfiguration.configurations.insert
              service: "google"
              clientId: Meteor.settings.google.api
              secret: Meteor.settings.google.secret
              domain: Meteor.absoluteUrl()
        else
            Meteor.log.info 'Google API keys already set.'

    checkGoogleApi: ->
        googleSettings = ServiceConfiguration.configurations.findOne service: 'google', domain: Meteor.absoluteUrl()
        !!googleSettings
}

Meteor.methodsz
    # checkGoogleApi: () ->
    #     GlobalConfiguration.checkGoogleApi() # temporarily commented out, have to find solution how to load settings on startup

    # initGoogleOauth: () ->
    #     GlobalConfiguration.initGoogleOauth() # temporarily commented out, have to find solution how to load settings on startup
