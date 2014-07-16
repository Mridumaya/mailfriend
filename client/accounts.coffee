googleOauthOpen = (ev) ->
  ev.preventDefault()
  mixpanel.track("logs in", { });

  console.log new Date()

  button = $(ev.currentTarget)
  $(button).prop('disabled', true)
  Meteor.signInWithGoogle({
    requestPermissions: [
      "https://mail.google.com/", # imap
      "https://www.googleapis.com/auth/userinfo.profile", # profile
      "https://www.googleapis.com/auth/userinfo.email", # email
      "https://www.google.com/m8/feeds/" # contacts
    ]
    requestOfflineToken: true
    forceApprovalPrompt: true
  }, (err, mergedUserId) ->
    $(button).prop('disabled', false)
    unless err
      Meteor.call 'loadContacts', Meteor.userId(), (err) ->
        console.log err if err

        Session.set 'loggedInWithGoogle', true

        $('#login-dialog').modal('hide')
        $('#register-dialog').modal('hide')
        if Session.get 'sent_campaign_id'
          Session.set 'public', 'no'
          Router.go "edit"
        else
          Router.go "feature_select"
  )


registerOpen = (ev) ->
  ev.preventDefault()
  mixpanel.track("click goto registration button", { });

  $('#login-dialog').modal('hide')
  $('#register-dialog').modal('show')

manualLoginOpen = (ev) ->
  ev.preventDefault()
  mixpanel.track("click goto standard login button", { });

  $('#login-dialog').modal('hide')
  $('#manual-login-dialog').modal('show')


Template.welcome.helpers
  sender: ->
    sender = Session.get("senderId")

    Meteor.call 'getSenderName', sender, (e, resp) ->
      console.log e if e

      name = resp[0]
      senderId = resp[1]
      Session.set('name' + senderId, name)

    name = Session.get('name' + sender)

    if name is undefined
      name = 'Someone'

    return name


Template.welcome.rendered = ->
  mixpanel.track("Unique url opened", { })

Template.welcome.events
  'click .register': (e) ->
    registerOpen(e)

  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)

  'click .public-account': (e) ->
    delete Session.keys["OWN_MESS"]

    Router.go("publicedit")

  'click .clicked-register-public': (e) ->
    mixpanel.track("clicked on register from unique url", { })

  'click .clicked-help-public': (e) ->
    mixpanel.track("clicked on help user from unique url", { })


Template.home.events
  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)

  'click .add-google-oauth-bottom': (e) ->
    mixpanel.track("clicked on login with gmail button on the bottom", { });

  'click .register': (e) ->
    registerOpen(e)

  'click .btn-standard-login': (e) ->
    manualLoginOpen(e)

  'click #nav_down': (e) ->
    mixpanel.track("clicked on explore more on home page", { });


Template.login_dialog.rendered = ->
  mixpanel.track("view front page", { });


Template.login_dialog.events
  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)
  'click .add-google-oauth-green': (e) ->
    mixpanel.track("clicked on login with gmail big green button", { });

  'click .add-google-oauth-small': (e) ->
    mixpanel.track("clicked on login with gmail small button", { });

  'click .register': (e) ->
    registerOpen(e)

  'click .btn-standard-login': (e) ->
    manualLoginOpen(e)


Template.manual_login_dialog.events
  'click .btn-try-login': (e) ->
    e.preventDefault()
    Meteor.call "checkIfEmailVerified", $("#login-email").val(), (err, data) ->
      #console.log data
      if data
        Meteor.loginWithPassword($("#login-email").val(), $("#login-password").val(), (err) ->
          console.log err
          if err && (err.error == 403 or err.error == 400)
            apprise(err.reason)
            return
          unless err
            mixpanel.track("logs in with password", { });
            Meteor.call 'loadContacts', Meteor.userId(), (err) ->
              console.log err if err

              Session.set 'loggedInWithGoogle', false

              Meteor.call 'redirectToShareCampaign', Meteor.userId(), (err, res) ->
                if res isnt false and res.redirect.done isnt true
                  $('#manual-login-dialog').modal('hide')
                  if res.campaign isnt undefined
                    Session.set "MAIL_TITLE", res.campaign.subject
                    Session.set "ORIG_MESS", res.campaign.body
                    Session.set "slug", res.campaign.slug
                    Session.set "senderId", res.campaign.user_id
                    Session.set "searchQ", res.campaign.search_tags
                    Session.set "campaign_id", res.redirect.campaign_id
                    Session.set 'sent_campaign_id', res.redirect.campaign_id
                    Session.set 'public', 'no'
                    Router.go "edit"
                  else
                    Router.go "feature_select"
                else
                  Router.go "feature_select"
        )
      else
        apprise("Your email address was not yet verified!")


Template.register_dialog.events
  'click .add-google-oauth': (e) ->
    googleOauthOpen(e)

  'click .add-google-oauth-green': (e) ->
    mixpanel.track("clicked on login with gmail big green button", { });

  'click .add-google-oauth-small': (e) ->
    mixpanel.track("clicked on login with gmail small button", { });


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
          apprise("Email already exists, try again.")
          return
        if Session.get 'sent_campaign_id'
          # console.log Session.get 'sent_campaign_id'
          # console.log user
          Meteor.call "setRedirectToShareCampaign", user.email, Session.get 'sent_campaign_id', (err, res) ->
            return

        apprise("You have been succefully registered, please check your email for confirmation code.")
        $(".close").click()
        mixpanel.track("new user without gmail", { });
        return

        # Meteor.loginWithPassword($(form).find("#email").val(), $(form).find("#password").val(), (err) ->
        #   if err && err.error == 403
        #     apprise(err.reason)
        #     return
        #   unless err
        #     mixpanel.track("logs in with password", { });
        #     Meteor.call 'loadContacts', Meteor.userId(), (err) ->
        #
        #       Router.go("feature_select")
        # )
        #
        # Router.go("feature_select")


Template.edit_user_info.helpers
  first_name: ->
    # return Meteor.user().profile.first_name
    return Meteor.user().profile.name.split(' ')[0]
  last_name: ->
    # return Meteor.user().profile.last_name
    return Meteor.user().profile.name.split(' ')[1]


Template.edit_user_info.events
  'click .cancel': ->
    Router.go("feature_select")


Template.edit_user_info.rendered = ->
  mixpanel.track("viewed user profile", { });
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
          apprise(err.reason)
          return
        else
          Router.go("feature_select")
      )
