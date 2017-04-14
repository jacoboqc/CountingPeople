var admin = {};
var logger = require('../logger.js');
var config = require('../config/config.js');
var backup = require('mongodb-backup');
var dateTime = require('node-datetime');


admin.deleteDatabase = function (req, res) {
    var directory;

    if (config.backupDirectory === 'Default') {
        directory = '../backup';
    }
    var dt = dateTime.create();
    var formatted = dt.format('Y-m-d H:M:S');

    backup({
        uri: config.dbAddres, 
        root: directory,
        tar: formatted + '.tar',
        callback: function (err) {

            if (err) {
                logger.log('error', err);
                res.status(501).send('Something happenned');
            } else {
                logger.log('info', 'Backup completed');
                db.db.dropDatabase(function (err, result) {
                    if (err) {
                        logger.log('error', err);
                        res.status(501).send('Something happenned');
                    } else {
                        logger.log('info', 'Removed entire database');
                        res.status(200).send('Database removed successfully');
                    }
                });
            }
        }
    });


    
};

module.exports = admin;