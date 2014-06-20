Template.new_campaign.helpers
  own_message: ->
    return Session.get("OWN_MESS", '')
  
  showContactList: ->
    console.log "enter list"
    Session.equals("contact_list", "yes")
  
  searchTags: ->
    Session.get("search_tags") || []
  
  mail_title: ->
    return Session.get("MAIL_TITLE", '')

  recipients: ->
    campaign_id = Session.get('campaign_id')
    campaign = Campaigns.findOne({_id: campaign_id})

    if campaign
      if campaign.recipients isnt undefined
        return  campaign.recipients
      else
        return ''
    else
      return ''


Template.list_campaign.helpers
  campaigns: ->
    campaigns = Campaigns.find().fetch()
    campaigns = _.sortBy campaigns, (c) -> -c.created_at || 0

  rooturl: ->
    Meteor.absoluteUrl ""


@key_up_delay = 0;
getEnteredTags = () ->
  if (@key_up_delay)
    clearTimeout @key_up_delay

  message = $('#own_message').val()

  @key_up_delay = setTimeout(->
    currentTagsStr = $("#tags").tagit("assignedTags").join(' ')

    searchTags = $('#campaign-tags').val().split(' ')
    searchTagsStr = searchTags.join(' ')

    re = /(?:^|\W)#(\w+)(?!\w)/g
    match
    messageTags = new Array()

    while (match = re.exec(message))
      if searchTagsStr.indexOf(match[1]) is -1
        searchTags.push match[1]

    newTagsStr = searchTags.join(' ') # + ' ' + messageTags.join(' ')
    newTagsStr.trim()

    # console.log currentTagsStr
    # console.log newTagsStr

    if currentTagsStr isnt newTagsStr
      # clear tags
      $("#tags").tagit("removeAll")

      # add predefined tags 
      _.each(searchTags || [],(item) ->
        $("#tags").tagit("createTag", item)
      )

    Session.set("search_tags", tags)
  , 1000)


@refreshDataTable = (table, source) ->
  table = table.DataTable()
  table.clear().draw()

  newrows = []
  selectedrows = []
  rowcount = 0
  if source.length isnt 0
    _.each(source,(item) ->
      row = $(item)

      checked = row.find('td:nth-child(1)').html()
      if checked isnt '<i></i>'
        selectedrows.push(rowcount)

      rowcount++

      newrow =
        checked: row.find('td:nth-child(1)').html()
        name: row.find('td:nth-child(2)').html()
        email: row.find('td:nth-child(3)').html()
        sentMessages: row.find('td:nth-child(4)').html()
        receivedMessages: row.find('td:nth-child(5)').html()
        isGContact: row.find('td:nth-child(6)').html()
        isRelevant: row.find('td:nth-child(7)').html()
      
      newrows.push(newrow)
    )

  if newrows.length
    table.rows.add(newrows).draw()

    if selectedrows.length isnt 0
      settings = table.settings()
      rowsdata = settings[0]['aoData']

      _.each(selectedrows,(item) ->
        rowdata = rowsdata[item]

        $(rowdata.nTr).addClass('info')
      )

    # hide loaders
    searchLoader('hide');
    $('div.loading-contacts').addClass('hidden')


Template.new_campaign.events
  'click .reset-tags': (e) ->
    $('#recipients').tagit('removeAll')
    $('#existing-recipients').text('')

    $('#tags').tagit('removeAll')
    $('#campaign-tags').val('')
    delete Session.keys['searchQ']

    $('#tmp_matched_contacts tr, #tmp_unmatched_contacts tr').remove()
    refreshDataTable($("#matched-contacts-tab table.dataTable"), $('#tmp_matched_contacts tr'))
    refreshDataTable($("#unmatched-contacts-tab table.dataTable"), $('#tmp_unmatched_contacts tr'))

  'click .search-tags': (e) ->
    button = $(e.currentTarget)
    button.data('pressed', 1)
    
    searchQuery = $("#tags").tagit("assignedTags").join(" ");
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

  'click .tagit-close': (e) ->
    addedTags = $("#tags").tagit("assignedTags").join(" ")
    $('#campaign-tags').val(addedTags)

  'click .btn-save-campaign': (e) ->
    console.log "save campaign"
    Session.set("OWN_MESS", $("#own_message").val())
    Session.set("MAIL_TITLE", $("#subject").val())
    SaveCampaign()
    Router.go 'list_campaign'

  'click .back-to-campaign-list': (e) ->
    Router.go 'list_campaign'

  'click .back-to-feature-select': (e) ->
    Router.go 'feature_select'

  'click .mailbox_right': (e) ->
    $('li.tagit-new input').focus()


