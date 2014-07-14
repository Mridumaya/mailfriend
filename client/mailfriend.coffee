introPagesDone = (page, pageObject) ->
  Meteor.call 'introPagesDone', page, pageObject, (err, res) ->
    if res
      introJs().start()

Template.masterLayout.helpers
  picture: ->
    user = Meteor.user()
    if user and user.profile and user.profile.picture
      return user.profile.picture
    return '/images/default_user.jpg'

  fullname: ->
    return Meteor.user().profile.name

  hasLogin: ->
    !!Meteor.user()

  new_messages: ->
    email = Meteor.user().profile.email
    messages = Messages.find({to: email, new_message: 'yes'}).count()


Template.masterLayout.events
  'click .logout': (e) ->
    e.preventDefault
    Meteor.logout()

    delete Session.keys['GOOGLE_LOGIN']

    if $('div.mobile-menu').hasClass('menu-opened')
      $('div.mobile-menu').removeClass('menu-opened')
      $('#container1').removeClass('menu-is-opened')

    Router.go('home')
    return true

  'click .edit-user-info': (e) ->
    menuitemActive()
    e.preventDefault

    if $('div.mobile-menu').hasClass('menu-opened')
      $('div.mobile-menu').removeClass('menu-opened')
      $('#container1').removeClass('menu-is-opened')

    Router.go "edit_user_info"

  'click .back-to-feature-select': (e) ->
    if $('div.mobile-menu').hasClass('menu-opened')
      $('div.mobile-menu').removeClass('menu-opened')
      $('#container1').removeClass('menu-is-opened')

    Router.go 'feature_select'

  'click .btn-create-campaign': (e) ->
    mixpanel.track("visit new campaign", { });
    delete Session.keys['campaign_id']
    delete Session.keys['searchQ']
    delete Session.keys['prev_searchQ']
    delete Session.keys['contact_list']

    if $('div.mobile-menu').hasClass('menu-opened')
      $('div.mobile-menu').removeClass('menu-opened')
      $('#container1').removeClass('menu-is-opened')

    Router.go "new_campaign"

  'click .btn-view-campaign': (e) ->
    mixpanel.track("visit campaign list", { });

    if $('div.mobile-menu').hasClass('menu-opened')
      $('div.mobile-menu').removeClass('menu-opened')
      $('#container1').removeClass('menu-is-opened')

    Router.go "list_campaign"

  'click .btn-view-messages': (e) ->
    mixpanel.track("visit inbox", { });

    if $('div.mobile-menu').hasClass('menu-opened')
      $('div.mobile-menu').removeClass('menu-opened')
      $('#container1').removeClass('menu-is-opened')

    Router.go "inbox"

  'click #show-mobile-menu': (e) ->
    e.preventDefault()
    $('div.mobile-menu').toggleClass('menu-opened')
    $('#container1').toggleClass('menu-is-opened')

Template.feature_select.rendered = ->
  menuitemActive()
  $('#manual-login-dialog').modal('hide')
  $('#login-dialog').modal('hide')
  $('#register-dialog').modal('hide')
  # $('#help-dialog').modal('hide')
  introPagesDone 'feature_select', {'introPagesDone.feature_select':true}

  console.log Meteor.user()

Template.feature_select.helpers
  name: ->
    Meteor.user().profile.name

  campaign_count: ->
    campaigns = Campaigns.find().fetch()
    count = campaigns.length

  sent_campaign_count: ->
    campaigns = Campaigns.find({sent: 'yes'}).fetch()
    count = campaigns.length

    if count is 1
      count += ' of these was'
    else
      count += ' of these were'

  forwarded_messages: ->
    userId = Meteor.user()._id
    forwarded = Sharings.find({type: 'email', owner_id: userId, sender_id: {$ne: userId}}).fetch()
    count = forwarded.length

  new_messages: ->
    email = Meteor.user().profile.email
    messages = Messages.find({to: email, new_message: 'yes'}).count()


Template.feature_select.events
  'click .btn-create-campaign': (e) ->
    mixpanel.track("visit new campaign", { });
    delete Session.keys['campaign_id']
    menuitemActive($(this).parent())
    Router.go "new_campaign"

  'click .btn-view-campaign': (e) ->
    mixpanel.track("visit campaign list", { });
    menuitemActive($(this).parent())
    Router.go "list_campaign"

  'click .btn-view-messages': (e) ->
    mixpanel.track("visit inbox", { });
    Router.go "inbox"


