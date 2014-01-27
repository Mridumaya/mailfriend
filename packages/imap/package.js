Npm.depends({
  'imap': '0.8.7'
});

Package.on_use(function(api){
  api.add_files('imap.js', 'server');
  api.export("Imap");
});