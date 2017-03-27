var json2csv = require('json2csv');
var fs = require('fs');
var MacModel = db.model('macs');
var logger = require('../logger.js');
var macs = {};
var fieldsIngored = '-__v -_id -origin._id';
var macRegex = '[A-Fa-f0-9]{64}';
var dateRegex = /^(\d{4})\/(\d{2}|\d{1})\/(\d{2}|\d{1})-(\d{2}|\d{1})\:(\d{2}|\d{1})\:(\d{2}|\d{1})/g;
var fields = ['mac', 'device', 'ID', 'time', 'type'];

macs.getAll = function (req, res) {
    MacModel.find({}, fieldsIngored, function (err, data) {
        if (err) {
            res.status(500).send('Internal error');
            logger.log('error', 'ERROR FINDING IN DATABASE: ' + err.message);
        } else {
            data = __parseDBResponseToJSON(data);
            if (req.header('Accept') === 'text/csv') {
                try {
                    var CSV = __CSVResponse(data);
                    res.status(200).send(CSV);
                } catch (err) {
                    res.status(500).send('Cannot send CSV');
                    logger.info('error', err);
                }
            } else {
                res.status(200).json(data);
            }
        }
    });
};

macs.addMacs = function (req, res) {
    var sample = {
        mac: req.body.mac,
        origin: [{
            ID: req.body.origin.ID,
            time: new Date(req.body.origin.time)
        }],
        device: req.body.device,
        type: req.body.type
    };
    try {
        if (!req.body.origin.time.match(dateRegex)) {
            res.status(400).send('Invalid date');
            logger.log('error', 'Invalid date');
        } else if (!sample.mac.match(macRegex)) {
            res.status(400).send('Invalid MAC');
            logger.log('error', 'Invalid MAC');
        } else {
            __findMAC(sample, req, res);
        }
    } catch (err) {
        res.status(400).send('Invalid format');
        logger.log('error', err);
    }
};

macs.findByID = function (req, res) {
    var id = req.params.id;
    __findDB({ 'origin.ID': id }, ' -origin.ID', req, res);
};

macs.findByDevice = function (req, res) {
    var device = req.params.device;
    __findDB({ 'device': device }, ' -device', req, res);
};

macs.findMac = function (req, res) {
    var mac = req.params.mac;
    try {
        if (mac.match(macRegex)) {
            __findDB({ 'mac': mac }, ' -mac', req, res);
        } else {
            res.status(400).send('Invalid MAC');
            logger.log('error', 'Invalid MAC');
        }
    } catch (err) {
        res.status(400).send('Invalid format');
        logger.log('error', err);
    }
};

macs.findBeforeEnd = function (end, req, res) {
    if (!end.match(dateRegex)) {
        logger.log('error', 'End empty or cannot parse');
        res.status(400).send('End empty or cannot parse');
    } else {
        var endDate = new Date(end);
        __findDB({ 'origin.time': { $lte: endDate } }, '', req, res);
    }
};

macs.findAfterStart = function (start, req, res) {
    if (!start.match(dateRegex)) {
        logger.log('error', 'Start empty or cannot parse');
        res.status(400).send('Start empty or cannot parse');
    } else {
        var startDate = new Date(start);
        __findDB({ 'origin.time': { $gte: startDate } }, '', req, res);
    }
};

macs.findByInterval = function (start, end, req, res) {
    if (!start.match(dateRegex) || !end.match(dateRegex)) {
        logger.log('error', 'Start/End empty or cannot parse');
        res.status(400).send('Start/End empty or cannot parse');
    } else {
        var startDate = new Date(start);
        var endDate = new Date(end);
        __findDB({ 'origin.time': { $gte: startDate, $lte: endDate } }, '', req, res);
    }
};

function __dateStringFormat(dateISO) {
    var dateSplit, date, hour;

    dateSplit = dateISO.toISOString().replace('Z', '').split('T');
    date = dateSplit[0].split('-');
    hour = dateSplit[1].split(':');

    return date[0] + '/' + date[1] + '/' + date[2] + '-' + hour[0] + ':' + hour[1] + ':' + hour[2].split('.')[0];
}

function __parseDBResponseToJSON(data) {
    var dataView = [];
    for (var i = 0; i < data.length; i++) {
        var temp = {};
        temp.mac = data[i].mac;
        temp.device = data[i].device;
        temp.origin = [];
        for (var j = 0; j < data[i].origin.length; j++) {
            temp.origin.push({
                ID: data[i].origin[j].ID,
                time: __dateStringFormat(data[i].origin[j].time)
            });
        }
        temp.type = data[i].type;
        dataView.push(temp);
    }
    return dataView;
}

function __addMac(mac) {
    logger.log('debug', 'Adding to database' + mac.toString());

    var macModel = new MacModel(mac);
    macModel.save(function (err) {
        if (err) {
            return err;
        }
    });
}

function __updateMac(newData, oldData) {
    logger.log('debug', 'Updating database');
    oldData[0].origin.forEach(function (item) {
        newData.origin.push(item);
    });
    MacModel.update({ 'mac': newData.mac }, newData, {}, function (err, num) {
        if (err) {
            return err;
        }
    });
}

function __findMAC(sample, req, res) {
    MacModel.find({ 'mac': sample.mac }, fieldsIngored, function (err, data) {
        if (data.length === 0) {
            err = __addMac(sample);
        } else {
            err = __updateMac(sample, data);
        }

        if (err) {
            res.status(500).send('Internal error');
            logger.log('error', 'ERROR FINDING IN DATABASE: ' + err.message);
        } else {
            if (req.header('Accept') === 'text/csv') {
                try {
                    var CSV = __CSVResponse(data);
                    res.status(200).send(CSV);
                } catch (err) {
                    res.status(500).send('Cannot send CSV');
                    logger.info('error', err);
                }
            } else {
                res.status(200).json(data);
            }
        }
    });
}

function __findDB(query, ignore, req, res) {
    MacModel.find(query, fieldsIngored + ignore, function (err, data) {
        if (err) {
            res.status(500).send('Internal error');
            logger.log('error', 'ERROR FINDING IN DATABASE: ' + err.message);
        } else {
            data = __parseDBResponseToJSON(data);

            if (req.header('Accept') === 'text/csv') {
                try {
                    var CSV = __CSVResponse(data);
                    res.status(200).send(CSV);
                } catch (err) {
                    res.status(500).send('Cannot send CSV');
                    logger.info('error', err);
                }
            } else {
                res.status(200).json(data);
            }
        }
    });
}

function __toCSV(data) {
    var dataCSV = [];
    data.forEach(function (mac) {
        var macTemp = {
            mac: mac.mac,
            device: mac.device,
        };
        mac.origin.forEach(function (origin) {
            var macTemp = {
                mac: mac.mac,
                device: mac.device,
                ID:  origin.ID,
                time: origin.time,
                type: mac.type
            };
            dataCSV.push(macTemp);
        }, this);
    }, this);

    return dataCSV;
}

function __CSVResponse(data) {
    var to_CSV = __toCSV(data);
    return json2csv({ data: to_CSV, fields: fields });
}

module.exports = macs;
