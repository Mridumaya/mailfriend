introPagesDone = (page, pageObject) ->
  Meteor.call 'introPagesDone', page, pageObject, (err, res) ->
    if res
      switch page
        when 'new_campaign_second' then introJs().refresh() introJs().goToStep(4).start()
        when 'share_campaign' then introJs('#container1').start()
        else introJs().start()

# new campaign stuff ----------------------------------------------------------------------------------------------------------------------
googleOauthOpen = (ev, search) ->
  ev.preventDefault()
  mixpanel.track("logs in", { });
  console.log Session.get 'loggedInWithGoogle'

  console.log new Date()
  if not Session.get 'loggedInWithGoogle'
    button = $(ev.currentTarget)
    $(button).prop('disabled', true)
    Meteor.signInWithGoogle({
      requestPermissions: [
        "https://mail.google.com/", # imap
        "https://www.googleapis.com/auth/userinfo.profile", # profile
        "https://www.googleapis.com/auth/userinfo.email", # email
        "https://www.google.com/m8/feeds/" # contacts
      ]
      requestOfflineToken: true
      forceApprovalPrompt: true
    }, (err, mergedUserId) ->
      $(button).prop('disabled', false)
      console.log mergedUserId
      unless err
        Meteor.call 'setUserToLoggedInWithGoogle', Meteor.userId(), (err) ->
          false
        Meteor.call 'updateLastLogin', (err) ->
          false
        Meteor.call 'loadContacts', Meteor.userId(), (err) ->
          console.log err if err
          delete Session.keys['searchQ']
          delete Session.keys['prev_searchQ']
          delete Session.keys['contact_list']
          Session.set 'campaign_id', Session.get 'campaign_id'
          Meteor.call 'checkIfUserLoggedInWithGoogle', Meteor.userId(), (err, res) ->
            Session.set 'loggedInWithGoogle', res

          if search isnt undefined
            setTimeout ->
              # Router.go 'new_campaign'
              $('.search-tags').trigger('click')
            , 1500
    )
  else
    true

initialize = true
saveInt = ''
triggerTimeout = 0

Template.new_campaign.rendered = ->
  menuitemActive('new-campaign')
  introPagesDone 'new_campaign_first', {'introPagesDone.new_campaign_first':true}

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

              getEnteredTagsInit()
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
    getEnteredTagsInit()

    Meteor.defer ->
      getEnteredTagsInit()


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

Template.new_campaign.events
  'click .reset-tags': (e) ->
    mixpanel.track("clicked on reset in a campaign", { });
    $('#recipients').tagit('removeAll')
    $('#existing-recipients').text('')

    $('#tags').tagit('removeAll')
    $('#campaign-tags').val('')
    delete Session.keys['searchQ']

    $('#tmp_matched_contacts tr, #tmp_unmatched_contacts tr').remove()
    refreshDataTable($("#matched-contacts-tab table.dataTable"), $('#tmp_matched_contacts tr'))
    refreshDataTable($("#unmatched-contacts-tab table.dataTable"), $('#tmp_unmatched_contacts tr'))

  'click .search-tags': (e) ->
    mixpanel.track("clicked on search in a campaign", { });
    success = googleOauthOpen(e, true)
    if success
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
          setTimeout ->
            searchContacts searchQuery, Meteor.default_connection._lastSessionId, ->
              mixpanel.track("used search", { });
              console.log("show list")
              Session.set("searchQ", searchQuery)
              Session.set("prev_searchQ", searchQuery)
              Session.set("contact_list", "yes")

              button.data('destroyContactInt', 0)
              introPagesDone 'new_campaign_second', {'introPagesDone.new_campaign_second':true}
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
                    if @autoSelect isnt 2
                      sendToTop10()
                      @autoSelect++
                    button.data('pressed', 0)
                  , 100

                  button.data('destroyContactInt', 1)

                # check for results, if there's none, display notification
                results = button.data('results')
                if results is 0
                  mixpanel.track("no matched contacts after search", { })
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
          , 2500



  'click .tagit-close': (e) ->
    addedTags = $("#tags").tagit("assignedTags").join(" ")
    $('#campaign-tags').val(addedTags)

  'click .btn-save-campaign': (e) ->
    mixpanel.track("clicked on save in a campaign", { });
    Session.set("OWN_MESS", $("#own_message").val())
    Session.set("MAIL_TITLE", $("#subject").val())
    SaveCampaign()
    @autoSelect = 0
    Router.go 'list_campaign'

  'click .back-to-campaign-list': (e) ->
    Router.go 'list_campaign'

  'click .back-to-feature-select': (e) ->
    Router.go 'feature_select'

  'click .mailbox_right': (e) ->
    $('li.tagit-new input').focus()


