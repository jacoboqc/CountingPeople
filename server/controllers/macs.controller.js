var json2csv = require('json2csv');
var fs = require('fs');
var MacModel = db.model('macs');
var logger = require('../logger.js');
var macs = {};
var fieldsIngored = '-__v -_id -origin._id';
var macRegex = '[A-Fa-f0-9]{64}';
var fields = ['mac','device','ID','time'];

macs.getAll = function (req, res) {
    MacModel.find({}, fieldsIngored, function (err, data) {
        if (err) {
            res.status(500).send('Internal error');
            logger.log('error', 'ERROR FINDING IN DATABASE: ' + err.message);
        } else {
            data = __parseDBResponseToJSON(data);
            if (req.header('Accept') === 'text/csv') {
                try {
                    var to_CSV = __toCSV(data);
                    var CSV = json2csv({ data: to_CSV, fields: fields });
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
            time: _dateStringDate(req.body.origin.time)
        }],
        device: req.body.device
    };

    try {
        if (Object.prototype.toString.call(_dateStringDate(req.body.origin.time)) !== '[object Date]') {
            res.status(400).send('Invalid date');
            logger.log('error', 'Invalid date');
        } else if (typeof sample.mac !== 'string' || !sample.mac.match(macRegex)) {
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
        if (typeof mac === 'string' && mac.match(macRegex)) {
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
    end = _dateStringToJSON(end);

    if (end === null) {
        logger.log('error', 'End empty');
        res.status(400).send('End empty');
    } else {
        var endDate = new Date(end.year, end.month, end.day, end.hour, end.minutes, end.seconds);

        if (Object.prototype.toString.call(endDate) !== '[object Date]') {
            logger.log('error', 'Invalid Date');
            res.status(400).send('Invalid Date');
        } else {
            __findDB({ 'origin.time': { $lte: endDate } }, '', req, res);
        }
    }
};

macs.findAfterStart = function (start, req, res) {
    start = _dateStringToJSON(start);

    if (start === null) {
        logger.log('error', 'Start empty');
        res.status(400).send('Start empty');
    } else {
        var startDate = new Date(start.year, start.month, start.day, start.hour, start.minutes, start.seconds);

        if (Object.prototype.toString.call(startDate) !== '[object Date]') {
            logger.log('error', 'Invalid Date');
            res.status(400).send('Invalid Date');
        } else {
            __findDB({ 'origin.time': { $gte: startDate } }, '', req, res);
        }
    }
};

macs.findByInterval = function (start, end, req, res) {
    start = _dateStringToJSON(start);
    end = _dateStringToJSON(end);
    if (start === null || end === null) {
        logger.log('error', 'Start/End empty or cannot parse');
        res.status(400).send('Start/End empty or cannot parse');
    } else {

        var startDate = new Date(start.year, start.month, start.day, start.hour, start.minutes, start.seconds);
        var endDate = new Date(end.year, end.month, end.day, end.hour, end.minutes, end.seconds);

        if (Object.prototype.toString.call(startDate) !== '[object Date]' || Object.prototype.toString.call(endDate) !== '[object Date]') {
            logger.log('error', 'Invalid Date');
            res.status(400).send('Invalid Date');
        } else {
            __findDB({ 'origin.time': { $gte: startDate, $lte: endDate } }, '', req, res);
        }
    }
};

function _dateStringToJSON(dateString) {
    var dateSplit, date, hour;

    try {
        dateSplit = JSON.parse(dateString).time.split('-');
        date = dateSplit[0].split('/');
        hour = dateSplit[1].split(':');

    } catch (err) {
        logger.log('error', err);
        return null;
    }

    if (date.length !== 3 && hour.length !== 3) return null;

    a= {
        year: date[0],
        month: date[1],
        day: date[2],
        hour: hour[0],
        minutes: hour[1],
        seconds: hour[2]
    };
	logger.log('debug', 'here are the dates: ' + JSON.stringify(a));
    return a;
}

function _dateStringDate(dateString) {
    var dateSplit, date, hour;
    try {
        dateSplit = dateString.split('-');
        if (dateSplit.length !== 2) return null;

        date = dateSplit[0].split('/');
        hour = dateSplit[1].split(':');
    } catch (err) {
        logger.log('error', err);
        return null;
    }

    if (date.length !== 3 && hour.length !== 3) return null;

    return new Date(date[0], date[1], date[2], hour[0], hour[1], hour[2]);
}


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
                    var to_CSV = __toCSV(data);
                    var CSV = json2csv({ data: to_CSV , fields: fields});
                    res.status(200).send(CSV);
                } catch (err) {
                    res.status(500).send('Cannot send CSV');
                    logger.info('error', err);
                }
            } else {
                res.status(200).json(data);
            }
            res.status(200).send('All data saved correctly');
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
                    var to_CSV = __toCSV(data);
                    var CSV = json2csv({ data: to_CSV , fields: fields});
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
            console.log(origin);
            macTemp.ID = origin.ID;
            macTemp.time = origin.time;
            dataCSV.push(macTemp);
        }, this);
    }, this);

    return dataCSV;
}

module.exports = macs;
