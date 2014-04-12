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
    user = Meteor.user()
    if user
      Meteor.call 'createCampaign', user._id, $("#subject").val(),  $("#own_message").val(), $("#tags").tagit("assignedTags").join(" "),(e, campaign_id) ->
        if(e)
          console.log "error: "
          console.log e
        console.log("saved: ") + campaign_id
        $.gritter.add
          title: "Notification"
          text: "Campaign Saved!"

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