Template.list_campaign.events
  'click .delete-campaign': (e) ->
      # console.log $(e.currentTarget).data('id')
      apprise('Are you sure to delete this campaign?', {'verify':true}, (r) ->
        if r
          Meteor.call 'deleteCampaign', $(e.currentTarget).data('id')
      )
      # if (confirm('Are you sure?'))

  'click .edit-campaign': (e) ->
      delete Session.keys['searchQ']
      delete Session.keys['prev_searchQ']
      delete Session.keys['contact_list']
      Session.set 'campaign_id', $(e.currentTarget).data('id')
      Router.go 'new_campaign'

  'click .send-campaign': (e) ->
      menuitemActive()

      # get campaign data
      campaign_id = $(e.currentTarget).data('id')
      campaign = Campaigns.findOne({_id: campaign_id})

      if campaign.subject.length is 0
        apprise('Your campaign message has no subject. Would you like to be redirected to the edit page now?', { verify: true }, (r) ->
          if r
            delete Session.keys['searchQ']
            delete Session.keys['prev_searchQ']
            delete Session.keys['contact_list']           
            Session.set('campaign_id', campaign_id)
            Router.go('new_campaign')
        )
        return false

      if campaign.body.length is 0
        apprise('Your campaign has no message body. Would you like to be redirected to the edit page now?', { verify: true }, (r) ->
          if r
            delete Session.keys['searchQ']
            delete Session.keys['prev_searchQ']
            delete Session.keys['contact_list']          
            Session.set('campaign_id', campaign_id)
            Router.go('new_campaign')
        )
        return false

      if campaign.recipients is undefined or campaign.recipients.length is 0
        apprise('Your campaign message has no recipients. Would you like to be redirected to the edit page now?', { verify: true }, (r) ->
          if r
            delete Session.keys['searchQ']
            delete Session.keys['prev_searchQ']
            delete Session.keys['contact_list']
            Session.set('campaign_id', campaign_id)
            Router.go('new_campaign')
        )
        return false

      Session.set('campaign_id', campaign_id)

      Session.set("OWN_MESS", campaign.body)
      Session.set("MAIL_TITLE", campaign.subject)
      Session.set("CONF_DATA", campaign.recipients)

      Router.go("confirm")

  'click .btn-create-campaign': (e) ->
      mixpanel.track("visit new campaign", { });
      delete Session.keys['campaign_id']
      delete Session.keys['searchQ']
      delete Session.keys['prev_searchQ']
      delete Session.keys['contact_list']
      Router.go 'new_campaign'

  'click .back-to-feature-select': (e) ->
    Router.go 'feature_select'      


initialize = true
saveInt = ''
triggerTimeout = 0
Template.new_campaign.rendered = ->
  menuitemActive('new-campaign')

  $('#tags-popover').popover({ 
    trigger: 'hover'
  })

  # save the campaign periodically
  clearInterval saveInt
  saveInt = setInterval(->
    if $('#own_message').length and $('.search-loader').is(':visible') isnt true and $('.modal-dialog').is(':visible') isnt true and $('#gritter-notice-wrapper').length is 0
      SaveCampaign()
  , 17000)   

  # do search when a campaign is opened and there are search tags
  if $('#campaign-tags').val().length
    button = $('a.search-tags')
    pressed = button.data('pressed')

    if pressed is 0    
      setTimeout ->
        # console.log 'search-tags click triggered'
        button.trigger('click')
      , 2000

  # init wisyhtml5 editor
  if (initialize)
    messageLength = 0
    interval = 0

    $("#own_message").wysihtml5
      image: false
      "font-styles": false
      events:
        focus: () ->
          interval = setInterval(->
            tmpLength = $('#own_message').val().length
            if (tmpLength isnt messageLength)
              messageLength = tmpLength
              
              getEnteredTags()
              return
          , 100)

        blur: () ->
          clearInterval interval

    # initialize = false;

  # init tagit
  $("#tags").tagit({
    afterTagAdded: (event,ui) ->
      currentTags = $("#tags").tagit("assignedTags")
      
      Session.set("search_tags", currentTags)
      addedTags = currentTags.join(" ")

      $('#campaign-tags').val(addedTags)

      if triggerTimeout isnt 0
        clearTimeout triggerTimeout

      triggerTimeout = setTimeout ->
        console.log 'trigger the search'
        $('a.search-tags').trigger('click');
      , 1000

    afterTagRemoved: (event,ui) ->
      currentTags = $("#tags").tagit("assignedTags")
      
      Session.set("search_tags", currentTags)
      addedTags = currentTags.join(" ")
      
      # $('#campaign-tags').val(addedTags)

      if triggerTimeout isnt 0
        clearTimeout triggerTimeout

      triggerTimeout = setTimeout ->
        console.log 'trigger the search'
        $('a.search-tags').trigger('click');
      , 1000
  })

  if Session.get 'campaign_id'
    getEnteredTags()

    Meteor.defer ->
      getEnteredTags()


