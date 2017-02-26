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
logger.default.transports.console.timestamp = true;

if (config.logFile === true) {
    logger.add(logger.transports.File, { filename: config.logFilePath });
}

if (config.logConsole !== true) {
    logger.remove(logger.default.transports.console);
}

logger.log('info', 'Init system');
logger.log('info', 'Debugger level: ' + logger.level);

module.exports = logger;