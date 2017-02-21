var logger = require('winston');
var config = require('./config/config.js');

logger.level = config.debug;
var colors = {
    info: 'blue',
    error: 'red',
    warn: 'yellow',
    debug: 'green'
};

logger.addColors(colors);
logger.default.transports.console.colorize = true;
//logger.default.transports.console.timestamp = true;
logger.add(logger.transports.File, {filename: config.logFile});
    
logger.info('info', 'Init system');
logger.info('info', 'Debugger level: ' + logger.level);

module.exports = logger;