
#mailfriend

lets you send mails that your friends can pass on

download and deploy by

##1. test/see in console/logs
use the below command in console to see the contact matching the query.
`$ Contacts.find({searchQ: 'knotable'}, {fields: {email: true, searchQ: true}}).fetch()`
this is an example of result of searching contact which was matching 'knotable'.

##2. how to deploy?
Re:  pull the latest code, change dirctory to proejct folder, deploy with this command:

First we need to login to the meteor account to deploy. To login to a meteor account
```
meteor login <username> <password>
```

After signing into a account use the following command. The domain you specify here should be linked to the acount you signed in just.

```
meteor deploy <domain name>
```

###Signin details

Domain | Username | Password
---|---|---
stable.mailfriend.meteor.com|dev1mailfriend|mailfriend
mailfriend.meteor.com|long|mailfriend

Apart from from this there is possibility to give authorization for a another user to use you domain. To perform this action we need to use the following command

```
meteor authorized <domain> --list - To list all the authorised user
```
```
meteor authorized <domain> --add <username> - To authorize a user for a domain
```
```
meteor authorized <domain> --remove <username> - To unauthorize a user for a domain
```


3. query format?
any words
