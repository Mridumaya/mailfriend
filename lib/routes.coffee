Router.configure
  layoutTemplate: 'masterLayout'
  notFoundTemplate: 'notFound'
  loadingTemplate: 'loading'

IR_BeforeHooks =
  isLoggedIn: ->
    unless Meteor.user()
      console.log "no user"
      Router.go("login")

Router.onBeforeAction(IR_BeforeHooks.isLoggedIn, { only: ['feature_select', "edit_user_info", 'new_campaign'] } )

Router.map ->
  @route "publicLayout",
    path: '/:user_id/:slug',
    layoutTemplate: 'publicLayout',
    data: ->
      Meteor.subscribe 'publicCampaigns', @params.user_id, @params.slug, ->
        console.log 'Public campaigns'

      #user = Meteor.users.findOne({username: @params.username});
      campaign = Campaigns.findOne {slug: @params.slug, user_id: @params.user_id}
      console.log campaign

      if campaign isnt `undefined`
        Session.set "MAIL_TITLE", campaign.subject
        Session.set "ORIG_MESS", campaign.body
        #Session.set 'slug', @params.slug
        #Session.set 'user_id', @params.user_id
        #Session.set 'STEP', "public_welcome"
        Session.set 'STEP', "public_signup"
      console.log Session.get "MAIL_TITLE"
      campaign

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
  @route "feature_select",
    layoutTemplate: 'masterLayout',
    path: "/"
  @route "home",
    layoutTemplate: 'masterLayout',
    path: "/"  
  @route "login",
    layoutTemplate: "masterLogoutLayout"
  @route "register",
    layoutTemplate: "masterLogoutLayout"
  @route "standard_login",
    path: "/manual_login",
    layoutTemplate: "masterLogoutLayout"
  @route "edit_user_info",
    path: "/user/edit",
  @route "new_campaign",
    path: "/campaign/new",
    data: ->
      Campaigns.findOne _id: Session.get("campaign_id")  if Session.get("campaign_id")
  @route "delete_campaign",
    path: "campaign/delete/:_id",
  @route "list_campaign",
    path: "/campaigns"
  @route "confirm",
    path: "/campaign/confirm",

