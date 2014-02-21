@Contacts = new Meteor.Collection "contacts"#,
  # transform: (doc) ->
  #   new UserAccount(doc)

@Sharings = new Meteor.Collection "sharings"