Template.home.rendered = ->
  mixpanel.track("view home page", { });
  # introJs().start()
  if Session.get 'afterEmailVerified'
    # delete Session.keys['afterEmailVerified']
    apprise(Session.get('successMessage'))
    $('#manual-login-dialog').modal('show')

  setTimeout ->
    if Meteor.user()
      Router.go "feature_select"
  , 500

Template.home.events
  'click .add-google-oauth': (e) ->
    mixpanel.track("logs in with google", { });
    console.log new Date()
    button = $(e.currentTarget)
    $(button).prop('disabled', true)
    Meteor.loginWithGoogle({
      requestPermissions: [
        "https://mail.google.com/", # imap
        "https://www.googleapis.com/auth/userinfo.profile", # profile
        "https://www.googleapis.com/auth/userinfo.email", # email
        "https://www.google.com/m8/feeds/" # contacts
      ]
      requestOfflineToken: true
      forceApprovalPrompt: true
    }, (err) ->
      console.log err
      $(button).prop('disabled', false)
      unless err
        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log 'Calling callback function'
          console.log err if err

          Router.go "list_campaign"
    )

  'click #nav_down': (e) ->
    $('html, body').animate({scrollTop: $('#content').height()}, 800);

clearAllSelection = () ->
  SelectedEmailsHelper.unselectAllEmails()
  oTable = $('#matched-contacts').dataTable()
  list = oTable.fnGetNodes()
  count =
  i = 0
  while i < list.length
    $(list[i++]).removeClass("info").find(".icon i").removeClass "glyphicon glyphicon-ok"

  oTable = $('#unmatched-contacts').dataTable()
  list = oTable.fnGetNodes()
  count =
  i = 0
  while i < list.length
    $(list[i++]).removeClass("info").find(".icon i").removeClass "glyphicon glyphicon-ok"


  receivedMessages: ->
    if @uids
      _.filter @uids, (uid) ->
        today = new Date()
        priorDate = new Date().setDate today.getDate() - 90
        uidDate = new Date uid.date
        return priorDate < uidDate
      .length
    else
      0

  sentMessages: ->
    if @sent_uids
      _.filter @sent_uids, (uid) ->
        today = new Date()
        priorDate = new Date().setDate today.getDate() - 90
        uidDate = new Date uid.date
        return priorDate < uidDate
      .length
    else
      0

  isGContact: ->
    @source is 'gcontact'

  isRelevant: ->
    if Session.get('searchQ')
      (@name.indexOf(Session.get('searchQ')) isnt -1) || _.contains((@searchQ || []), Session.get('searchQ'))

  searchQ: ->
    Session.get('searchQ') || ''


Template.confirm.rendered = ->
  mixpanel.track("visits step 4 page", { });
  introPagesDone 'campaign_send', {'introPagesDone.campaign_send':true}


Template.confirm.helpers
  subject: ->
    Session.get "MAIL_TITLE" || ""

  forwaded_message: ->
    Session.get "ORIG_MESS" || ""

  user_message: ->
    message = Session.get "OWN_MESS" || ""

    message = message.replace(/style="color:rgb\(150, 150, 150\)"/g, '')

  emails: ->
    to = []
    $(Session.get "CONF_DATA").each (index, value) ->
      to.push value
    emails = '<span>' + to.join('</span>, <span>') + '</span>'
    emails

  shareurl: ->
    Meteor.call 'getCampaignSlug', Session.get('campaign_id'), (e, resp) ->
      console.log e if e

      slug = resp[0]
      campaignId = resp[1]
      Session.set('slug' + campaignId, slug)

    slug = Session.get('slug' + Session.get('campaign_id'))

    return Meteor.absoluteUrl "" + Meteor.user()._id + '/' + slug

