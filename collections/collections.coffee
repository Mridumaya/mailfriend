@Contacts = new Meteor.Collection "contacts"#,
  # transform: (doc) ->
  #   new UserAccount(doc)

@Sharings = new Meteor.Collection "sharings"
@Messages = new Meteor.Collection "messages"

@SearchStatus = new Meteor.Collection "search_status"
@UserMessages = new Meteor.Collection "user_messages"
