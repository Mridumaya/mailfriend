@GlobalConfiguration = {
    init: ->
        # if(Meteor.settings != undefined)
        #     Meteor.log.info 'Starting server with following settings'
        # else
        #     Meteor.settings = JSON.parse(Assets.getText("settings.json"));

        if Meteor.absoluteUrl() == 'http://localhost:3000/'
            # Meteor.settings = JSON.parse(Assets.getText("settings_local.json"))
            Meteor.settings.public.custom = JSON.parse(Assets.getText("pollenpost.json"))

        else if Meteor.absoluteUrl() == 'http://jacint.meteor.com/'
            Meteor.settings = JSON.parse(Assets.getText("settings_live.json"))

        else if Meteor.absoluteUrl() == 'http://borkom.meteor.com/'
            Meteor.settings = JSON.parse(Assets.getText("settings_borkom.json"))
            Meteor.settings.public.custom = JSON.parse(Assets.getText("pollenpost.json"))

        else if Meteor.absoluteUrl() == 'http://www.pollenpost.com/'
            Meteor.settings = JSON.parse(Assets.getText("settings_pollen.json"))
            Meteor.settings.public.custom = JSON.parse(Assets.getText("pollenpost.json"))

        else if Meteor.absoluteUrl() == 'http://www.hirenurture.com/'
            Meteor.settings = JSON.parse(Assets.getText("settings_hirenurture.json"))
            Meteor.settings.public.custom = JSON.parse(Assets.getText("hirenurture.json"))

        else
            Meteor.settings = JSON.parse(Assets.getText("settings_live.json"))

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

Meteor.methods
    checkGoogleApi: () ->
        GlobalConfiguration.checkGoogleApi()

    initGoogleOauth: () ->
        GlobalConfiguration.initGoogleOauth()
