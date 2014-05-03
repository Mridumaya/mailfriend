@Contacts = new Meteor.Collection "contacts"#,
  # transform: (doc) ->
  #   new UserAccount(doc)

@Sharings = new Meteor.Collection "sharings"
@Messages = new Meteor.Collection "messages"

@Campaigns = new Meteor.Collection "campaigns"
@SearchStatus = new Meteor.Collection "search_status"
