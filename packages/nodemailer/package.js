// file: packages.js
Npm.depends({
  'nodemailer': '0.6.0'
});

Package.on_use(function(api){
  api.add_files('nodemailer.js', 'server');
  api.export("Nodemailer");
});