@initScrollbar = (scrollcontent) ->
  console.log scrollcontent
  $(scrollcontent).mCustomScrollbar
    scrollButtons:
      enable: true,
      scrollType: "pixels",
      horizontalScroll: true


@displayDate = (list) ->
  weekdays = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
  months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

  curr_date = new Date()
  curr_monthday = curr_date.getDate()
  curr_day = weekdays[curr_date.getDay()]
  curr_month = months[curr_date.getMonth()]
  curr_year = curr_date.getFullYear()

  # console.log curr_year + ' ' + curr_month + ' ' + curr_day + ' ' + curr_monthday

  _.each(list,(item) ->
    elem = $(item)
    created = new Date(elem.data('created'))

    created_hours = created.getHours()
    created_minutes = created.getMinutes()

    if created_minutes < 10
      created_minutes = '0' + created_minutes

    if created_hours > 11
      ampm = 'pm'
    else
      ampm = 'am'  

    if created_hours > 12
      created_hours -= 12      

    created_time = created_hours + ':' + created_minutes + ampm
    created_monthday = created.getDate()
    created_day = weekdays[created.getDay()]
    created_month = months[created.getMonth()]
    created_year = created.getFullYear()

    # console.log created
    # console.log created_year + ' ' + created_month + ' ' + created_day + ' ' + created_time + ' ' + created_monthday

    formated = created_day + ' ' + created_time

    if curr_year is created_year
      if curr_month is created_month
        if curr_monthday is created_monthday
          formated = 'Today ' + created_time
        else if curr_month - 1 is created_monthday
          formated = 'Yesterday ' + created_time
        else formated += ', ' + created_month + ' ' + created_monthday
      else
        formated += ', ' + created_month + ' ' + created_monthday
    else
      formated += ', ' + created_month + ' ' + created_monthday + ' ' + created_year

    elem.removeClass('raw').text(formated)
  )


Template.list_campaign.rendered = ->
  menuitemActive('campaign-list')

  listInt = setInterval(->
    list1 = $('#list1 td.info_content span.created.raw')

    if list1.length
      displayDate(list1)

      if list1.length > 4
        initScrollbar('#content_1')
        clearInterval listInt

  , 750)


Template.inbox.helpers = ->


Template.inbox.events = ->


Template.inbox.rendered = ->
  menuitemActive('my-inbox')


@searchLoader = (action) ->
  loader = $('#search-loader')
  if action is 'show'
    loader.removeClass('hidden')
  else if action is 'hide'
    loader.addClass('hidden')


@SaveCampaign = ->
  user = Meteor.user()
  if user
    # get campaign message recipients
    recipientsTagit = $("#recipients")
    if recipientsTagit.length
      recipients = recipientsTagit.tagit("assignedTags")
    else
      recipients = ''

    if Session.get("campaign_id")
      Meteor.call 'updateCampaign', Session.get("campaign_id"), user._id, $("#subject").val(), $("#own_message").val(), $("#tags").tagit("assignedTags").join(" "), recipients, (e, campaign_id) ->
        console.log e if e
        $.gritter.add
          title: "Notification"
          text: "Campaign updated!"
    else
      Meteor.call 'createCampaign', user._id, $("#subject").val(), $("#own_message").val(), $("#tags").tagit("assignedTags").join(" "), recipients, (e, campaign_id) ->
        console.log e if e
        Session.set("campaign_id", campaign_id)
        $.gritter.add
          title: "Notification"
          text: "Campaign saved!"

@searchContacts = (searchQuery, session_id, cb) ->
  if Meteor.user()
    SearchStatus.insert {session_id: session_id}
    console.log SearchStatus.findOne()
    Meteor.call 'searchContacts', searchQuery, session_id, (err) ->
      Session.set('searchQ', searchQuery)
      # console.log 'Search Contact err : ' + err
      do cb

      #$("#loading").hide()
      #console.log 'searchContact Error: ', err if err
      #$.unblockUI()

@CampaignController = RouteController.extend
    onBeforeAction:->
        console.log 'Routes Called'
    template: 'edit_campign'
    path: 'campaign/edit/:_id'
    data:
        body: ->
            Campaigns.findOne({_id: this.params._id})
    run: ->
        this.render 'new_campaign'
