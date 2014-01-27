// file: packages.js
Npm.depends({
  'xoauth2': '0.1.8'
});

Package.on_use(function(api){
  api.add_files('xoauth2.js', 'server');
  api.export("XOauth2");
});