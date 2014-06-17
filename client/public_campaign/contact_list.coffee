Template.public_contact_list.helpers
  matchedContacts: ->
    console.log 'Matched Contacts'
    if Session.get('searchQ')
      selector = {}

      _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
      _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
      _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
      _.extend(selector, {searchQ: Session.get('searchQ')})
      
      contacts = Contacts.find(selector).fetch()

      button = $('a.search-tags')
      button.data('results', contacts.length)

      if contacts isnt undefined and contacts isnt null and contacts.length isnt 0
        contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0
        _.map contacts, (c, i) -> _.extend c, {index: i+1}
      else
        button.data('destroyContactInt', 1)
        console.log 'no matched contacts'
        []
    else
      []

  unmatchedContacts: ->
    console.log 'Unmatched Contacts'
    if Session.get('searchQ')
      selector = {}

      _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
      _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
      _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
      _.extend(selector, {searchQ: {$ne: Session.get('searchQ')}}) if Session.get('searchQ')

      contacts = Contacts.find(selector).fetch()

      if contacts isnt undefined and contacts isnt null and contacts.length isnt 0
        contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0
        _.map contacts, (c, i) -> _.extend c, {index: i+1}
      else
        []
    else
      []

  columns: ->
    columns = [{
      title: ""
      data: "checked"
      mRender:  ( data, type, row ) ->
        row.checked ?= ""      
    },{
      title: "Name"
      data: "name"
      mRender:  ( data, type, row ) ->
        row.name ?= ""
    },{
      title: "Email"
      data: "email"
      mRender:  ( data, type, row ) ->
        row.email ?= ""    
    },{
      title: "Sent in last<br>90 Days"
      data: "sentMessages"
      mRender:  ( data, type, row ) ->
        row.sentMessages ?= ""
    },{
      title: "Recevied in last<br>90 Days"
      data: "receivedMessages"
      mRender:  ( data, type, row ) ->
        row.receivedMessages ?= ""    
    },{
      title: "On contact<br>List"
      data: "isGContact"
      mRender:  ( data, type, row ) ->
        row.isGContact ?= "" 
    },{
      title: 'Relevant<br>(<span class="relevantQ"></span>)'
      data: "isRelevant"
      mRender:  ( data, type, row ) ->
        row.isRelevant ?= "" 
    }]

  matched_selector: ->
    selector = "matched-contacts"

  unmatched_selector: ->
    selector = "unmatched-contacts"

  timestamp: ->
    timestamp = new Date()

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


