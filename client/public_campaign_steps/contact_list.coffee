Template.public_contact_list.helpers
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

  isSearchRunning: ->
    SearchStatus.find({session_id: Meteor.default_connection._lastSessionId}).count() > 0


Template.public_contact_list.events
  'click .gmail-received': (e) ->
    Session.set("FILTER_GMAIL_RECEIVED", $(e.currentTarget).is(":checked"))

  'click .gmail-sent': (e) ->
    Session.set("FILTER_GMAIL_SENT", $(e.currentTarget).is(":checked"))

  'click .gcontact': (e) ->
    Session.set("FILTER_GCONTACT", $(e.currentTarget).is(":checked"))

  'click .add-all-relevant': (e) ->
    console.log 'Add all relevant'
    clearAllSelection()
    oTable = $('#matched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < list.length
      $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
      SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
      i++

  'click .clear-all': (e) ->
    console.log 'Clear all'
    clearAllSelection()

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
    clearAllSelection()
    oTable = $('#matched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < 15
      $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
      SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
      i++


  'click .sendToTop30': (e) ->
    console.log 'sendToTop30'
    clearAllSelection()
    oTable = $('#matched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < 30
      $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
      SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
      i++

  'click .sendToAll': (e) ->
    console.log 'sendToAll'
    oTable = $('#unmatched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < list.length
      $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
      SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
      i++

    oTable = $('#matched-contacts').dataTable()
    list = oTable.fnGetNodes()
    count = 
    i = 0
    while i < list.length
      $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
      SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
      i++

  'click .edit-search-term': (e) ->
    searchQuery = $('#s_term').val().trim()
    if searchQuery
      $("#searchTermModal").modal("hide")
      SearchStatus.insert {session_id: Meteor.default_connection._lastSessionId}
      searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
        console.log "search query changed"


  'click .contact-list-to-confirm': (e) ->
     clickSendMessages()
     Session.set("STEP", "public_confirm")

  'click .contact-list-to-searchq': (e) ->
    Session.set("STEP", "public_searchq")

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


clickSendMessages = (toEmails=[])->
  emails = []
  if toEmails.length
    emails = toEmails
  else
    #$('tr.contact.info').each -> emails.push $(this).data('email')
    emails = @SelectedEmailsHelper.selectedEmail().emails
  Session.set("CONF_DATA", emails)

Template.public_contact_list.rendered = ->
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