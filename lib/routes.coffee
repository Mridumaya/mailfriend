Router.configure
  layoutTemplate: 'masterLayout'
  notFoundTemplate: 'notFound'
  loadingTemplate: 'loading'


IR_BeforeHooks =
  isLoggedIn: ->
    unless Meteor.user()
      console.log "no user"
      Router.go("home")


Router.onBeforeAction(IR_BeforeHooks.isLoggedIn, { only: ['feature_select', "edit_user_info", 'new_campaign'] } )


Router.map ->
  @route "verify-email",
    path: "/verify-email/:token"
    action: ->
      Meteor.call "verifyEmailCode", @params.token, (err)->
        console.log(err)
        if(err)
            Session.set( "errorMessage", err.reason);
        else
            Session.set( "successMessage", 'Your email verified successfully, you can now log in.');
            Session.set 'afterEmailVerified', true
        Router.go("home")
    onAfterAction: ->
      SEO.set
        title: 'Verify your email address'


  @route "home",
    layoutTemplate: "masterLogoutLayout",
    template: "home",
    path: "/home"
    onAfterAction: ->
      baseurl = Meteor.absoluteUrl("")
      
      SEO.set
        title: 'Welcome to Mailfriend'
        meta:
          'title':       'Mailfriend'
          'description': 'Mailfriend - send mail to people who care'
          'keywords':    'mailfriend, email, friend'
        og:
          'image':     baseurl + 'images/logo.png'
          'title':     'Mailfriend'
          'url':       baseurl + 'home/'
          'site_name': 'Mailfriend'
          'type':      'website'


  @route "about",
    layoutTemplate: "publicMasterLayout",
    template: "about",
    path: "/about"
    onAfterAction: ->
      baseurl = Meteor.absoluteUrl("")

      SEO.set
        title: 'About Mailfriend'
        meta:
          'title':       'About Mailfriend'
          'description': 'Mailfriend - send mail to people who care'
          'keywords':    'mailfriend, email, friend'
        og:
          'image':     baseurl + 'images/logo.png'
          'title':     'About Mailfriend'
          'url':       baseurl + 'about/'
          'site_name': 'Mailfriend'
          'type':      'website'


  @route "faq",
    layoutTemplate: "publicMasterLayout",
    template: "faq",
    path: "/faq"
    onAfterAction: ->
      baseurl = Meteor.absoluteUrl("")

      SEO.set
        title: 'Mailfriend FAQ'
        meta:
          'title':       'Mailfriend FAQ'
          'description': 'Mailfriend - send mail to people who care'
          'keywords':    'mailfriend, email, friend'
        og:
          'image':     baseurl + 'images/logo.png'
          'title':     'Mailfriend FAQ'
          'url':       baseurl + 'faq/'
          'site_name': 'Mailfriend'
          'type':      'website'


  @route "feature_select",
    layoutTemplate: 'masterLayout',
    path: "/"
    onAfterAction: ->
      SEO.set
        title: 'Welcome to Mailfriend'


  @route "edit_user_info",
    path: "/user/edit",
    onAfterAction: ->
      SEO.set
        title: 'Edit your profile data'


  @route "new_campaign",
    path: "/campaign/new",
    data: ->
      Campaigns.findOne _id: Session.get("campaign_id") if Session.get("campaign_id")
    onAfterAction: ->
      campaignId = Session.get("campaign_id")
      if campaignId
        title = 'Edit your campaign'
      else
        title = 'New campaign'
      SEO.set
        title: title


  @route "delete_campaign",
    path: "campaign/delete/:_id",


  @route "list_campaign",
    path: "/campaigns"
    onAfterAction: ->
      SEO.set
        title: 'Existing campaigns'


  @route "confirm",
    path: "/campaign/confirm",


  @route "share_via_email",
    path: "/campaign/share_via_email",


  @route "inbox",
    path: "/inbox",
    data: ->
      Meteor.subscribe 'allcampaigns', ->
    onAfterAction: ->
      SEO.set
        title: 'My inbox'


  @route "404",
    path: '/404',
    layoutTemplate: "publicMasterLayout",
    template: "notFound",
    onAfterAction: ->
      SEO.set
        title: '404 - Page not found'


# non-public stuff ------------------------------------------------------------------------------------------------------------------------

  @route "edit",
    path: '/edit',
    template: "public_edit"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


  @route "searchcontacts",
    path: '/search-contacts',
    template: "public_search_contacts"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


  @route "contactlist",
    path: '/contact-list',
    template: "public_contact_list"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


  @route "forwardconfirm",
    path: '/confirm',
    template: "public_confirm"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


# public forward --------------------------------------------------------------------------------------------------------------------------

  @route "public_welcome",
    path: '/:user_id/:slug',
    layoutTemplate: "masterLogoutLayout",
    # template: "welcome",
    waitOn: ->
      return [ Meteor.subscribe 'publicCampaigns', @params.user_id, @params.slug ]

    action: ->
      if @ready()
        @render('welcome')
      else
        @render('loading')

    data: ->
      campaign = Campaigns.findOne({slug: @params.slug, user_id: @params.user_id})
      sender = Meteor.users.findOne({_id: @params.user_id})

      if campaign isnt undefined
        Session.set "MAIL_TITLE", campaign.subject
        Session.set "ORIG_MESS", campaign.body
        Session.set "slug", @params.slug
        Session.set "senderId", @params.user_id
        Session.set "searchQ", campaign.search_tags
        Session.set "campaign_id", campaign._id
        Session.set "sent_campaign_id", campaign._id
        Session.set "public", 'yes'

      return {'campaign': campaign, 'sender': sender}

    onAfterAction: ->
      campaign = @data().campaign
      sender = @data().sender
      baseurl = Meteor.absoluteUrl("")

      if campaign isnt undefined
        sender_name = sender.profile.name + "'s"
        SEO.set
          title: 'Get the word out for ' + sender_name + ' mailfriend campaign'
          meta:
            'title':       'Get the word out for ' + sender_name + ' mailfriend campaign'
            'description': 'Get the word out for ' + sender_name + ' mailfriend campaign'
            'keywords':    'mailfriend, email, friend'
          og:
            'image':     baseurl + 'images/logo.png'
            'title':     'Get the word out for ' + sender_name + ' mailfriend campaign'
            'url':       baseurl + @params.user_id + '/' + @params.slug + '/'
            'site_name': 'Mailfriend'
            'type':      'website'
      else
        SEO.set
          title: 'Get the word out for this mailfriend campaign'
          meta:
            'title':       'Get the word out for this mailfriend campaign'
            'description': 'Get the word out for this mailfriend campaign'
            'keywords':    'mailfriend, email, friend'
          og:
            'image':     baseurl + 'images/logo.png'
            'title':     'Get the word out for this mailfriend campaign'
            'url':       baseurl + @params.user_id + '/' + @params.slug + '/'
            'site_name': 'Mailfriend'
            'type':      'website'      

  @route "publicedit",
    path: '/public-edit',
    layoutTemplate: "publicMasterLayout",
    template: "public_edit"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


  @route "publicsearchcontacts",
    path: '/public-search-contacts',
    layoutTemplate: "publicMasterLayout",
    template: "public_search_contacts"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


  @route "publiccontactlist",
    path: '/public-contact-list',
    layoutTemplate: "publicMasterLayout",
    template: "public_contact_list"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'


  @route "publicconfirm",
    path: '/public-confirm',
    layoutTemplate: "publicMasterLayout",
    template: "public_confirm"
    onAfterAction: ->
      SEO.set
        title: 'Forward a message'