Template.public_contact_list.events
  'click .gmail-received': (e) ->
    Session.set("FILTER_GMAIL_RECEIVED", $(e.currentTarget).is(":checked"))

  'click .gmail-sent': (e) ->
    Session.set("FILTER_GMAIL_SENT", $(e.currentTarget).is(":checked"))

  'click .gcontact': (e) ->
    Session.set("FILTER_GCONTACT", $(e.currentTarget).is(":checked"))

  'click button.selectAll': (e) ->
    selectAll = $(e.currentTarget)
    rows = $('table.dataTable:visible tbody tr')
    
    $('.alert-contact').hide()

    if selectAll.hasClass('selected')
      selectAll.removeClass('selected').text('Select All')
      rows.removeClass('info').find('td:nth-child(1)').html('')
      rows.each ->
        SelectedEmailsHelper.unselectEmail($(this).find('td:nth-child(3)').text())

    else
      selectAll.addClass('selected').text('Unselect All')
      rows.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
      rows.each ->
        SelectedEmailsHelper.selectEmail($(this).find('td:nth-child(3)').text())

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



  'click table.dataTable tbody tr': (e) ->
    row = $(e.currentTarget)
    email = row.find('td:nth-child(3)').text()

    row.toggleClass('info')

    if row.hasClass('info')
      row.find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
      addRecipient(row)      
    else
      row.find('td:nth-child(1)').html('')
      removeRecipient(row)      

    $('.alert-contact').hide()

  'click .sendToTop15': (e) ->
    console.log 'sendToTop15'
    rows = $('table.dataTable:visible tbody tr')
    rows15 = $('table.dataTable:visible tbody tr').slice(0,15)

    rows.removeClass('info').find('td:nth-child(1)').html('')
    # clear recipients list
    $("#recipients").tagit("removeAll")

    rows15.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
    # add recipients
    rows15.each ->
      addRecipient($(this))      

  'click .sendToTop30': (e) ->
    console.log 'sendToTop30'
    rows = $('table.dataTable:visible tbody tr')
    rows30 = $('table.dataTable:visible tbody tr').slice(0,30)

    rows.removeClass('info').find('td:nth-child(1)').html('')
    # clear recipients list
    $("#recipients").tagit("removeAll")

    rows30.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
    # add recipients
    rows30.each ->
      addRecipient($(this))      

  'click .sendToAll': (e) ->
    console.log 'sendToAll'
    rows = $('table.dataTable:visible tbody tr')

    rows.removeClass('info').find('td:nth-child(1)').html('')
    # clear recipients list
    $("#recipients").tagit("removeAll")

    rows.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
    # add recipients
    rows.each ->
      addRecipient($(this))      

  'click .add-all-relevant': (e) ->
    console.log 'sendToAllRelevant'
    rows = $('table.dataTable:visible tbody tr')
    relevant = $('table.dataTable:visible tbody').find('i.relevant-contact').closest('tr')

    rows.removeClass('info').find('td:nth-child(1)').html('')
    # clear recipients list
    $("#recipients").tagit("removeAll")

    relevant.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
    # add recipients
    rows.each ->
      addRecipient($(this))

  'click .selectNone': (e) ->
    console.log 'selectNone'
    rows = $('table.dataTable tbody tr')
    # rows = $('table.dataTable:visible tbody tr')
    rows.removeClass('info').find('td:nth-child(1)').html('')

    # clear recipients list
    $("#recipients").tagit("removeAll")



  'click .edit-search-term': (e) ->
    searchQuery = $('#s_term').val().trim()
    if searchQuery
      Session.set('searchQ', searchQuery)

      $("#searchTermModal").modal("hide")

      $('.search-tags').trigger('click')
      # searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
        # console.log "search query changed"

  # 'click .contact-list-to-confirm': (e) ->
  #   subject = $("#subject").val()
  #   message = $("#own_message").val()
  #   recipients = $('table.dataTable tbody tr.info')

  #   if subject.length is 0
  #     apprise('Please enter the subject for your campaign email!')
  #     return false

  #   if message.length is 0
  #     apprise('Please enter your message!')
  #     return false

  #   if recipients.length is 0
  #     apprise('Please select recipients for your campaign email!')
  #     return false

  #   Session.set("OWN_MESS", message)
  #   Session.set("MAIL_TITLE", subject)

  #   user = Meteor.user()
  #   SaveCampaign()
  #   clickSendMessages()
  #   Router.go("confirm")

  'click .contact-list-to-confirm': (e) ->
    recipients = $('table.dataTable tbody tr.info')

    if recipients.length is 0
      apprise('Please select recipients for your campaign email!')
      return false

    clickSendMessages()
    Router.go('publicconfirm')
    # Session.set("STEP", "public_confirm")

  'click .contact-list-to-searchq': (e) ->
    Router.go("publicsearchcontacts")
    # Session.set("STEP", "public_searchq")

  # 'click .back-to-editing': (e) ->
  #   editor = $('#campaign-editor-section')
  #   if editor.length
  #     scroll = editor.offset().top
  #     $('html, body').animate({
  #       scrollTop: scroll
  #     }, 1000)

  # 'click .contact-list-to-searchq': (e) ->
  #   Router.go("new_campaign")
  #   #Session.set("STEP", "searchq")

  'click .multi-select .header': (e) ->
    e.preventDefault()
    $(".multi-select .items").toggle()

  'click .contact-tab': (e) ->
    $('.contact-tab').removeClass('tab-active')
    $(e.target).addClass('tab-active')

  'click .search-tags': (e) ->
    button = $(e.currentTarget)
    button.data('pressed', 1)
    
    searchQuery = Session.get('searchQ')

    # console.log searchQuery

    prev_searchQuery = Session.get("prev_searchQ")

    # do the search if there's a search term and if the current search term is not equal to the previous one
    if searchQuery.length
      mixpanel.track("search tag", { });
      
      # show the loaders
      searchLoader('show');
      $('div.loading-contacts').removeClass('hidden')

      # remove the no results warning
      $('div.no-results').addClass('hidden')

      # switch to matched contacts tab
      $('div.select-contact-group a:first-child').trigger('click')

      console.log 'ezt: ' + searchQuery

      searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
        console.log("show list")
        Session.set("searchQ", searchQuery)
        Session.set("prev_searchQ", searchQuery)
        Session.set("contact_list", "yes")

        button.data('destroyContactInt', 0)

        # check for results in every 0.75 seconds
        contactInt = setInterval(->
          # add tags to datatables header
          $("span.relevantQ").text(searchQuery)

          # if there are matches add them to datatables
          matches = parseInt($('#tmp_matched_contacts tr').length)
          if matches
            # add existing recipients to recipienys list
            recipients_str = $('#existing-recipients').text()

            if recipients_str.length
              recipients = recipients_str.split(',')

              _.each(recipients, (email) ->
                $("#recipients").tagit("createTag", email)

                row = $('#tmp_matched_contacts tr td:contains(' + email + ')').parent()
                if row.length isnt 0
                  row.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
                
                else
                  row = $('#tmp_unmatched_contacts tr td:contains(' + email + ')').parent()
                  if row.length isnt 0
                    row.addClass('info').find('td:nth-child(1)').html('<i class="glyphicon glyphicon-ok"></i>')
              )

            setTimeout ->
              # populate datatables
              refreshDataTable($("#matched-contacts-tab table.dataTable"), $('#tmp_matched_contacts tr'))
              refreshDataTable($("#unmatched-contacts-tab table.dataTable"), $('#tmp_unmatched_contacts tr'))

              button.data('pressed', 0)
            , 2000

            button.data('destroyContactInt', 1)

          # check for results, if there's none, display notification
          results = button.data('results')
          if results is 0
            button.data('destroyContactInt', 1)

            # clear datatables
            @refreshDataTable($("#matched-contacts-tab table.dataTable"), $('#tmp_matched_contacts tr'))
            @refreshDataTable($("#unmatched-contacts-tab table.dataTable"), $('#tmp_unmatched_contacts tr'))

            # hide loaders
            searchLoader('hide');
            $('div.loading-contacts').addClass('hidden')

            # show the no results warning
            $('div.no-results').removeClass('hidden')

          # clear interval
          destroyContactInt = button.data('destroyContactInt')
          if destroyContactInt is 1
            clearInterval contactInt
        
        , 750)

