// Just a basic server setup for this site
var Connect = require('./vendor/connect');

module.exports = Connect.createServer(
  Connect.logger(),
  Connect.conditionalGet(),
  Connect.favicon(),
  Connect.cache(),
  Connect.gzip(),
  require('./vendor/wheat')(__dirname)
).listen(3000);


module.exports = Connect.createServer(
  Connect.logger(),
  Connect.conditionalGet(),
  Connect.favicon(),
  Connect.cache(),
  Connect.gzip(),
  require('./vendor/wheat')(__dirname)
).listen(3001);
