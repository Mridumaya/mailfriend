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
    action: ()->
      Accounts.verifyEmail @params.token, (err)->
        console.log(err)
        if(err)
            Session.set( "errorMessage", err.reason);
        else
            Session.set( "successMessage", 'Your mail verified successfully.');
        Router.go("login")

  @route "home",
    layoutTemplate: "masterLogoutLayout",
    template: "home",
    path: "/home"

  @route "about",
    layoutTemplate: "masterLogoutLayout",
    template: "about",
    path: "/about"

  @route "faq",
    layoutTemplate: "masterLogoutLayout",
    template: "faq",
    path: "/faq"

  @route "feature_select",
    layoutTemplate: 'masterLayout',
    path: "/"

  @route "edit_user_info",
    path: "/user/edit",

  @route "new_campaign",
    path: "/campaign/new",
    data: ->
      Campaigns.findOne _id: Session.get("campaign_id") if Session.get("campaign_id")

  @route "delete_campaign",
    path: "campaign/delete/:_id",

  @route "list_campaign",
    path: "/campaigns"

  @route "confirm",
    path: "/campaign/confirm",

  @route "share_via_email",
    path: "/campaign/share_via_email",

  @route "inbox",
    path: "/inbox",
 
  @route "404",
    path: '/404',
    layoutTemplate: "publicMasterLayout",
    template: "notFound",

  # public stuff 
  @route "public_welcome",
    path: '/:user_id/:slug',
    layoutTemplate: "masterLogoutLayout",
    template: "welcome",
    
    data: ->
      Meteor.subscribe 'publicCampaigns', @params.user_id, @params.slug, ->
        console.log 'Public campaigns'

      #user = Meteor.users.findOne({username: @params.username});
      campaign = Campaigns.findOne {slug: @params.slug, user_id: @params.user_id}
      console.log campaign

      if campaign isnt undefined
        Session.set "MAIL_TITLE", campaign.subject
        Session.set "ORIG_MESS", campaign.body
        Session.set "slug", @params.slug
        Session.set "senderId", @params.user_id
        Session.set "searchQ", campaign.search_tags
        Session.set "campaign_id", campaign._id
        # Session.set 'user_id', @params.user_id
        # console.log Session.get "MAIL_TITLE"
      # else
      #   Router.go("404")
      #   return false
      campaign

  @route "publicedit",
    path: '/public-edit',
    layoutTemplate: "publicMasterLayout",
    template: "public_edit"

  @route "publicsearchcontacts",
    path: '/public-search-contacts',
    layoutTemplate: "publicMasterLayout",
    template: "public_search_contacts", 

  @route "publiccontactlist",
    path: '/public-contact-list',
    layoutTemplate: "publicMasterLayout",
    template: "public_contact_list", 

  @route "publicconfirm",
    path: '/public-confirm',
    layoutTemplate: "publicMasterLayout",
    template: "public_confirm", 