@addRecipient = (row) ->
  name = row.find('td:nth-child(2)').text()
  email = row.find('td:nth-child(3)').text()

  recipient = email
  # if name.length
  #   recipient += ' (' + name + ')'

  $("#recipients").tagit("createTag", recipient)

@removeRecipient = (row) ->
  name = row.find('td:nth-child(2)').text()
  email = row.find('td:nth-child(3)').text()

  recipient = email
  # if name.length
  #   recipient += ' (' + name + ')'

  $("#recipients").tagit("removeTagByLabel", recipient)


loadAllGmails = (isLoadAll) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'loadAllGmails', Meteor.userId(), isLoadAll, (err) ->
        console.log err if err
    else
      loadAllGmails(isLoadAll)
  , 500


Template.public_contact_list.rendered = ->
  mixpanel.track("visits step 3 page", { });

  setTimeout ->
    $('a.search-tags').trigger('click')
  , 2000

  # set some custom stuff in the datatables layout
  $('div.dataTables_filter input').attr('placeholder', "Sort By Pople l've:").after('<button type="submit"><img src="/images/search_button.png" alt="Search"></button>')
  $('div.dataTables_length select').after(' entries')

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

  # recipients list
  $("#recipients").tagit(
    afterTagRemoved: (event,ui) ->
      email = ui.tagLabel
      row = $('table.dataTable tbody tr td:contains(' + email + ')').parent()

      row.removeClass('info').find('td:nth-child(1)').html('')
  )


clickSendMessages = (toEmails=[]) ->
  emails = []
  if toEmails.length
    emails = toEmails
  else
    $('table.dataTable tbody tr.info').each -> emails.push $(this).find('td:nth-child(3)').text()

  Session.set("CONF_DATA", emails)






# Template.public_contact_list.helpers
#   matchedContacts: ->
#     if Session.get('searchQ')
#       selector = {}
#       _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
#       _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
#       _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
#       _.extend(selector, {searchQ: Session.get('searchQ')})

#       contacts = Contacts.find(selector).fetch()
#       contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0
#       _.map contacts, (c, i) -> _.extend c, {index: i+1}
#     else
#       []

#   unmatchedContacts: ->
#     selector = {}
#     _.extend selector, {source: 'gcontact'} if Session.equals('FILTER_GCONTACT', true)
#     _.extend selector, {uids: {$exists: true}} if Session.equals('FILTER_GMAIL_RECEIVED', true)
#     _.extend selector, {sent_uids: {$exists: true}} if Session.equals('FILTER_GMAIL_SENT', true)
#     _.extend(selector, {searchQ: {$ne: Session.get('searchQ')}}) if Session.get('searchQ')

#     contacts = Contacts.find(selector).fetch()
#     contacts = _.sortBy contacts, (c) -> -c.sent_uids?.length || 0

#     _.map contacts, (c, i) -> _.extend c, {index: i+1}

