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


  'click .search-button': (e) ->
    searchQuery = $('.search-query').val().trim()
    if searchQuery
      $(e.target).prop('disabled', true)
      Meteor.setTimeout ->
        $(e.target).prop('disabled', false)
      , 60*1000
      searchContacts(searchQuery)



searchContacts = (searchQuery) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'searchContacts', searchQuery, (err) ->
        Session.set('searchQ', searchQuery)
        console.log 'searchContact Error: ', err if err
    else
      searchContacts(searchQuery)
  , 500

Template.contact_list.helpers
  contacts: ->
    selector = {}
    _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
    _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
    _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
    contacts = Contacts.find(selector).fetch()
    contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0
    _.map contacts, (c, i) -> _.extend c, {index: i+1}


  receivedMessages: ->
    @uids?.length || 0


  sentMessages: ->
    @sent_uids?.length || 0


  isGContact: ->
    @source is 'gcontact'

  isRelevant: ->
    # @searchQ?.length > 0
    _.contains @searchQ || [], Session.get('searchQ') if Session.get('searchQ')

Template.contact_list.events
  'click .gmail-received': (e) ->
    Session.set("FILTER_GMAIL_RECEIVED", $(e.currentTarget).is(":checked"))


  'click .gmail-sent': (e) ->
    Session.set("FILTER_GMAIL_SENT", $(e.currentTarget).is(":checked"))


  'click .gcontact': (e) ->
    Session.set("FILTER_GCONTACT", $(e.currentTarget).is(":checked"))

  'click .add-all-relevant': (e) ->
    $('tr.contact').find('i.relevant-contact').closest('tr.contact').addClass('info').find('.icon i').addClass('icon-ok')

  'click tr.contact': (e) ->
    $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('icon-ok')
    $('.alert-contact').hide()


  'click button.selectAll, ': (e) ->
    $('.alert-contact').hide()
    selectAll = $(e.currentTarget)
    if $(selectAll).toggleClass('selected').hasClass('selected')
      $(selectAll).text('Unselect All')
      $('tr.contact').addClass('info').find('.icon i').addClass('icon-ok')
    else
      $(selectAll).text('Select All')
      $('tr.contact').removeClass('info').find('.icon i').removeClass('icon-ok')

  'click .add-all': (e) ->
    $('tr.contact').addClass('info').find('.icon i').addClass('icon-ok')

  'click button.reload': (e) ->
    $(e.currentTarget).prop('disabled', true)
    Meteor.call 'loadContacts', Meteor.userId()

  'change .gmail-contacts': (e) ->
    isLoadAll = $(e.target).prop('checked')
    console.log isLoadAll
    $(e.target).prop('disabled', true)
    Meteor.setTimeout ->
      $(e.target).prop('disabled', false)
    , 10*1000
    loadAllGmails(isLoadAll)

loadAllGmails = (isLoadAll) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'loadAllGmails', Meteor.userId(), isLoadAll, (err) ->
        console.log err if err
    else
      loadAllGmails(isLoadAll)
  , 500


Template.contact_list.rendered = ->
  $(this.find('.alert-contact')).hide()
  $(this.find('button.selectAll')).prop('disabled', !Meteor.user())
  if Meteor.user()?.profile?.isLoadAll
    $(this.find('.gmail-contacts')).prop('checked', true)


Template.compose.helpers
  webUrl: ->
    Meteor.absoluteUrl()


  subject: ->
    Sharings.findOne(type: 'email')?.subject



Template.compose.rendered = ->
  sharing = Sharings.findOne()
  if sharing
    $(this.find('.email-subject')).val(sharing.subject)
    $(this.find('.email-body')).html(sharing.htmlBody)

  $(this.find('.email-subject')).focus() if Meteor.user()
  $(this.find('.alert-body')).hide()
  $(this.find('.email-send')).prop('disabled', !Meteor.user())
  $(this.find('.gmail-received')).prop('checked', true) if Session.equals('FILTER_GMAIL_RECEIVED', true)
  $(this.find('.gmail-sent')).prop('checked', true) if Session.equals('FILTER_GMAIL_SENT', true)
  $(this.find('.gcontact')).prop('checked', true) if Session.equals('FILTER_GCONTACT', true)



Template.compose.events
  'keypress .email-subject': (e) ->
    $('.email-body').focus() if e.which is 13


  'focus .email-body': (e) ->
    $('.alert-body').hide()


  'keypress .email-body': (e) ->
    if e.which is 13
      $('.email-send').focus()
    else
      $('.email-send').prop('disabled', false)


  'click .email-send': (e) ->
    subject = $('.email-subject').val().trim() || "Invitation"
    body = $('.email-body').html().trim()

    return $('.alert-body').show() unless body
    return $('.alert-contact').show() unless $('tr.contact.info').length
    emails = []
    $('tr.contact.info').each -> emails.push $(this).data('email')
    to = _.map emails, (e) -> '<p class="email" style="margin:0 0 0;">' + e + '</p>'

    # console.log subject
    # console.log body
    # console.log to
    $('#email_draft .draft-subject').text(subject)
    $('#email_draft .draft-body').html(body)
    $('#email_draft .draft-to').html(to.join(''))
    $('#email_draft').modal()



Template.email_draft.events
  'click button.draft-send': (e) ->
    subject = $('#email_draft .draft-subject').text()
    body = $('#email_draft .draft-body').html()
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
        checkGoogleApi()