Template.confirm.events
  'click .confirm-to-contact-list': (e) ->
    mixpanel.track("clicked on back to editing campaign on final step", { })
    delete Session.keys['searchQ']
    delete Session.keys['prev_searchQ']
    delete Session.keys['contact_list']
    Router.go 'new_campaign'

  'click .draft-send': (e) ->
    e.preventDefault()
    slug = $(e.currentTarget).data('shareurl')

    subject = Session.get "MAIL_TITLE"
    body = Session.get("OWN_MESS")
    body = body.replace(/style="color:rgb\(150, 150, 150\)"/g, '')
    body = body + '<br><br>Support this idea by sending it to people who care by clicking on this link:<br>' + slug
    to = Session.get "CONF_DATA"

    $('.draft-send').prop('disabled', true)

    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      campaign_id = Session.get("campaign_id")
      campaign = Campaigns.findOne({_id: campaign_id})

      if err
        console.log err
      else
        # sharing = Sharings.findOne({type: 'email', campaign_id: campaign_id})
        # if sharing
        #   Sharings.update sharing._id,
        #     $set:
        #       subject: subject
        #       htmlBody: body
        #       senderName: Meteor.user()?.profile?.name || ""
        # else

        Sharings.insert
          type: 'email'
          campaign_id: campaign_id
          sender_id: Meteor.user()._id
          owner_id: campaign.user_id
          slug: campaign.slug
          subject: subject
          htmlBody: body
          senderName: Meteor.user()?.profile?.name || ""

        _.each(to,(email) ->
          # message = Messages.findOne({campaign_id: campaign_id, to: email})

          # if message
          #   Messages.update message._id,
          #     $set:
          #       message: body
          #       subject: subject
          #       new_message: 'yes'
          # else
            Messages.insert
              campaign_id: campaign_id
              slug: campaign.slug
              from: Meteor.user()._id
              to: email
              message: body
              subject: subject
              # password: ''
              new_message: 'yes'
              created_at: new Date()
        )

        Meteor.call 'markCampaignSent', Session.get("campaign_id"), (e, campaign_id) ->
          console.log e if e
          $.gritter.add
            title: "Email sent"
            text: "Your campaign email was successfully sent!"

        mixpanel.track("send email", { });

        console.log 'send mail success'

        Session.set("sent_campaign_id", Session.get("campaign_id"))

        Router.go 'list_campaign'


Template.share_via_email.rendered = ->
  menuitemActive()

  $('#share-message').wysihtml5({"image":false, "font-styles": false});

  $("#recipients-tagit").tagit({})

  _.each($('#recipients').val().split(',') || [],(item) ->
    $("#recipients-tagit").tagit("createTag", item)
  )


Template.share_via_email.helpers
  subject: ->
    Meteor.call 'getCampaignSubject', Session.get('campaign_id'), (e, resp) ->
      console.log e if e

      subject = resp[0]
      campaignId = resp[1]
      Session.set('subject' + campaignId, subject)

    subject = Session.get('subject' + Session.get('campaign_id'))

    return subject

  recipients: ->
    Meteor.call 'getCampaignRecipients', Session.get('campaign_id'), (e, resp) ->
      console.log e if e

      recipients = resp[0]
      campaignId = resp[1]
      Session.set('recipients' + campaignId, recipients)

    recipients = Session.get('recipients' + Session.get('campaign_id'))

    return recipients

  shareurl: ->
    return Session.get('shareThisUrl')


Template.share_via_email.events
  'click .draft-send': (e) ->
    e.preventDefault()

    subject = $('#share-subject').val()
    body = $('#share-message').val()
    to = $('#recipients-tagit').tagit("assignedTags")

    # console.log subject, body, to
    $('.draft-send').prop('disabled', true)

    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      campaign_id = Session.get("campaign_id")
      campaign = Campaigns.findOne({_id: campaign_id})

      if err
        console.log err
      else
        # insert into sharings
        Sharings.insert
          type: 'email'
          campaign_id: campaign_id
          sender_id: Meteor.user()._id
          owner_id: campaign.user_id
          slug: campaign.slug
          subject: subject
          htmlBody: body
          senderName: Meteor.user()?.profile?.name || ""

        # insert into messages
        _.each(to,(email) ->
            Messages.insert
              campaign_id: campaign_id
              slug: campaign.slug
              from: Meteor.user()._id
              to: email
              message: body
              subject: subject
              new_message: 'yes'
              created_at: new Date()
        )

        $.gritter.add
          title: "Email sent"
          text: "Your email was successfully sent!"

        mixpanel.track("send email", { });

        console.log 'send mail success'

        $('.draft-send').prop('disabled', false)
        $('.draft-close').trigger('click')


@menuitemActive = (elcl) ->
  list = $('.left_nav ul')
  list.find('li').removeClass('active').find('a').removeClass('active').find('span:first-child').removeClass('active')

  if elcl isnt undefined and elcl.length
    list.find('li.' + elcl).addClass('active').find('a').addClass('active').find('span:first-child').addClass('active')