#   receivedMessages: ->
#     #@uids?.length || 0
#     if @uids
#       _.filter @uids, (uid) ->
#         today = new Date()
#         priorDate = new Date().setDate today.getDate() - 90
#         uidDate = new Date uid.date
#         return priorDate < uidDate
#       .length
#     else
#       0

#   sentMessages: ->
#     #@sent_uids?.length || 0
#     if @sent_uids
#       _.filter @sent_uids, (uid) ->
#         today = new Date()
#         priorDate = new Date().setDate today.getDate() - 90
#         uidDate = new Date uid.date
#         return priorDate < uidDate
#       .length
#     else
#       0

#   isGContact: ->
#     @source is 'gcontact'



#   isRelevant: ->
#     if Session.get('searchQ')
#       (@name.indexOf(Session.get('searchQ')) isnt -1) || _.contains((@searchQ || []), Session.get('searchQ'))


#   searchQ: ->
#     Session.get('searchQ') || ''

#   isSearchRunning: ->
#     SearchStatus.find({session_id: Meteor.default_connection._lastSessionId}).count() > 0


# Template.public_contact_list.events
#   'click .gmail-received': (e) ->
#     Session.set("FILTER_GMAIL_RECEIVED", $(e.currentTarget).is(":checked"))

#   'click .gmail-sent': (e) ->
#     Session.set("FILTER_GMAIL_SENT", $(e.currentTarget).is(":checked"))

#   'click .gcontact': (e) ->
#     Session.set("FILTER_GCONTACT", $(e.currentTarget).is(":checked"))

#   'click .add-all-relevant': (e) ->
#     console.log 'Add all relevant'
#     clearAllSelection()
#     oTable = $('#matched-contacts').dataTable()
#     list = oTable.fnGetNodes()
#     count = 
#     i = 0
#     while i < list.length
#       $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
#       SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
#       i++

#   'click .clear-all': (e) ->
#     console.log 'Clear all'
#     clearAllSelection()

#   'click tr.contact': (e) ->
#     console.log $(e.currentTarget).data("email")
#     if $(e.currentTarget).toggleClass('info').find('.icon i').toggleClass('glyphicon glyphicon-ok').hasClass('glyphicon glyphicon-ok')
#       SelectedEmailsHelper.selectEmail($(e.currentTarget).data('email'))
#     else
#       SelectedEmailsHelper.unselectEmail($(e.currentTarget).data('email'))
#     console.log SelectedEmailsHelper.selectedEmail().emails
#     $('.alert-contact').hide()


#   'click button.selectAll': (e) ->
#     $('.alert-contact').hide()
#     selectAll = $(e.currentTarget)
#     if $(selectAll).toggleClass('selected').hasClass('selected')
#       $(selectAll).text('Unselect All')
#       selector = $('tr.contact').addClass('info')
#       selector.find('.icon i').addClass('glyphicon glyphicon-ok')
#       selector.each ->
#         SelectedEmailsHelper.selectEmail($(this).data('email'))
#     else
#       $(selectAll).text('Select All')
#       selector = $('tr.contact').removeClass('info')
#       selector.find('.icon i').removeClass('glyphicon glyphicon-ok')
#       selector.each ->
#         SelectedEmailsHelper.unselectEmail($(this).data('email'))

#   'click .add-all': (e) ->
#     selector = $('tr.contact').addClass('info')
#     selector.find('.icon i').addClass('glyphicon glyphicon-ok')
#     selector.each ->
#       SelectedEmailsHelper.selectEmail($(this).data('email'))

#   'click button.reload': (e) ->
#     btn = $(e.currentTarget)
#     btn.prop('disabled', true)
#     Meteor.call 'loadContacts', Meteor.userId(), ->
#       btn.prop('disabled', false)

#   'change .gmail-contacts': (e) ->
#     isLoadAll = $(e.target).prop('checked')
#     console.log isLoadAll
#     $(e.target).prop('disabled', true)
#     Meteor.setTimeout ->
#       $(e.target).prop('disabled', false)
#     , 10*1000
#     loadAllGmails(isLoadAll)



#   'click .sendToTop15': (e) ->
#     console.log 'sendToTop15'
#     clearAllSelection()
#     oTable = $('#matched-contacts').dataTable()
#     list = oTable.fnGetNodes()
#     count = 
#     i = 0
#     while i < 15
#       $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
#       SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
#       i++


#   'click .sendToTop30': (e) ->
#     console.log 'sendToTop30'
#     clearAllSelection()
#     oTable = $('#matched-contacts').dataTable()
#     list = oTable.fnGetNodes()
#     count = 
#     i = 0
#     while i < 30
#       $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
#       SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
#       i++

