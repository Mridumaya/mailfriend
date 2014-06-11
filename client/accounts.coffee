googleOauthOpen = (ev) ->
  ev.preventDefault()
  mixpanel.track("logs in", { });
  console.log new Date()
  button = $(ev.currentTarget)
  $(button).prop('disabled', true)
  Meteor.loginWithGoogle({
    requestPermissions: ["https://mail.google.com/", # imap
                         "https://www.googleapis.com/auth/userinfo.profile", # profile
                         "https://www.googleapis.com/auth/userinfo.email", # email
                         "https://www.google.com/m8/feeds/" # contacts
    ]
    requestOfflineToken: true
    forceApprovalPrompt: true
  }, (err) ->
    $(button).prop('disabled', false)
    unless err
      Meteor.call 'loadContacts', Meteor.userId(), (err) ->
        console.log err if err
        Router.go("feature_select")
        #Session.set("STEP", "feature_select")
  )


registerOpen = (ev) ->
  ev.preventDefault()
  $('#login-dialog').modal('hide')
  mixpanel.track("click goto registration button", { });
  $('#register-dialog').modal('show')
  # Router.go("register")
  # Session.set("STEP", "register")


manualLoginOpen = (ev) ->
  ev.preventDefault()
  $('#login-dialog').modal('hide')
  mixpanel.track("click goto standard login button", { });
  $('#manual-login-dialog').modal('show')
  # Router.go("manual_login")
  #Session.set("STEP", "manual_login")


# home template events
Template.home.events
  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)

  'click .register': (e) ->
    registerOpen(e)

  'click .btn-standard-login': (e) ->
    manualLoginOpen(e)


Template.login_dialog.rendered = ->
  mixpanel.track("view front page", { });


# login template events
Template.login_dialog.events
  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)

  'click .register': (e) ->
    registerOpen(e)

  'click .btn-standard-login': (e) ->
    manualLoginOpen(e)


# manual login template events
Template.manual_login_dialog.events
  'click .btn-try-login': (e) ->
    e.preventDefault()

    Meteor.loginWithPassword($("#login-email").val(), $("#login-password").val(), (err) ->
      console.log err
      if err && (err.error == 403 or err.error == 400)
        alert(err.reason)
        return
      unless err
        mixpanel.track("logs in with password", { });
        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log err if err
          #Session.set("STEP", "feature_select")
          Router.go("feature_select")
    )


Template.register_dialog.events
  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)


Template.register_dialog.rendered = ->
  $("#frm_register").validate
    rules:
      first_name: "required"
      last_name: "required"
      email:
        required: true
        email: true
      password: "required"
      confirm_password:
        required: true
        equalTo: "#password"
    errorElement: "span"
    errorClass: "help-inline"
    highlight: (element) ->
      $(element).closest(".form-group").removeClass("has-success").addClass "has-error"
      return

    unhighlight: (element) ->
      $(element).closest(".form-group").removeClass "has-error"
      return

    submitHandler: (form) ->
      profile =
        profile:
          first_name: $(form).find("#first_name").val()
          last_name: $(form).find("#last_name").val()
          name: $(form).find("#first_name").val() + " " + $(form).find("#last_name").val()
        email: $(form).find("#email").val()
        password: $(form).find("#password").val()

      Meteor.call "create_user", profile, (err, user) ->
        console.log('[ERROR] create_user:', err) if err
        
        if err?.reason == "Email already exist."
          alert("Email already exists, try again.")
          return

        # console.log user
        mixpanel.track("new user", { });

        Meteor.loginWithPassword($(form).find("#email").val(), $(form).find("#password").val(), (err) ->
          # console.log err
          if err && err.error == 403
            alert(err.reason)
            return
          unless err
            mixpanel.track("logs in with password", { });
            Meteor.call 'loadContacts', Meteor.userId(), (err) ->
              # console.log err if err
              #Session.set("STEP", "feature_select")
              Router.go("feature_select")
        )

        Router.go("feature_select")
        # Session.set("STEP","")

Template.edit_user_info.helpers
  first_name: ->
    # return Meteor.user().profile.first_name
    return Meteor.user().profile.given_name
  last_name: ->
    # return Meteor.user().profile.last_name
    return Meteor.user().profile.family_name


Template.edit_user_info.events
  'click .cancel': ->
    Router.go("feature_select")

Template.edit_user_info.rendered = ->
  $("#frm_edit").validate
    rules:
      first_name: "required"
      last_name: "required"
    errorElement: "span"
    errorClass: "help-inline"
    highlight: (element) ->
      $(element).closest(".form-group").removeClass("has-success").addClass "has-error"
      return

    unhighlight: (element) ->
      $(element).closest(".form-group").removeClass "has-error"
      return

    submitHandler: (form) ->
      profile =
        first_name: $(form).find("#first_name").val()
        last_name: $(form).find("#last_name").val()
        name: $(form).find("#first_name").val() + " " + $(form).find("#last_name").val()
        email: $(form).find("#email").val()
        userId: Meteor.user()._id

      Meteor.call "edit_user", profile, (err, user) ->
        Router.go("feature_select")

  $("#frm_password").validate
    rules:
      old_password: "required"
      new_password: "required"
      confirm_password:
        required: true
        equalTo: "#new_password"
    errorElement: "span"
    errorClass: "help-inline"
    highlight: (element) ->
      $(element).closest(".form-group").removeClass("has-success").addClass "has-error"
      return

    unhighlight: (element) ->
      $(element).closest(".form-group").removeClass "has-error"
      return

    submitHandler: (form) ->
      Accounts.changePassword($("#old_password").val(), $("#new_password").val(), (err)->
        if err && err.error == 403
          alert(err.reason)
          return
        else
          Router.go("feature_select")
      )