#Template.compose.helpers
#  webUrl: ->
#    Meteor.absoluteUrl()
#
#  subject: ->
#    Sharings.findOne(type: 'email')?.subject
#
#Template.compose.rendered = ->
#  sharing = Sharings.findOne()
#  if sharing
#    $(this.find('.email-subject')).val(sharing.subject)
#    $(this.find('.email-body2')).html(sharing.htmlBody)
#
#  # $(this.find('.email-subject')).focus() if Meteor.user()
#  $(this.find('.alert-body')).hide()
#  $(this.find('.email-send')).prop('disabled', !Meteor.user())
#  $(this.find('.gmail-received')).prop('checked', true) if Session.equals('FILTER_GMAIL_RECEIVED', true)
#  $(this.find('.gmail-sent')).prop('checked', true) if Session.equals('FILTER_GMAIL_SENT', true)
#  $(this.find('.gcontact')).prop('checked', true) if Session.equals('FILTER_GCONTACT', true)
#
#
#  $(this.findAll('.summernote')).summernote({
#    toolbar: [
#      ['style', ['bold', 'italic', 'underline', 'clear']],
#      ['fontsize', ['fontsize']],
#      ['color', ['color']],
#      ['para', ['ul', 'ol', 'paragraph']],
#      ['insert', ['link']]
#      ['height', ['height']],
#    ]
#  });
#
#  sharing = Sharings.findOne()
#  if sharing?.isLocked
#    $(this.find('.email-body2')).siblings().find(".note-editable").prop("contenteditable", false)
#    $(this.find('.lock-message')).prop('checked', true)
#    $(this.find('.lock-message-label')).text('unlock the message')


validatePassword = (password) ->
  password is 'queens'



#Template.compose.events
#  'change .lock-message': (e) ->
#    if $(e.currentTarget).prop('checked')
#      $(e.currentTarget).siblings('.lock-message-label').text('unlock the message')
#    else
#      $(e.currentTarget).siblings('.lock-message-label').text('lock the message')
#    $('.lock-message-password').focus()
#
#
#
#  'click .lock-message-button': (e) ->
#    isLocked = $(".lock-message").prop('checked')
#    password = $(".lock-message-password").val()
#    htmlBody = $(".email-body2").code()
#    if validatePassword(password) and Meteor.userId()
#      sharing = Sharings.findOne({})
#      options = {
#        $set:
#          htmlBody: htmlBody
#          isLocked: isLocked
#          lockedByUser: Meteor.userId()
#      }
#      Sharings.update(sharing._id, options)
#    else
#      $(".alert-lock-message").removeClass("hidden")
#      Meteor.setTimeout ->
#        $(".alert-lock-message").addClass("hidden")
#      , 2000
#      console.log 'Password is wrong.'
#


clickSendMessages = (toEmails=[])->
  emails = []
  if toEmails.length
    emails = toEmails
  else
    #$('tr.contact.info').each -> emails.push $(this).data('email')
    emails = @SelectedEmailsHelper.selectedEmail().emails

  Session.set("CONF_DATA", emails)
  Session.set("STEP", "confirm")

#Template.email_draft.events
#  'click button.draft-send': (e) ->
#    subject = $('#email_draft .draft-subject').text()
#    body = $('#email_draft .draft-body').html()
#    to = []
#    $('#email_draft .draft-to p.email').each -> to.push $(this).text()
#    console.log subject, body, to
#    $('.draft-send').prop('disabled', true)
#    sharingBody = $('.email-body2').code()
#    Meteor.call 'sendMail', subject, body, to, (err, result) ->
#      if err
#        console.log err
#      else
#        sharing = Sharings.findOne({type: 'email'})
#        if sharing
#          Sharings.update sharing._id,
#            $set:
#              subject: subject
#              htmlBody: sharingBody
#        else
#          Sharings.insert
#            type: 'email'
#            subject: subject
#            htmlBody: sharingBody
#      console.log 'send mail success'
#      $('.draft-send').prop('disabled', false)
#      $('.draft-close').trigger('click')


Template.google_api_dialog.helpers
  'domain': ->
    Meteor.absoluteUrl()


Template.google_api_dialog.events
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
        # $('#google-api-modal').modal('hide');
