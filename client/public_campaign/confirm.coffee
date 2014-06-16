Template.public_confirm.rendered = ->
  mixpanel.track("visits step 4 page", { });


Template.public_confirm.helpers 
  subject: ->
    Session.get "MAIL_TITLE" || ""

  forwaded_message: ->
    Session.get "ORIG_MESS" || ""

  user_message: ->
    Session.get "OWN_MESS" || ""

  emails: ->
    to = []
    $(Session.get "CONF_DATA").each (index, value) -> 
      to.push {'email': value}
    to


Template.public_confirm.events
  'click .confirm-to-contact-list': (e) ->
    mixpanel.track("click on cancel/back button", { });
    Router.go('publiccontactlist')
    # Session.set("STEP", "public_contact_list")

  'click #facebook': (e) ->
    window.open('https://www.facebook.com/sharer/sharer.php?u=http://mailfriend.meteor.com/', 'facebook-share-dialog', 'width=626,height=436');

  'click #twitter': (e) ->
    window.open("http://twitter.com/share?text=" + encodeURIComponent("Check this cool pictures application http://mailfriend.meteor.com/"), 'twitter', "width=575, height=400");

  'click #google': (e) ->
    window.open('https://plus.google.com/share?url=http://mailfriend.meteor.com/', '', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=600,width=600');

  'click #linkedin': (e) ->
    window.open("http://www.linkedin.com/shareArticle?mini=true&url=http://mailfriend.meteor.com/", '', "width=620, height=432");

  'click a.draft-send': (e) ->
    e.preventDefault()
    subject = Session.get "MAIL_TITLE"
    body = Session.get("OWN_MESS") + "<br><b>Forwarded Message</b><br>" + Session.get "ORIG_MESS"
    to = Session.get "CONF_DATA"

    console.log subject, body, to
    $('.draft-send').prop('disabled', true)

    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      if err
        console.log err
      else
        sharing = Sharings.findOne({type: 'email'})
        message = Messages.findOne()
        if sharing
          Sharings.update sharing._id,
            $set:
              subject: subject
              htmlBody: body
              senderName: Meteor.user()?.profile?.name || ""
        else
          Sharings.insert
            type: 'email'
            subject: subject
            htmlBody: body
            senderName: Meteor.user()?.profile?.name || ""

        if message
          Messages.update message._id,
            $set:
              message: Session.get("ORIG_MESS")
        else
          Messages.insert
            message: Session.get("ORIG_MESS")
            password: 'queens'
            created_at: new Date()

        mixpanel.track("send email", { });
        console.log 'send mail success'
        $(".success").removeClass("hidden")
        $('.draft-send').prop('disabled', false)
        $('.draft-close').trigger('click')
        