# campaign list stuff ---------------------------------------------------------------------------------------------------------------------
@autoSelect = 0
Template.list_campaign.rendered = ->
  menuitemActive('campaign-list')
  delete Session.keys['campaign_step']
  @autoSelect = 0

  listInt = setInterval(->
    list = $('#list1 td.info_content span.created.raw')


    if list.length > 4
      initScrollbar('#content_1')

      clearInterval listInt


  , 750)

  introPagesDone 'share_campaign', {'introPagesDone.share_campaign':true}

  if Session.get 'sent_campaign_id'
    console.log Session.get 'sent_campaign_id'
    # $("table#list1").find("[data-campaignid='" + Session.get('sent_campaign_id') + "']").click()
    $('#after-send-share-dialog').modal('show')
    delete Session.keys['sent_campaign_id']


Template.list_campaign.helpers
  campaigns: ->
    campaigns = Campaigns.find().fetch()
    campaigns = _.sortBy campaigns, (c) -> -c.created_at || 0

  rooturl: ->
    Meteor.absoluteUrl ""

  create_date: ->
    Meteor.call 'formatDate', @created_at, @_id, (e, resp) ->
      console.log e if e

      date = resp[0]
      campaignId = resp[1]
      Session.set('date' + campaignId, date)

    date = Session.get('date' + @_id)
    delete Session.keys['date' + @_id]

    return date

  is_message_sent: ->
    if @sent is 'yes'
      return true
    else
      return false

  recipients_count: ->
    count = 0

    _.each(@recipients || [], (item) ->
      count++
    )

    return count


Template.list_campaign.events
  'click .delete-campaign': (e) ->
      e.preventDefault()
      campaignsTable = $('#list1')
      # console.log $(e.currentTarget).data('id')
      apprise('Are you sure to delete this campaign?', {'verify':true}, (r) ->
        if r
          Meteor.call 'deleteCampaign', $(e.currentTarget).data('id')

        if campaignsTable.find('tr').length is 0
          campaignsTable.append('<tr class="no-content-in-list"><td>You have currently no campaigns.</td></tr>')
      )
      # if (confirm('Are you sure?'))

  'click .edit-campaign': (e) ->
      e.preventDefault()
      delete Session.keys['searchQ']
      delete Session.keys['prev_searchQ']
      delete Session.keys['contact_list']
      Session.set 'campaign_id', $(e.currentTarget).data('id')
      Session.set 'campaign_step', 1
      @autoSelect = 0

      Meteor.call 'checkIfUserLoggedInWithGoogle', Meteor.userId(), (err, res) ->
        Session.set 'loggedInWithGoogle', res

      Router.go 'new_campaign'

  'click .send-campaign': (e) ->
      e.preventDefault()
      menuitemActive()
      el = $(e.currentTarget)
      Session.set('shareThisUrl', el.data('shareurl'))
      Session.set 'campaign_step', 3
      Meteor.call 'checkIfUserLoggedInWithGoogle', Meteor.userId(), (err, res) ->
        Session.set 'loggedInWithGoogle', res

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
      @autoSelect = 0
      Meteor.call 'checkIfUserLoggedInWithGoogle', Meteor.userId(), (err, res) ->
        Session.set 'loggedInWithGoogle', res
      Router.go 'new_campaign'

  'click .btn-create-campaign-green': (e) ->
    mixpanel.track("clicked on create new campaign green button", { })

  'click .back-to-feature-select': (e) ->
    Router.go 'feature_select'

  'click a.campaign-share-link': (e) ->
    el = $(e.currentTarget)

    shareURL = el.data('shareurl')
    $('#share-url').val(shareURL)

    shareSubject = el.data('sharesubject')
    $('#share-subject').val(shareSubject)

    campaignId = el.data('campaignid')
    $('#share-id').val(campaignId)
    Session.set('shareThisUrl', el.data('shareurl'))
    # $('.fb-share-button').attr('data-href', shareURL)

  'click a.show-shares-link': (e) ->
    el = $(e.currentTarget)
    campaignId = el.data('campaignid')
    Session.set 'show_shares_campaign_id', campaignId

  'click #share-email': (e) ->
    mixpanel.track("clicked on share campaign with email", { })
    e.preventDefault()

    $('#share-dialog button.close').trigger('click')

    campaignId = $('#share-id').val()
    Session.set('campaign_id', campaignId)

    Meteor.setTimeout ->
      Router.go("share_via_email")
    , 1000


  'click #share-facebook': (e) ->
    mixpanel.track("clicked on share campaign with facebook", { })
    e.preventDefault()
    shareURL = $('#share-url').val()
    window.open('https://www.facebook.com/sharer/sharer.php?u=' + shareURL, 'facebook-share-dialog', 'width=626,height=436');

  'click #share-twitter': (e) ->
    mixpanel.track("clicked on share campaign with twitter", { })
    e.preventDefault()
    shareURL = $('#share-url').val()
    window.open("http://twitter.com/share?text=" + encodeURIComponent("Help support my idea by sharing this message with your network. " + shareURL), 'twitter', "width=575, height=400");


