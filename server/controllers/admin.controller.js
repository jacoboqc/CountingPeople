var admin = {};
var logger = require('../logger.js');

admin.deleteDatabase = function (req, res) {
    db.db.dropDatabase(function (err, result) {
        if (err) {
            logger.log('error', err);
            res.status(501).send('Something happenned');
        } else {
            logger.log('info', 'Removed entire database');
            res.status(200).send('Database removed successfully');
        }
    });
};

module.exports = admin;