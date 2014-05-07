Template.contact_list.helpers
  matchedContacts: ->
    console.log 'Matched Contacts'
    if Session.get('searchQ')
      selector = {}
      _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
      _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
      _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
      _.extend(selector, {searchQ: Session.get('searchQ')})
      contacts = Contacts.find(selector).fetch()

      if contacts isnt undefined and contacts isnt null
        contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0
        _.map contacts, (c, i) -> _.extend c, {index: i+1}
      else
        []
    else
      []

  unmatchedContacts: ->
    console.log 'Unmatched Contacts'
    selector = {}
    _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
    _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
    _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
    _.extend(selector, {searchQ: {$ne: Session.get('searchQ')}}) if Session.get('searchQ')

    contacts = Contacts.find(selector).fetch()

    if contacts isnt undefined and contacts isnt null
      contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0
      _.map contacts, (c, i) -> _.extend c, {index: i+1}
    else
      []

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

  isSearchRunning: ->
    SearchStatus.find({session_id: Meteor.default_connection._lastSessionId}).count() > 0

  isSearchRunning1: ->
    console.log 'Calling isSearchRunning'
    searchStatus = SearchStatus.find({session_id: Meteor.default_connection._lastSessionId})
    if searchStatus isnt null
      searchStatus.count() > 0
    else
      false


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

  'click tr.contact': (e) ->
    console.log $(e.currentTarget).data("email")
    if $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('glyphicon glyphicon-ok').hasClass('glyphicon glyphicon-ok')
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

  'click .sendToTop30': (e) ->
    console.log 'sendToTop30'
    $('tr.contact').removeClass('info').find('.icon i').removeClass('glyphicon glyphicon-ok')
    $('tr.contact').slice(0,30).addClass('info').find('.icon i').addClass('glyphicon glyphicon-ok')

  'click .sendToAll': (e) ->
    console.log 'sendToAll'
    $('tr.contact').addClass('info').find('.icon i').addClass('glyphicon glyphicon-ok')

  'click .edit-search-term': (e) ->
    searchQuery = $('#s_term').val().trim()
    if searchQuery
      searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
        console.log "search query changed"
        $("#searchTermModal").modal("hide")

  'click .contact-list-to-confirm': (e) ->
    Session.set("OWN_MESS", $("#own_message").val())
    Session.set("MAIL_TITLE", $("#subject").val())
    user = Meteor.user()
    SaveCampaign()
    clickSendMessages()
    Router.go("confirm")

  'click .contact-list-to-searchq': (e) ->
    Router.go("new_campaign")
    #Session.set("STEP", "searchq")

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


  $("#contacts").dataTable({
    "sDom": "<'row-fluid'l<'span6'>r>t<'row-fluid'<'span4'><'span8'p>>",
    "sPaginationType": "bootstrap",
    "iDisplayLength": 25,
    "aoColumns": [
      { sWidth: '10%' },
      { sWidth: '15%' },
      { sWidth: '25%' },
      { sWidth: '25%' },
      { sWidth: '15%' },
      { sWidth: '15%' }]
  });


clickSendMessages = (toEmails=[])->
  emails = []
  if toEmails.length
    emails = toEmails
  else
    $('tr.contact.info').each -> emails.push $(this).data('email')

  Session.set("CONF_DATA", emails)