#   'click .sendToAll': (e) ->
#     console.log 'sendToAll'
#     oTable = $('#unmatched-contacts').dataTable()
#     list = oTable.fnGetNodes()
#     count = 
#     i = 0
#     while i < list.length
#       $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
#       SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
#       i++

#     oTable = $('#matched-contacts').dataTable()
#     list = oTable.fnGetNodes()
#     count = 
#     i = 0
#     while i < list.length
#       $(list[i]).addClass("info").find(".icon i").addClass "glyphicon glyphicon-ok"
#       SelectedEmailsHelper.selectEmail($(list[i]).data('email'))
#       i++

#   'click .edit-search-term': (e) ->
#     searchQuery = $('#s_term').val().trim()
#     if searchQuery
#       $("#searchTermModal").modal("hide")
#       SearchStatus.insert {session_id: Meteor.default_connection._lastSessionId}
#       searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
#         console.log "search query changed"


#   'click .contact-list-to-confirm': (e) ->
#      clickSendMessages()
#      # Session.set("STEP", "public_confirm")
#      Router.go('publicconfirm')

#   'click .contact-list-to-searchq': (e) ->
#     Session.set("STEP", "public_searchq")

#   'click .multi-select .header': (e) ->
#     e.preventDefault()
#     console.log "test"
#     $(".multi-select .items").toggle()

# loadAllGmails = (isLoadAll) ->
#   Meteor.setTimeout ->
#     if Meteor.user()
#       Meteor.call 'loadAllGmails', Meteor.userId(), isLoadAll, (err) ->
#         console.log err if err
#     else
#       loadAllGmails(isLoadAll)
#   , 500


# clickSendMessages = (toEmails=[])->
#   emails = []
#   if toEmails.length
#     emails = toEmails
#   else
#     #$('tr.contact.info').each -> emails.push $(this).data('email')
#     emails = @SelectedEmailsHelper.selectedEmail().emails
#   Session.set("CONF_DATA", emails)

# Template.public_contact_list.rendered = ->
#   mixpanel.track("visits step 3 page", { });
#   $(this.find('.alert-contact')).hide()
#   $(this.find('button.selectAll')).prop('disabled', !Meteor.user())
#   if Meteor.user()?.profile?.isLoadAll
#     $(this.find('.chosen-select option[value="gmail-contacts"]')).prop('selected', true)

#   $(this.findAll("tr.contact")).each ->
#     if SelectedEmailsHelper.containEmail($(this).data('email'))
#       $(this).addClass('info').find('.icon i').addClass('glyphicon glyphicon-ok')

#   $(this.find('.chosen-select option[value="gmail-received"]')).prop('selected', true) if Session.equals('FILTER_GMAIL_RECEIVED', true)
#   $(this.find('.chosen-select option[value="gmail-sent"]')).prop('selected', true) if Session.equals('FILTER_GMAIL_SENT', true)
#   $(this.find('.chosen-select option[value="gcontact"]')).prop('selected', true) if Session.equals('FILTER_GCONTACT', true)

#   $(".chosen-select").chosen().change ->
#     Session.set('FILTER_GMAIL_RECEIVED', false)
#     Session.set('FILTER_GMAIL_SENT', false)
#     Session.set('FILTER_GCONTACT', false)
#     values = $(this).val()
#     gmail_contacts = _.findWhere(values,"gmail-contacts")
#     if gmail_contacts != undefined
#       loadAllGmails(true)
#     else
#       loadAllGmails(false)

#     for i of values
#       Session.set('FILTER_GMAIL_RECEIVED', true) if values[i] == "gmail-received"
#       Session.set('FILTER_GMAIL_SENT', true) if values[i] == "gmail-sent"
#       Session.set('FILTER_GCONTACT', true) if values[i] == "gcontact"


#   $("#matched-contacts, #unmatched-contacts").dataTable({
#     "sDom": "<'row-fluid'l<'span6'>r>t<'row-fluid'<'span4'><'span8'p>>",
#     "sPaginationType": "bootstrap",
#     "iDisplayLength": 50,
#     "aLengthMenu": [[50, 100, 200, 500, 1000, -1], [50, 100, 200, 500, 1000, "All"]]
#     "aoColumns": [
#       { sWidth: '6%' },
#       { sWidth: '9%' },
#       { sWidth: '14%' },
#       { sWidth: '24%' },
#       { sWidth: '24%' },
#       { sWidth: '14%' },
#       { sWidth: '14%' }]

#   });