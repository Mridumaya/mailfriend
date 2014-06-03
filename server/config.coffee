@GlobalConfiguration= {
    init: ->
        if(Meteor.settings != undefined)
            console.log 'Starting server with following settings'
            console.log Meteor.settings

        Meteor.log.info 'Calling GlobalConfiguration init.'
        this.initGoogleOauth()
    initGoogleOauth: ->
        if(!this.checkGoogleApi() && Meteor.settings.google != undefined )
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

Meteor.methods
    checkGoogleApi: ->
        GlobalConfiguration.checkGoogleApi()