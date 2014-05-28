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

  @route "login",
    layoutTemplate: "masterLogoutLayout",
    template: "login",
    path: "/login"

  @route "register",
    layoutTemplate: "masterLogoutLayout",
    template: "register",
    path: "/register"

  @route "about",
    layoutTemplate: "masterLogoutLayout",
    template: "about",
    path: "/about"

  @route "faq",
    layoutTemplate: "masterLogoutLayout",
    template: "faq",
    path: "/faq"

  @route "manual_login",
    layoutTemplate: "masterLogoutLayout",
    template: "manual_login",
    path: "/manual_login"

  @route "feature_select",
    layoutTemplate: 'masterLayout',
    path: "/"

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