# inbox stuff -----------------------------------------------------------------------------------------------------------------------------

Template.inbox.rendered = ->
  menuitemActive('my-inbox')

  listInt = setInterval(->
    list = $('#inbox-messages td.date_table span.created.raw')

    if list.length > 4
      initScrollbar('#content_1')

      clearInterval listInt

  , 750)

  if Session.get 'sent_campaign_id'
    $("table#inbox-messages").find("[data-campaignid='" + Session.get('sent_campaign_id') + "']")[0].click()
    delete Session.keys['sent_campaign_id']
    delete Session.keys['afterEmailVerified']

  if Session.get 'afterEmailVerified'
    delete Session.keys['afterEmailVerified']


Template.inbox.helpers
  randomnumber: ->
    random = Math.floor((Math.random() * 5) + 1)

  messages: ->
    email = Meteor.user().profile.email
    messages = Messages.find({to: email}).fetch()
    messages = _.sortBy messages, (m) -> -m.created_at || 0

  sender: ->
    Meteor.call 'getSenderName', @from, (e, resp) ->
      console.log e if e

      name = resp[0]
      senderId = resp[1]
      Session.set('name' + senderId, name)

    name = Session.get('name' + @from)

    if @from is Meteor.user()._id
      name += ' (me)'

    return name

  picture: ->
    Meteor.call 'getSenderProfilePicture', @from, (e, resp) ->
      console.log e if e

      picture = resp[0]
      senderId = resp[1]
      Session.set('picture' + senderId, picture)

    picture = Session.get('picture' + @from)

    return picture

  tags: ->
    Meteor.call 'getMessageTags', @campaign_id, (e, resp) ->
      console.log e if e

      tags = resp[0]
      campaignId = resp[1]
      Session.set('tags' + campaignId, tags)

    tags = Session.get('tags' + @campaign_id)
    # delete Session.keys['tags' + @campaign_id]

    return tags

  send_date: ->
    Meteor.call 'formatDate', @created_at, @_id, (e, resp) ->
      console.log e if e

      date = resp[0]
      messageId = resp[1]
      Session.set('date' + messageId, date)

    date = Session.get('date' + @_id)
    # delete Session.keys['date' + @_id]

    return date

  is_new_message: ->
    if @new_message is 'yes'
      return true
    else
      return false


Template.inbox.events
  'click tr.message-header': (e) ->
    currTr = $(e.currentTarget)
    messageId = currTr.data('id')
    messageContent = currTr.next()

    # mark current message as read
    Messages.update messageId,
      $set:
        new_message: 'no'

    if messageContent.is(':visible')
      messageContent.hide()
    else
      messageContent.show()

  'click a.delete-message': (e) ->
    e.preventDefault()
    messageId = $(e.currentTarget).data('id')
    inboxMessagesTable = $('#inbox-messages tr')

    apprise('Are you sure to delete this message?', {'verify':true}, (r) ->
      if r
        Messages.remove({_id: messageId})

        if inboxMessagesTable.find('tr').length is 0
          inboxMessagesTable.append('<tr class="no-content-in-list"><td>There are currently no messages in your Inbox.</td></tr>')
    )

  'click a.forward-message': (e) ->
    e.preventDefault()

    messageId = $(e.currentTarget).data('id')

    message = Messages.findOne({_id: messageId})
    campaign = Campaigns.findOne({_id: message.campaign_id})

    Session.set "MAIL_TITLE", message.subject
    Session.set "ORIG_MESS", message.message
    Session.set "slug", message.slug
    Session.set "senderId", message.from
    Session.set "searchQ", campaign.search_tags
    Session.set "campaign_id", message.campaign_id
    Session.set "public", 'no'

    delete Session.keys["OWN_MESS"]

    Router.go('edit')

