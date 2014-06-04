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

Template.list_campaign.helpers
  campaigns: ->
    campaigns = Campaigns.find()

@key_up_delay = 0;
getEnteredTags = () ->
  if (@key_up_delay)
    clearTimeout @key_up_delay

  message = $('#own_message').val()

  @key_up_delay = setTimeout(->
    $("#tags").tagit("assignedTags")
    re = /(?:^|\W)#(\w+)(?!\w)/g
    match
    tags = new Array()

    # clear tags
    $("#tags").tagit("removeAll")

    # add predefined tags 
    searchTags = $('#campaign-tags').val().split(' ')
    _.each(searchTags || [],(item) ->
      $("#tags").tagit("createTag", item)
    )

    while (match = re.exec(message))
      $("#tags").tagit("createTag", match[1]);
      tags.push match[1]

    Session.set("search_tags", tags)
  , 1000)

Template.new_campaign.events
  'click .search-tags': (e) ->
    searchQuery = $("#tags").tagit("assignedTags").join(" ");
    mixpanel.track("search tag", { });
    searchLoader('show');
    searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
      console.log("show list")
      Session.set("contact_list", "yes")
      searchLoader('hide');

    $("#DataTables_Table_0").empty();

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
  'click .delete-campaign': (e)->
      console.log $(e.currentTarget).attr('data-id')
      if (confirm('Are you sure?'))
          Meteor.call 'deleteCampaign', $(e.currentTarget).attr('data-id')

  'click .edit-campaign': (e)->
      Session.set 'campaign_id', $(e.currentTarget).attr('data-id')
      Router.go 'new_campaign'

  'click .btn-create-campaign': (e) ->
      mixpanel.track("visit new campaign", { });
      delete Session.keys['campaign_id']
      Router.go 'new_campaign'

  'click .back-to-feature-select': (e) ->
    Router.go 'feature_select'      

initialize = true
Template.new_campaign.rendered = ->
  menuitemActive('new-campaign')

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
          ,100)

        blur: () ->
          clearInterval interval

    # initialize = false;

  $("#tags").tagit({
    afterTagAdded: (event,ui)->
      Session.set("search_tags", $("#tags").tagit("assignedTags"))
      addedTags = $("#tags").tagit("assignedTags").join(" ")
      Session.set("searchQ", addedTags)
      $('#campaign-tags').val(addedTags)

    afterTagRemoved: (event,ui)->
      Session.set("search_tags", $("#tags").tagit("assignedTags"))
      Session.set("searchQ", $("#tags").tagit("assignedTags").join(" "))
  })

  if Session.get 'campaign_id'
    getEnteredTags()

    # Meteor.defer ->
      # message = $('#own_message').val()
      # getEnteredTags(message)

@initScrollbar = (scrollcontent) ->
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

    if created_hours > 12
      created_hours -= 12

    if created_hours > 11
      ampm = 'pm'
    else
      ampm = 'am'        

    created_time = created_hours + ':' + created.getMinutes() + ampm
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

  destroyInt = 0

  listInt = setInterval(->
    # console.log 'int'
    list1 = $('#list1 td.info_content span.created.raw')
    list2 = $('#list2 td.info_content span.created.raw')

    if list1.length
      displayDate(list1)

      if list1.length > 4
        initScrollbar('#content_1')
        destroyInt++

    if list2.length
      displayDate(list2)   

      if list2.length > 4
        initScrollbar('#content_2')
        destroyInt++

    if destroyInt is 2
      # console.log 'destroy'
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
    if Session.get("campaign_id")
      Meteor.call 'updateCampaign', Session.get("campaign_id"), user._id, $("#subject").val(),  $("#own_message").val(), $("#tags").tagit("assignedTags").join(" "),(e, campaign_id) ->
        console.log e if e
        $.gritter.add
          title: "Notification"
          text: "Campaign updated!"
    else
      Meteor.call 'createCampaign', user._id, $("#subject").val(),  $("#own_message").val(), $("#tags").tagit("assignedTags").join(" "),(e, campaign_id) ->
        console.log e if e
        Session.set("campaign_id", campaign_id)
        $.gritter.add
          title: "Notification"
          text: "Campaign Saved!"

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
