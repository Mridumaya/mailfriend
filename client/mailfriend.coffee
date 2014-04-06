Template.layout.helpers
  hasLogin: ->
    !!Meteor.user()
  stepIsChooseFeature: ->
     Session.equals("STEP", "feature_select")
  stepIsWelcome: ->
    Session.equals('STEP', "welcome")
  stepIsSearchQ: ->
    Session.equals('STEP', "searchq")
  stepIsNewCampaign: ->
    console.log "new capaign"
    Session.equals('STEP', "new_campaign")
  stepIsConfirm: ->
    Session.equals('STEP', "confirm")
  picture: ->
    user = Meteor.user()
    console.log("Hello")
    console.log(user)
    if user and user.profile and user.profile.picture
      return user.profile.picture
    return 'images/default_user.jpg'


Template.layout.events
  'click .logout': (e) ->
    e.preventDefault
    Meteor.logout()
    return true


Template.welcome.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name.split(" ")[0]
    else
      ''
  own_message: ->
    return Session.get("OWN_MESS", '')

  mail_title: ->
    return Session.get("MAIL_TITLE", '')

  orig_message: ->
    return Session.get("ORIG_MESS", 'This is some exciting message that is going to be placed here')

Template.welcome.events
  'click .original-message': (e) ->
    div = $(e.currentTarget)
    if($(div).attr("contenteditable"))
      return true;


    $("#defMessageModal").modal("show")

  'click .msg-password': (e) ->
    console.log "test"
    password = $("#msg-password").val()
    Meteor.call "checkPassword", Meteor.userId(), password, (data) ->
      console.log "entered " + data
      #if data == true
      $("#original_message").attr("contenteditable", true)
      $("#defMessageModal").modal("hide")
  'click .welcome-to-searchq': (e) ->
    Session.set("ORIG_MESS", $("#original_message").text())
    Session.set("OWN_MESS", $("#own_message").val())
    Session.set("MAIL_TITLE", $("#subject").val())
    Session.set("STEP", "searchq")


Template.welcome.rendered = ->
  mixpanel.track("visits step 1 page", { });
  Session.setDefault("ORIG_MESS", 'This is some exciting message that is going to be placed here')


Template.feature_select.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name.split(" ")[0]
    else
      ''

Template.feature_select.events
  'click .btn-create-campaign': (e) ->
    Session.set('STEP', "new_campaign")
  'click .btn-view-campaign': (e) ->
    Session.set("STEP", "welcome")
  'click .btn-view-messages': (e) ->
    Session.set("STEP", "welcome")

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

Template.login.rendered = ->
  mixpanel.track("view front page", { });




Template.searchQ.helpers
  searchQ: ->
    Session.get('searchQ') || ''


Template.searchQ.rendered = ->
  mixpanel.track("visits step 2 page", { });

Template.searchQ.events
  'click .search-button': (e) ->
    searchQuery = $('.search-query').val().trim()
    if searchQuery
      $(e.target).prop('disabled', true)
      # Meteor.setTimeout ->
      #   $(e.target).prop('disabled', false)
      # , 60*1000
      searchContacts searchQuery, ->
        $(e.target).prop('disabled', false)
        Session.set('STEP', "new_campaign")
    else
      $("#sq_error").toggleClass("hidden")

  'keypress .search-query': (e) ->
     $("#sq_error").addClass("hidden")

  'click .searchq-to-welcome': (e) ->
     Session.set("STEP", "welcome")

searchContacts = (searchQuery, cb) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'searchContacts', searchQuery, (err) ->
        Session.set('searchQ', searchQuery)
        console.log 'searchContact Error: ', err if err
        cb()
    else
      searchContacts(searchQuery)
  , 500

Template.confirm.rendered = ->
  mixpanel.track("visits step 4 page", { });
  emails = Session.get("CONF_DATA")
  body = Session.get("ORIG_MESS") + Session.get("OWN_MESS")

  to = _.map emails, (e) -> '<p class="email" style="margin:0 0 0;">' + e + '</p>'
  $('.draft-subject').text((Session.get("MAIL_TITLE") || "") + "Invitation")
  $('.draft-body').html(body)
  $('.draft-to').html(to.join(''))

