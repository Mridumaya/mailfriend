mailfriend
==========

lets you send mails that your friends can pass on


download and deploy by 

1. test/see in console/logs
use the below command in console to see the contact matching the query.
$ Contacts.find({searchQ: 'knotable'}, {fields: {email: true, searchQ: true}}).fetch()
this is an example of result of searching contact which was matching 'knotable'.

2. how to deploy
Re:  pull the latest code, change dirctory to proejct folder, deploy with this command: meteor deploy mailfriend.meteor.com

Meteor has updated its deploy system. We need to create account and login to deploy.
username: long
password: mailfriend

3. query format?
any words
