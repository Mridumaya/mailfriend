@SelectedEmails = new Meteor.Collection(null);

@SelectedEmailsHelper =
  selectedEmail: ()->
    SelectedEmails.findOne()


  selectEmail: (email) ->
    emailModel = @selectedEmail()
    if emailModel
      SelectedEmails.update(emailModel._id, {$addToSet: {emails: email}})
    else
      SelectedEmails.insert({emails: [email]})



  unselectEmail: (email) ->
    emailModel = @selectedEmail()
    if emailModel
      SelectedEmails.update(emailModel._id, {$pull: {emails: email}})



  selectEmails: (emails) ->
    emailModel = @selectedEmail()
    if emailModel
      SelectedEmails.update emailModel._id, {$addToSet: {emails: {$each: emails}}}



  unselectEmails: (emails) ->
    emailModel = @selectedEmail()
    if emailModel
      SelectedEmails.update emailModel._id, {$pullAll: {emails: emails}}

  containEmail: (email) ->
    emailModel = @selectedEmail()
    if emailModel
      _.contains emailModel.emails, email