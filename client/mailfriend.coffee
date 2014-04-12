Template.masterLayout.helpers
  picture: ->
    user = Meteor.user()
    console.log("Hello")
    console.log(user)
    if user and user.profile and user.profile.picture
      return user.profile.picture
    return 'images/default_user.jpg'

Template.masterLayout.events
  'click .logout': (e) ->
    e.preventDefault
    Meteor.logout()
    return true
  'click .edit': (e) ->
    e.preventDefault
    Router.go "edit_user_info"


Template.feature_select.helpers
  name: ->
    user = Meteor.user()
    if user
      user.profile.name.split(" ")[0]
    else
      ''

Template.feature_select.events
  'click .btn-create-campaign': (e) ->
    mixpanel.track("visit new campaign", { });
    Router.go "new_campaign"
#  'click .btn-view-campaign': (e) ->
#    mixpanel.track("visit view campaign", { });
#    Session.set("STEP", "welcome")
#  'click .btn-view-messages': (e) ->
#    Session.set("STEP", "welcome")


searchContacts = (searchQuery, cb) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'searchContacts', searchQuery, (err) ->
        Session.set('searchQ', searchQuery)
        console.log 'searchContact Error: ', err if err
        cb()
    else
      searchContacts(searchQuery)
  , 500

Template.confirm.rendered = ->
  mixpanel.track("visits step 4 page", { });
  emails = Session.get("CONF_DATA")
  body = Session.get("OWN_MESS") || ""

  to = _.map emails, (e) -> '<p class="email" style="margin:0 0 0;">' + e + '</p>'
  $('.draft-subject').text(Session.get("MAIL_TITLE") || "Invitation")
  $('.draft-body').html(body)
  $('.draft-to').html(to.join(''))

Template.confirm.events
  'click .confirm-to-contact-list': (e) ->
    mixpanel.track("click on cancel/back button", { });
    Router.go("new_campaign")

  'click #facebook': (e) ->
    window.open('https://www.facebook.com/sharer/sharer.php?u=http://mailfriend.meteor.com/', 'facebook-share-dialog', 'width=626,height=436');
  'click #twitter': (e) ->
    window.open("http://twitter.com/share?text=" + encodeURIComponent("Check this cool pictures application http://mailfriend.meteor.com/"), 'twitter', "width=575, height=400");
  'click #google': (e) ->
    window.open('https://plus.google.com/share?url=http://mailfriend.meteor.com/', '', 'menubar=no,toolbar=no,resizable=yes,scrollbars=yes,height=600,width=600');
  'click #linkedin': (e) ->
    window.open("http://www.linkedin.com/shareArticle?mini=true&url=http://mailfriend.meteor.com/", '', "width=620, height=432");

  'click button.draft-send': (e) ->
    subject = $('.draft-subject').text()
    body = $('.draft-body').html()
    to = []
    $('.preview .draft-to p.email').each -> to.push $(this).text()
    console.log subject, body, to
    $('.draft-send').prop('disabled', true)
    #sharingBody = $('.email-body2').code()
    sharingBody = body


    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      if err
        console.log "greska"
        console.log err
      else
        sharing = Sharings.findOne({type: 'email'})
        if sharing
          Sharings.update sharing._id,
            $set:
              subject: subject
              htmlBody: sharingBody
        else
          Sharings.insert
            type: 'email'
            subject: subject
            htmlBody: sharingBody
        mixpanel.track("send email", { });
        console.log 'send mail success'
        $(".success").removeClass("hidden")
        $('.draft-send').prop('disabled', false)
        $('.draft-close').trigger('click')



validatePassword = (password) ->
  password is 'queens'


Template.google_api_modal.helpers
  'domain': ->
    Meteor.absoluteUrl()


Template.google_api_modal.events
  'keypress .client-id': (e) ->
    $('.client-secret').focus() if e.which is 13


  'click .google-api-set': (e) ->
    id = $('.client-id').val().trim()
    secret = $('.client-secret').val().trim()
    if id and secret
      console.log id
      console.log secret
      $('.google-api-set').prop('disabled', true)
      Meteor.call 'initGoogleOauth', id, secret, (err) ->
        console.log err if err
        GoogleAccountChecker.checkGoogleApi()

@searchContacts = (searchQuery, cb) ->
  Meteor.setTimeout ->
    if Meteor.user()
      Meteor.call 'searchContacts', searchQuery, (err) ->
        Session.set('searchQ', searchQuery)
        console.log 'searchContact Error: ', err if err
        cb()
    else
      searchContacts(searchQuery)
  , 500