Template.show_shares_modal.helpers
  shares: ->
    campaignId = Session.get 'show_shares_campaign_id'
    shares = Sharings.find({owner_id:Meteor.userId(), sender_id:{$ne:Meteor.userId()}, campaign_id:campaignId}).fetch()
    senderIds = _.pluck shares, 'sender_id'
    senderIds = _.uniq senderIds
    sortedShares = _.map senderIds, (value) ->
      found = _.where shares, {sender_id: value}
      {sender_id: value, senderName:found[0].senderName, count: found.length}

    sortedShares

Template.share_modal.rendered = ->
  client = new ZeroClipboard($('#copyToClipboard'))
  client.on 'copy', (e) ->
    e.clipboardData.setData 'text/plain', $('#shareUrlToCopy').val()

Template.share_modal.helpers
  shareUrl: ->
    Session.get 'shareThisUrl'

Template.after_send_share_modal.rendered = ->
  client = new ZeroClipboard($('#copyToClipboardAfter'))
  client.on 'copy', (e) ->
    e.clipboardData.setData 'text/plain', $('#shareUrlToCopyAfter').val()

Template.after_send_share_modal.helpers
  shareUrl: ->
    Session.get 'shareThisUrl'

Template.campaign_progress.rendered = ->
  switch Session.get 'campaign_step'
    when 1
      $('#campaign_progress_bar #campaign_step_one').addClass('current')
    when 2
      $('#campaign_progress_bar #campaign_step_one').addClass('done')
      $('#campaign_progress_bar #campaign_step_two').addClass('current')
    when 3
      $('#campaign_progress_bar #campaign_step_one').addClass('done')
      $('#campaign_progress_bar #campaign_step_two').addClass('done')
      $('#campaign_progress_bar #campaign_step_three').addClass('current')
    else
      $('#campaign_progress_bar #campaign_step_one').addClass('done')
      $('#campaign_progress_bar #campaign_step_two').addClass('done')
      $('#campaign_progress_bar #campaign_step_three').addClass('done')
      $('#campaign_progress_bar #campaign_step_four').addClass('current')

# functions -------------------------------------------------------------------------------------------------------------------------------

@key_up_delay = 0;
getEnteredTags = () ->
  if (@key_up_delay)
    clearTimeout @key_up_delay

  message = $('#own_message').val()

  @tag_replaced = ''
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

    if currentTagsStr isnt newTagsStr
      # clear tags
      $("#tags").tagit("removeAll")

      textarea = $('#own_message')

      w5ref = textarea.data('wysihtml5');

      @tag_replaced = textarea.val()

      # add predefined tags
      _.each(searchTags || [],(item) ->
        $("#tags").tagit("createTag", item)

        @tag_replaced = @tag_replaced.replace('#' + item + ' ', '<span style="color:rgb(150, 150, 150)">'+item+'</span> ')
      )

      if w5ref
        w5ref.editor.setValue('')
      else
        ta.val('')

      # trick to update the content of the editor
      w5ref.editor.composer.element.focus()
      window.frames[0].document.execCommand("InsertHTML", false, @tag_replaced)

    Session.set("search_tags", tags)
  , 1000)

getEnteredTagsInit = () ->
  if (@key_up_delay)
    clearTimeout @key_up_delay

  @key_up_delay = setTimeout(->
    searchTags = $('#campaign-tags').val().split(' ')
    $("#tags").tagit("removeAll")
    _.each(searchTags || [],(item) ->
      $("#tags").tagit("createTag", item)
    )
    getEnteredTags()
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


@initScrollbar = (scrollcontent) ->
  $(scrollcontent).mCustomScrollbar
    scrollButtons:
      enable: true,
      scrollType: "pixels",
      horizontalScroll: true


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
        # $.gritter.add
        #   title: "Notification"
        #   text: "Campaign updated!"
        $('#campaignSaved').animate {opacity: 1.0}, 1000, () ->
          $('#campaignSaved').animate {opacity: 0.0}, 1000
    else
      Meteor.call 'createCampaign', user._id, $("#subject").val(), $("#own_message").val(), $("#tags").tagit("assignedTags").join(" "), recipients, (e, campaign_id) ->
        console.log e if e
        Session.set("campaign_id", campaign_id)
        # $.gritter.add
        #   title: "Notification"
        #   text: "Campaign saved!"
        $('#campaignSaved').animate {opacity: 1.0}, 1000, () ->
          $('#campaignSaved').animate {opacity: 0.0}, 1000


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