Template.confirm.events
  'click .confirm-to-contact-list': (e) ->
    mixpanel.track("click on cancel/back button", { });
    Session.set("STEP", "new_campaign")

  'click #facebook': (e) ->
    window.open('https://www.facebook.com/sharer/sharer.php?u=http://mailfriend.meteor.com/', 'facebook-share-dialog', 'width=626,height=436');
  'click #twitter': (e) ->
    window.open("http://twitter.com/share?text=" + encodeURIComponent("Check this cool pictures application http://mailfriend.meteor.com/"), 'twitter', "width=575, height=400");
  'click #google': (e) ->
    window.open('https://plus.google.com/share?url=http://mailfriend.meteor.com/', '', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=600,width=600');
  'click #linkedin': (e) ->
    window.open("http://www.linkedin.com/shareArticle?mini=true&url=http://mailfriend.meteor.com/", '', "width=620, height=432");

  'click button.draft-send': (e) ->
    subject = $('.draft-subject').text()
    body = $('.draft-body').html()
    to = []
    $('.preview .draft-to p.email').each -> to.push $(this).text()
    console.log subject, body, to
    $('.draft-send').prop('disabled', true)
    #sharingBody = $('.email-body2').code()
    sharingBody = body


    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      if err
        console.log "greska"
        console.log err
      else
        sharing = Sharings.findOne({type: 'email'})
        if sharing
          Sharings.update sharing._id,
            $set:
              subject: subject
              htmlBody: sharingBody
        else
          Sharings.insert
            type: 'email'
            subject: subject
            htmlBody: sharingBody
        mixpanel.track("send email", { });
        console.log 'send mail success'
        $(".success").removeClass("hidden")
        $('.draft-send').prop('disabled', false)
        $('.draft-close').trigger('click')





Template.compose.helpers
  webUrl: ->
    Meteor.absoluteUrl()


  subject: ->
    Sharings.findOne(type: 'email')?.subject



Template.compose.rendered = ->
  sharing = Sharings.findOne()
  if sharing
    $(this.find('.email-subject')).val(sharing.subject)
    $(this.find('.email-body2')).html(sharing.htmlBody)

  # $(this.find('.email-subject')).focus() if Meteor.user()
  $(this.find('.alert-body')).hide()
  $(this.find('.email-send')).prop('disabled', !Meteor.user())
  $(this.find('.gmail-received')).prop('checked', true) if Session.equals('FILTER_GMAIL_RECEIVED', true)
  $(this.find('.gmail-sent')).prop('checked', true) if Session.equals('FILTER_GMAIL_SENT', true)
  $(this.find('.gcontact')).prop('checked', true) if Session.equals('FILTER_GCONTACT', true)


  $(this.findAll('.summernote')).summernote({
    toolbar: [
      ['style', ['bold', 'italic', 'underline', 'clear']],
      ['fontsize', ['fontsize']],
      ['color', ['color']],
      ['para', ['ul', 'ol', 'paragraph']],
      ['insert', ['link']]
      ['height', ['height']],
    ]
  });

  sharing = Sharings.findOne()
  if sharing?.isLocked
    $(this.find('.email-body2')).siblings().find(".note-editable").prop("contenteditable", false)
    $(this.find('.lock-message')).prop('checked', true)
    $(this.find('.lock-message-label')).text('unlock the message')


validatePassword = (password) ->
  password is 'Chapter37'



Template.compose.events
  'change .lock-message': (e) ->
    if $(e.currentTarget).prop('checked')
      $(e.currentTarget).siblings('.lock-message-label').text('unlock the message')
    else
      $(e.currentTarget).siblings('.lock-message-label').text('lock the message')
    $('.lock-message-password').focus()



  'click .lock-message-button': (e) ->
    isLocked = $(".lock-message").prop('checked')
    password = $(".lock-message-password").val()
    htmlBody = $(".email-body2").code()
    if validatePassword(password) and Meteor.userId()
      sharing = Sharings.findOne({})
      options = {
        $set: 
          htmlBody: htmlBody
          isLocked: isLocked
          lockedByUser: Meteor.userId()
      }
      Sharings.update(sharing._id, options)
    else
      $(".alert-lock-message").removeClass("hidden")
      Meteor.setTimeout ->
        $(".alert-lock-message").addClass("hidden")
      , 2000
      console.log 'Password is wrong.'


Template.email_draft.events
  'click button.draft-send': (e) ->
    subject = $('#email_draft .draft-subject').text()
    body = $('#email_draft .draft-body').html()
    to = []
    $('#email_draft .draft-to p.email').each -> to.push $(this).text()
    console.log subject, body, to
    $('.draft-send').prop('disabled', true)
    sharingBody = $('.email-body2').code()
    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      if err
        console.log err 
      else
        sharing = Sharings.findOne({type: 'email'})
        if sharing
          Sharings.update sharing._id,
            $set:
              subject: subject
              htmlBody: sharingBody
        else
          Sharings.insert
            type: 'email'
            subject: subject
            htmlBody: sharingBody
      console.log 'send mail success'
      $('.draft-send').prop('disabled', false)
      $('.draft-close').trigger('click')


Template.google_api_modal.helpers
  'domain': ->
    Meteor.absoluteUrl()


Template.google_api_modal.events
  'keypress .client-id': (e) ->
    $('.client-secret').focus() if e.which is 13


  'click .google-api-set': (e) ->
    id = $('.client-id').val().trim()
    secret = $('.client-secret').val().trim()
    if id and secret
      console.log id
      console.log secret
      $('.google-api-set').prop('disabled', true)
      Meteor.call 'initGoogleOauth', id, secret, (err) ->
        console.log err if err
        GoogleAccountChecker.checkGoogleApi()