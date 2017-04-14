var express = require('express'),
    router = express.Router(),
    admin = require('../controllers/admin.controller'),
    logger = require('../logger.js'),
    config = require('../config/config.js');

router.delete('/', function (req, res) { 
    if (req.query.password === config.adminPassword) {
        logger.log('info', 'Deleting entire Database');
        admin.deleteDatabase(req, res); 
    } else {
        logger.log('error', 'Invalid password');
        res.status(401).send('Invalid login');
    }
});

module.exports = router;