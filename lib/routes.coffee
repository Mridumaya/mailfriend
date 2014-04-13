IR_BeforeHooks =
  isLoggedIn: ->
    unless Meteor.user()
      console.log "no user"
      Router.go("login")

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
  @route "feature_select",
    path: "/",
    layoutTemplate: "masterLayout",
  @route "login",
    layoutTemplate: "masterLogoutLayout"
  @route "register",
    layoutTemplate: "masterLogoutLayout"
  @route "standard_login",
    path: "/manual_login",
    layoutTemplate: "masterLogoutLayout"
  @route "edit_user_info",
    path: "/user_edit",
    layoutTemplate: "masterLayout"
  @route "new_campaign",
    path: "/campaign",
    layoutTemplate: "masterLayout"
  @route "confirm",
    path: "/campaign/confirm",
    layoutTemplate: "masterLayout"
