Template.layout.helpers
  hasLogin: ->
    !!Meteor.user()
  stepIsWelcome: ->
    Session.equals('STEP', "welcome")
  stepIsSearchQ: ->
    Session.equals('STEP', "searchq")
  stepIsContactList: ->
    Session.equals('STEP', "contact_list")
  stepIsConfirm: ->
    Session.equals('STEP', "confirm")
  picture: ->
    user = Meteor.user()
    if user and user.profile and user.profile.picture
      user.profile.picture
    else
      'images/default_user.jpg'


Template.layout.events
  'click .logout': (e) ->
    e.preventDefault
    Meteor.logout()
    return true

initialize = true

Template.welcome.rendered = ->
  mixpanel.track("visits step 1 page", { });
  if(initialize)
    $('#own_message').wysihtml5({"image":false, "font-styles": false});
    initialize = false;

Template.welcome.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name.split(" ")[0]
    else
      ''
  own_message: ->
    if Session.get("OWN_MESS") is 'undefined'
      Session.set "OWN_MESS", ""
    Session.get "OWN_MESS"

  mail_title: ->
    if Session.get("MAIL_TITLE") is 'undefined'
      Session.set "MAIL_TITLE", Sharings.findOne(type: 'email')?.subject || ""    
    Session.get "MAIL_TITLE"

  orig_message: ->
    if Session.get("ORIG_MESS") is `undefined`
      Session.set "ORIG_MESS", Messages.findOne()?.message || ""
    Session.get "ORIG_MESS"

  sender: ->
    Sharings.findOne(type: 'email')?.senderName || "Someone"

Template.welcome.events
  'click .original-message': (e) ->
    div = $(e.currentTarget)
    if($(div).attr("contenteditable"))
      return true;
    $("#defMessageModal").modal("show")

  'click .msg-password': (e) ->
    console.log "test"
    password = $("#password").val()
    if validatePassword(password)
      message = $("#original_message").html()
      $("#original_message").remove()
      $('#original-message-holder').html '<textarea id="original_message">' + message + '</textarea>'
      $('#original_message').wysihtml5({"image":false, "font-styles": false});
      $("#defMessageModal").modal("hide")

  'click .welcome-to-searchq': (e) ->
    Session.set "ORIG_MESS", $("#original_message").val() || $("#original_message").html()
    Session.set "OWN_MESS", $("#own_message").val() 
    Session.set "MAIL_TITLE", $("#subject").val() 
    Session.set "STEP", "searchq" 

Template.login.rendered = ->
  mixpanel.track("view front page", { });

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
          Session.set("STEP", "welcome")
    )


Template.searchQ.rendered = ->
  mixpanel.track("visits step 2 page", { });

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
        Session.set('STEP', "contact_list")
    else
      $("#sq_error").toggleClass("hidden")

  'keypress .search-query': (e) ->
     $("#sq_error").addClass("hidden")

  'click .searchq-to-welcome': (e) ->
     Session.set("STEP", "welcome")

searchContacts = (searchQuery, cb) ->
  #$("#loading").show()

  $.blockUI({ message: '<img src="/images/busy.gif" />  Loading...' });
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'searchContacts', searchQuery, (err) ->
        Session.set('searchQ', searchQuery)
        #$("#loading").hide()

        #console.log 'searchContact Error: ', err if err
        $.unblockUI()
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
    #@uids?.length || 0
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
    #@sent_uids?.length || 0
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



