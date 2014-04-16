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
    return Campaigns.find()

@key_up_delay = 0;
get_entered_tags = (message) ->
  if(@key_up_delay)
    clearTimeout @key_up_delay
  @key_up_delay = setTimeout(->
    $("#tags").tagit("assignedTags")
    re = /(?:^|\W)#(\w+)(?!\w)/g
    match
    tags = new Array()

    $("#tags").tagit("removeAll")
    while (match = re.exec(message))
      $("#tags").tagit("createTag", match[1]);
      tags.push match[1]

    Session.set("search_tags", tags)
  , 500)

Template.new_campaign.events
  'click .search-tags': (e) ->
    searchQuery = $("#tags").tagit("assignedTags").join(" ");
    mixpanel.track("search tag", { });
    searchContacts searchQuery, ->
      console.log("show list")
      Session.set("contact_list", "yes")
  'keyup #own_message': (e) ->
    message = $(e.currentTarget).val()
    get_entered_tags(message)

  'click .btn-save-campaign': (e) ->
    console.log "save campaign"
    Session.set("OWN_MESS", $("#own_message").val())
    Session.set("MAIL_TITLE", $("#subject").val())
    SaveCampaign()
    Router.go 'list_campaign'
      #console.log "campagin: " + campaign_id
  'click .back-to-campaign-list': (e) ->
    Router.go '/campaigns'

Template.list_campaign.events
    'click .delete-campaign': (e)->
        console.log $(e.currentTarget).attr('data-id')
        if(confirm('Are you sure?'))
            Meteor.call 'deleteCampaign', $(e.currentTarget).attr('data-id')

    'click .edit-campaign': (e)->
        Session.set 'campaign_id', $(e.currentTarget).attr('data-id')
        Router.go 'new_campaign'

    'click .btn-create-campaign': (e) ->
        Router.go 'new_campaign'

Template.new_campaign.rendered = ->
  $("#tags").tagit({
    afterTagAdded: (event,ui)->
      Session.set("search_tags", $("#tags").tagit("assignedTags"))
      Session.set("searchQ", $("#tags").tagit("assignedTags").join(" "))
    afterTagRemoved: (event,ui)->
      Session.set("search_tags", $("#tags").tagit("assignedTags"))
      Session.set("searchQ", $("#tags").tagit("assignedTags").join(" "))
  })
  _.each(Session.get("search_tags")|| [],(item) ->
    $("#tags").tagit("createTag", item);
  )
  if Session.get 'campaign_id'
    Meteor.defer ->
        message = $('#own_message').val()
        get_entered_tags(message)


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
