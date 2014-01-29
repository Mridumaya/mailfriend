@Contacts = new Meteor.Collection "contacts"#,
  # transform: (doc) ->
  #   new UserAccount(doc)

@AppVariables = new Meteor.Collection "app_variables"