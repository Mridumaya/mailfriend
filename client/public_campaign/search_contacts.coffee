Template.public_search_contacts.rendered = ->
  mixpanel.track("visits step 2 page", { });

  # init tagit
  $("#public-tags").tagit({})

  # add predefined tags
  publicTags = $('input.search-query').val().split(' ')
  _.each(publicTags || [],(item) ->
    $("#public-tags").tagit("createTag", item)
  )

Template.public_search_contacts.helpers
  searchQ: ->
    Session.get('searchQ') || ''

Template.public_search_contacts.events
  'click .search-button': (e) ->
    e.preventDefault()
    searchQuery = $("#public-tags").tagit("assignedTags").join(' ')
    
    if searchQuery
      $(e.target).prop('disabled', true)
      Session.set('searchQ', searchQuery)
      # Meteor.setTimeout ->
      #   $(e.target).prop('disabled', false)
      # , 60*1000
      # SearchStatus.insert {session_id: Meteor.default_connection._lastSessionId}
      # searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
      Router.go('publiccontactlist')
      # Session.set('STEP', "public_contact_list")
    else
      apprise('Please add at least one search term!')

  # 'keypress .search-query': (e) ->
  #   $("#sq_error").addClass("hidden")

  'click .searchq-to-welcome': (e) ->
    e.preventDefault()
    Router.go('publicedit')
    # Session.set("STEP", "public_welcome")

# searchContacts = (searchQuery, session_id, cb) ->
  #$("#loading").show()

  #$.blockUI({ message: '<img src="/images/busy.gif" />  Loading...' });
  # Meteor.setTimeout ->
  #   if Meteor.user()
  #     Meteor.call 'searchContacts', searchQuery, session_id, (err) ->
  #       Session.set('searchQ', searchQuery)
  #       #$("#loading").hide()
  #       #console.log 'searchContact Error: ', err if err
  #       #$.unblockUI()
  #       cb()
  #   else
  #     searchContacts(searchQuery)
  # , 500

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

  isSearchRunning: ->
    SearchStatus.find({session_id: Meteor.default_connection._lastSessionId}).count() > 0