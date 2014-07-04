Template.public_confirm.rendered = ->
  mixpanel.track("visits step 4 page", { });


Template.public_confirm.helpers
  subject: ->
    Session.get "MAIL_TITLE" || ""

  forwaded_message: ->
    message = Session.get "ORIG_MESS" || ""
    message = message.replace(/style="color:rgb\(150, 150, 150\)"/g, '')

  user_message: ->
    message = Session.get "OWN_MESS" || ""

  emails: ->
    to = []
    $(Session.get "CONF_DATA").each (index, value) ->
      to.push {'email': value}
    to

  shareurl: ->
    Meteor.call 'getCampaignSlug', Session.get('campaign_id'), (e, resp) ->
      console.log e if e

      slug = resp[0]
      campaignId = resp[1]
      Session.set('slug' + campaignId, slug)

    slug = Session.get('slug' + Session.get('campaign_id'))

    return Meteor.absoluteUrl "" + Meteor.user()._id + '/' + slug

Template.public_confirm.events
  'click .confirm-to-contact-list': (e) ->
    mixpanel.track("click on cancel/back button", { });

    is_public = Session.get('public')
    if is_public is 'yes'
      Router.go('publiccontactlist')
    else
      Router.go('contactlist')

  'click .draft-send': (e) ->
    e.preventDefault()
    slug = $(e.currentTarget).data('shareurl')

    subject = Session.get "MAIL_TITLE"
    body = Session.get("OWN_MESS") + "<br><b>Forwarded Message</b><br>" + Session.get "ORIG_MESS"
    body = body.replace(/style="color:rgb\(150, 150, 150\)"/g, '')
    body = body + '<br><br>Support this idea by sending it to people who care by clicking on this link:<br>' + slug
    to = Session.get "CONF_DATA"

    # console.log subject, body, to
    $('.draft-send').prop('disabled', true)

    Meteor.call 'sendMail', subject, body, to, (err, result) ->
      campaign_id = Session.get("campaign_id")
      campaign = Campaigns.findOne({_id: campaign_id})

      if err
        console.log err
      else
        # sharing = Sharings.findOne({type: 'email', campaign_id: campaign_id})
        # if sharing
        #   Sharings.update sharing._id,
        #     $set:
        #       subject: subject
        #       htmlBody: body
        #       senderName: Meteor.user()?.profile?.name || ""
        # else

        if !!Meteor.user()
          sender_id = Meteor.user()._id
        else
          sender_id = 'guest'

        console.log sender_id

        Sharings.insert
          type: 'email'
          campaign_id: campaign_id
          sender_id: sender_id
          owner_id: Session.get("senderId")
          slug: Session.get("slug")
          subject: subject
          htmlBody: body
          senderName: Meteor.user()?.profile?.name || ""

        _.each(to,(email) ->
          # message = Messages.findOne({campaign_id: campaign_id, to: email})

          # if message
          #   Messages.update message._id,
          #     $set:
          #       message: body
          #       subject: subject
          #       new_message: 'yes'
          # else
            Messages.insert
              campaign_id: campaign_id
              slug: Session.get("slug")
              from: sender_id
              to: email
              message: body
              subject: subject
              # password: ''
              new_message: 'yes'
              created_at: new Date()
        )

        # message = Messages.findOne({campaign_id: campaign_id})
        # if message
        #   Messages.update message._id,
        #     $set:
        #       message: Session.get("ORIG_MESS")
        # else
        #   Messages.insert
        #     campaign_id: campaign_id
        #     slug: campaign.slug
        #     message: Session.get("ORIG_MESS")
        #     password: 'queens'
        #     created_at: new Date()

        $.gritter.add
          title: "Email sent"
          text: "You have successfully forwarded this campaign email!"

        mixpanel.track("send email", { });

        console.log 'send mail success'

        $('.draft-send').prop('disabled', false)
        $('.draft-close').trigger('click')
