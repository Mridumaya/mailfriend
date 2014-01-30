Template.invite_friends.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name
    else
      ''
  hasLogin: ->
    !!Meteor.user()

Template.invite_friends.events
  'click .logout': (e) ->
    Meteor.logout()
  'click .add-google-oauth': (e) ->
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
    )

Template.contact_list.helpers
  contacts: ->
    contacts = Contacts.find().fetch()
    contacts = _.sortBy contacts, (c) -> -c.uids.length
    _.map contacts, (c, i) -> _.extend c, {index: i+1}
  messages: ->
    @uids.length

Template.contact_list.events
  'click tr.contact': (e) ->
    $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('icon-ok')
    $('.alert-contact').hide()

  'click button.selectAll': (e) ->
    $('.alert-contact').hide()
    selectAll = $(e.currentTarget)
    if $(selectAll).toggleClass('selected').hasClass('selected')
      $(selectAll).text('Unselect All')
      $('tr.contact').addClass('info').find('.icon i').addClass('icon-ok')
    else
      $(selectAll).text('Select All')
      $('tr.contact').removeClass('info').find('.icon i').removeClass('icon-ok')

Template.contact_list.rendered = ->
  $(this.find('.alert-contact')).hide()

Template.compose.rendered = ->
  $(this.find('.email-subject')).focus() if Meteor.user()
  $(this.find('.alert-body')).hide()

Template.compose.events
  'keypress .email-subject': (e) ->
    $('.email-body').focus() if e.which is 13
  'focus .email-body': (e) ->
    $('.alert-body').hide()
  'keypress .email-body': (e) ->
    $('.email-send').focus() if e.which is 13
  'click .email-send': (e) ->
    subject = $('.email-subject').val().trim() || "Invitation"
    body = $('.email-body').val().trim()

    return $('.alert-body').show() unless body
    return $('.alert-contact').show() unless $('tr.contact.info').length
    emails = []
    $('tr.contact.info').each -> emails.push $(this).data('email')
    to = _.map emails, (e) -> '<p class="email" style="margin:0 0 0;">' + e + '</p>'

    # console.log subject
    # console.log body
    # console.log to
    $('#email_draft .draft-subject').text(subject)
    $('#email_draft .draft-body').html(body + "<p><a href=\"#{Meteor.absoluteUrl()}\">Tell your friends</a></p>")
    $('#email_draft .draft-to').html(to.join(''))
    $('#email_draft').modal()

Template.email_draft.events
  'click button.draft-send': (e) ->
    subject = $('#email_draft .draft-subject').text()
    body = $('#email_draft .draft-body').text()
    to = []
    $('#email_draft .draft-to p.email').each -> to.push $(this).text()
    console.log subject, body, to
    $('.draft-send').prop('disabled', true)
    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      console.log err if err
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
        $('.google-api-set').prop('disabled', false)
        $('#google-api-modal').modal 'hide'

Template.layout.rendered = ->
  if !Accounts.loginServiceConfiguration.findOne({service: 'google'})
    $('#google-api-modal').modal(backdrop: 'static', keyboard: false)
    $('#google-api-modal').find('.google-id').focus()