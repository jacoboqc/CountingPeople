var express = require('express'),
    router = express.Router(),
    mac = require('../controllers/macs.controller'),
    logger = require('../logger.js');

router.get('/', function (req, res) { //devuelve todos los datos
    logger.log('debug', 'get al raiz');
    mac.getAll(req, res);

}).put('/', function (req, res) {    //actualiza macs
    logger.log('debug', 'put al raiz');
    mac.addMacs(req, res);

}).get('/id/:id', function (req, res) {
    logger.log('debug', 'get by id');
    mac.findByID(req, res);

}).get('/device/:device', function (req, res) {
    logger.log('debug', 'by device');
    mac.findByDevice(req, res);

}).get('/mac/:mac', function (req, res) {
    logger.log('debug', 'by mac');
    mac.findMac(req, res);

}).get('/interval', function (req, res) {
    var start = req.query.start;
    var end = req.query.end;

    if (start === undefined || end === undefined) {
        if (end !== undefined) {
            logger.log('debug', 'by interval end');
            mac.findBeforeEnd(end, req, res);
        } else if (start !== undefined) {
            logger.log('debug', 'by interval start');
            mac.findAfterStart(start, req, res);
        } else {
            logger.log('debug', 'by interval all undefined');
            res.status(404).send();
        }
    } else {
        logger.log('debug', 'by interval');
        mac.findByInterval(start, end, req, res);
    }
});

module.exports = router;