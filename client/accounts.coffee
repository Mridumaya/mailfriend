Template.login.events
  'click .add-google-oauth': (e) ->
    mixpanel.track("logs in", { });
    console.log new Date()
    button = $(e.currentTarget)
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
          Session.set("STEP", "feature_select")
    )
  'click #register': (e) ->
    e.preventDefault()
    Session.set("STEP", "register")
  'click .btn-standard-login': (e) ->
    Session.set("STEP", "standard_login")

Template.login.rendered = ->
  mixpanel.track("view front page", { });

Template.standard_login.events
  'click .btn-try-login': (e) ->
    e.preventDefault()
    Meteor.loginWithPassword($("#email").val(), $("#password").val(), (err) ->
      console.log err
      if err && err.error == 403
        alert(err.reason)
        return
      unless err
        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log err if err
          Session.set("STEP", "feature_select")
    )

Template.register.rendered = ->
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

        console.log user
        Session.set("STEP","")

Template.edit_user_info.helpers
  first_name: ->
    console.log Meteor.user().profile.first_name
    return Meteor.user().profile.first_name
  last_name: ->
    return Meteor.user().profile.last_name

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
        Session.set("STEP", "feature_select")

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
          Session.set("STEP", "feature_select")
      )



