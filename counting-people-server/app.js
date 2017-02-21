var express = require('express'),
    app = express(),
    bodyParser = require('body-parser'),
    methodOverride = require('method-override'),
    mongoose = require('mongoose'),
    logger = require('./logger.js'),
    macsModel = require('./models/macs.model'),
    config = require('./config/config.js');

app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(methodOverride());

/********* DATABASE *********/
mongoose.connect(config.dbAddres, function (err) {
    if (err) {
        logger.log('error', 'Connecting to Database. ' + err);
        process.exit();
    }
});

global.db = mongoose.connection;
global.db.on('error', function (err) {
    logger.log('error', err);
});

logger.log('info', 'Database Connected');
/************ */

//************ Routing ***********/
var router = express.Router();
router.get('/', function (req, res) {
    res.send('Counting People Server');
});

app.use('/macs', require('./routes/macs.routes'));
app.use(router);
////////////

app.listen(config.port, function () {
    //var today = new Date();
    //var myToday = new Date(today.getFullYear(), today.getMonth(), today.getDate(), today.getHours(), today.getMinutes(), today.getSeconds());

    logger.log('info', 'Node server running on http://localhost:3000');
});

