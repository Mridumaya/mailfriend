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



Template.searchQ.helpers
  searchQ: ->
    Session.get('searchQ') || ''



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



Template.contact_list.helpers
  matchedContacts: ->
    if Session.get('searchQ')
      selector = {}
      _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
      _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
      _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
      _.extend(selector, {searchQ: Session.get('searchQ')})

      contacts = Contacts.find(selector).fetch()
      contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0

      _.map contacts, (c, i) -> _.extend c, {index: i+1}
    else
      []

  unmatchedContacts: ->
    selector = {}
    _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
    _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
    _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
    _.extend(selector, {searchQ: {$ne: Session.get('searchQ')}}) if Session.get('searchQ')

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
    if Session.get('searchQ')
      (@name.indexOf(Session.get('searchQ')) isnt -1) || _.contains((@searchQ || []), Session.get('searchQ'))


  searchQ: ->
    Session.get('searchQ') || ''



Template.contact_list.events
  'click .gmail-received': (e) ->
    Session.set("FILTER_GMAIL_RECEIVED", $(e.currentTarget).is(":checked"))


  'click .gmail-sent': (e) ->
    Session.set("FILTER_GMAIL_SENT", $(e.currentTarget).is(":checked"))


  'click .gcontact': (e) ->
    Session.set("FILTER_GCONTACT", $(e.currentTarget).is(":checked"))

  'click .add-all-relevant': (e) ->
    selector = $('tr.contact').find('i.relevant-contact').closest('tr.contact').addClass('info')
    selector.find('.icon i').addClass('icon-ok')
    selector.each ->
      SelectedEmailsHelper.selectEmail($(this).data('email'))

  'click tr.contact': (e) ->
    console.log $(e.currentTarget).data("email")
    if $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('icon-ok').hasClass('icon-ok')
      SelectedEmailsHelper.selectEmail($(e.currentTarget).data('email'))
    else
      SelectedEmailsHelper.unselectEmail($(e.currentTarget).data('email'))
    $('.alert-contact').hide()


  'click button.selectAll': (e) ->
    $('.alert-contact').hide()
    selectAll = $(e.currentTarget)
    if $(selectAll).toggleClass('selected').hasClass('selected')
      $(selectAll).text('Unselect All')
      selector = $('tr.contact').addClass('info')
      selector.find('.icon i').addClass('icon-ok')
      selector.each ->
        SelectedEmailsHelper.selectEmail($(this).data('email'))
    else
      $(selectAll).text('Select All')
      selector = $('tr.contact').removeClass('info')
      selector.find('.icon i').removeClass('icon-ok')
      selector.each ->
        SelectedEmailsHelper.unselectEmail($(this).data('email'))

  'click .add-all': (e) ->
    selector = $('tr.contact').addClass('info')
    selector.find('.icon i').addClass('icon-ok')
    selector.each ->
      SelectedEmailsHelper.selectEmail($(this).data('email'))

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



  'click .sendToTop15': (e) ->
    console.log 'sendToTop15'
    $('tr.contact').removeClass('info').find('.icon i').removeClass('icon-ok')
    $('tr.contact').slice(0,15).addClass('info').find('.icon i').addClass('icon-ok')
    clickSendMessages()


  'click .sendToTop30': (e) ->
    console.log 'sendToTop30'
    $('tr.contact').removeClass('info').find('.icon i').removeClass('icon-ok')
    $('tr.contact').slice(0,30).addClass('info').find('.icon i').addClass('icon-ok')
    clickSendMessages()


  'click .sendToAll': (e) ->
    console.log 'sendToAll'
    $('tr.contact').addClass('info').find('.icon i').addClass('icon-ok')
    clickSendMessages()



  'click .sendToHandpicked': (e) ->
    console.log 'sendToHandpicked'
    clickSendMessages()



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
  $(this.findAll("tr.contact")).each ->
    if SelectedEmailsHelper.containEmail($(this).data('email'))
      $(this).addClass('info').find('.icon i').addClass('icon-ok')


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



clickSendMessages = (toEmails=[])->
  subject = $('.email-subject').val().trim() || "Invitation"
  body = $('.email-body').code() + $('.email-body2').code() # $('.email-body').html().trim() 


  return $('.alert-body').show() unless body
  return $('.alert-contact').show() unless $('tr.contact.info').length
  emails = []
  if toEmails.length
    emails = toEmails
  else
    $('tr.contact.info').each -> emails.push $(this).data('email')

  to = _.map emails, (e) -> '<p class="email" style="margin:0 0 0;">' + e + '</p>'
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
        checkGoogleApi()