Template.contact_list.events
  'click .gmail-received': (e) ->
    Session.set("FILTER_GMAIL_RECEIVED", $(e.currentTarget).is(":checked"))


  'click .gmail-sent': (e) ->
    Session.set("FILTER_GMAIL_SENT", $(e.currentTarget).is(":checked"))


  'click .gcontact': (e) ->
    Session.set("FILTER_GCONTACT", $(e.currentTarget).is(":checked"))

  'click .add-all-relevant': (e) ->
    selector = $('tr.contact').find('i.relevant-contact').closest('tr.contact').addClass('info')
    selector.find('.icon i').addClass('glyphicon glyphicon-ok')
    selector.each ->
      SelectedEmailsHelper.selectEmail($(this).data('email'))

  'click .clear-all': (e) ->
    selector = $('tr.contact').removeClass('info')
    selector.find('.icon i').removeClass('glyphicon glyphicon-ok')

  'click tr.contact': (e) ->
    console.log $(e.currentTarget).data("email")
    if $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('glyphicon glyphicon-ok').hasClass('glyphicon glyphicon-ok')
      SelectedEmailsHelper.selectEmail($(e.currentTarget).data('email'))
    else
      SelectedEmailsHelper.unselectEmail($(e.currentTarget).data('email'))
    console.log SelectedEmailsHelper.selectedEmail().emails
    $('.alert-contact').hide()


  'click button.selectAll': (e) ->
    $('.alert-contact').hide()
    selectAll = $(e.currentTarget)
    if $(selectAll).toggleClass('selected').hasClass('selected')
      $(selectAll).text('Unselect All')
      selector = $('tr.contact').addClass('info')
      selector.find('.icon i').addClass('glyphicon glyphicon-ok')
      selector.each ->
        SelectedEmailsHelper.selectEmail($(this).data('email'))
    else
      $(selectAll).text('Select All')
      selector = $('tr.contact').removeClass('info')
      selector.find('.icon i').removeClass('glyphicon glyphicon-ok')
      selector.each ->
        SelectedEmailsHelper.unselectEmail($(this).data('email'))

  'click .add-all': (e) ->
    selector = $('tr.contact').addClass('info')
    selector.find('.icon i').addClass('glyphicon glyphicon-ok')
    selector.each ->
      SelectedEmailsHelper.selectEmail($(this).data('email'))

  'click button.reload': (e) ->
    btn = $(e.currentTarget)
    btn.prop('disabled', true)
    Meteor.call 'loadContacts', Meteor.userId(), ->
      btn.prop('disabled', false)

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
    $('tr.contact').removeClass('info').find('.icon i').removeClass('glyphicon glyphicon-ok')
    $('tr.contact').slice(0,15).addClass('info').find('.icon i').addClass('glyphicon glyphicon-ok')
    #clickSendMessages()


  'click .sendToTop30': (e) ->
    console.log 'sendToTop30'
    $('tr.contact').removeClass('info').find('.icon i').removeClass('glyphicon glyphicon-ok')
    $('tr.contact').slice(0,30).addClass('info').find('.icon i').addClass('glyphicon glyphicon-ok')
    #clickSendMessages()


  'click .sendToAll': (e) ->
    console.log 'sendToAll'
    oTable = $('#unmatched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < list.length
      $(list[i++]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"

    oTable = $('#matched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < list.length
      $(list[i++]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"

  'click .edit-search-term': (e) ->
    searchQuery = $('#s_term').val().trim()
    if searchQuery
      $("#searchTermModal").modal("hide")
      searchContacts searchQuery, ->
        console.log "search query changed"


  'click .contact-list-to-confirm': (e) ->
     clickSendMessages()
     Session.set("STEP", "confirm")

  'click .contact-list-to-searchq': (e) ->
    Session.set("STEP", "searchq")

  'click .multi-select .header': (e) ->
    e.preventDefault()
    console.log "test"
    $(".multi-select .items").toggle()

loadAllGmails = (isLoadAll) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'loadAllGmails', Meteor.userId(), isLoadAll, (err) ->
        console.log err if err
    else
      loadAllGmails(isLoadAll)
  , 500



Template.contact_list.rendered = ->
  mixpanel.track("visits step 3 page", { });
  $(this.find('.alert-contact')).hide()
  $(this.find('button.selectAll')).prop('disabled', !Meteor.user())
  if Meteor.user()?.profile?.isLoadAll
    $(this.find('.chosen-select option[value="gmail-contacts"]')).prop('selected', true)

  $(this.findAll("tr.contact")).each ->
    if SelectedEmailsHelper.containEmail($(this).data('email'))
      $(this).addClass('info').find('.icon i').addClass('glyphicon glyphicon-ok')

  $(this.find('.chosen-select option[value="gmail-received"]')).prop('selected', true) if Session.equals('FILTER_GMAIL_RECEIVED', true)
  $(this.find('.chosen-select option[value="gmail-sent"]')).prop('selected', true) if Session.equals('FILTER_GMAIL_SENT', true)
  $(this.find('.chosen-select option[value="gcontact"]')).prop('selected', true) if Session.equals('FILTER_GCONTACT', true)

  $(".chosen-select").chosen().change ->
    Session.set('FILTER_GMAIL_RECEIVED', false)
    Session.set('FILTER_GMAIL_SENT', false)
    Session.set('FILTER_GCONTACT', false)
    values = $(this).val()
    gmail_contacts = _.findWhere(values,"gmail-contacts")
    if gmail_contacts != undefined
      loadAllGmails(true)
    else
      loadAllGmails(false)

    for i of values
      Session.set('FILTER_GMAIL_RECEIVED', true) if values[i] == "gmail-received"
      Session.set('FILTER_GMAIL_SENT', true) if values[i] == "gmail-sent"
      Session.set('FILTER_GCONTACT', true) if values[i] == "gcontact"


  $("#matched-contacts, #unmatched-contacts").dataTable({
    "sDom": "<'row-fluid'l<'span6'>r>t<'row-fluid'<'span4'><'span8'p>>",
    "sPaginationType": "bootstrap",
    "iDisplayLength": 50,
    "aLengthMenu": [[50, 100, 200, 500, 1000, -1], [50, 100, 200, 500, 1000, "All"]]
    "aoColumns": [
      { sWidth: '6%' },
      { sWidth: '9%' },
      { sWidth: '14%' },
      { sWidth: '24%' },
      { sWidth: '24%' },
      { sWidth: '14%' },
      { sWidth: '14%' }]

  });
  

Template.confirm.rendered = ->
  mixpanel.track("visits step 4 page", { });

Template.confirm.helpers 
  subject: ->
    Session.get "MAIL_TITLE" || ""
  forwaded_message: ->
    Session.get "ORIG_MESS" || ""
  user_message: ->
    Session.get "OWN_MESS" || ""
  emails: ->
    to = []
    $(Session.get "CONF_DATA").each (index, value) -> 
      to.push {'email': value}
    to

Template.confirm.events
  'click .confirm-to-contact-list': (e) ->
    mixpanel.track("click on cancel/back button", { });
    Session.set("STEP", "contact_list")
  'click #facebook': (e) ->
    window.open('https://www.facebook.com/sharer/sharer.php?u=http://mailfriend.meteor.com/', 'facebook-share-dialog', 'width=626,height=436');
  'click #twitter': (e) ->
    window.open("http://twitter.com/share?text=" + encodeURIComponent("Check this cool pictures application http://mailfriend.meteor.com/"), 'twitter', "width=575, height=400");
  'click #google': (e) ->
    window.open('https://plus.google.com/share?url=http://mailfriend.meteor.com/', '', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=600,width=600');
  'click #linkedin': (e) ->
    window.open("http://www.linkedin.com/shareArticle?mini=true&url=http://mailfriend.meteor.com/", '', "width=620, height=432");

  'click button.draft-send': (e) ->
    subject = Session.get "MAIL_TITLE"
    body = Session.get("OWN_MESS") + "<br><b>Forwarded Message</b><br>" + Session.get "ORIG_MESS"
    to = Session.get "CONF_DATA"

    console.log subject, body, to
    $('.draft-send').prop('disabled', true)

    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      if err
        console.log err
      else
        sharing = Sharings.findOne({type: 'email'})
        message = Messages.findOne()
        if sharing
          Sharings.update sharing._id,
            $set:
              subject: subject
              htmlBody: body
              senderName: Meteor.user()?.profile?.name || ""
        else
          Sharings.insert
            type: 'email'
            subject: subject
            htmlBody: body
            senderName: Meteor.user()?.profile?.name || ""

        if message
          Messages.update message._id,
            $set:
              message: Session.get("ORIG_MESS")
        else
          Messages.insert
            message: Session.get("ORIG_MESS")
            password: 'queens'
            created_at: new Date()

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
  password is 'queens'



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
  emails = []
  if toEmails.length
    emails = toEmails
  else
    #$('tr.contact.info').each -> emails.push $(this).data('email')
    emails = @SelectedEmailsHelper.selectedEmail().emails

  Session.set("CONF_DATA", emails)
  Session.set("STEP", "confirm")

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