var MacModel = db.model('macs');
var logger = require('../logger.js');
var macs = {};
var fieldsIngored = '-__v -_id -origin._id';

macs.getAll = function (req, res) {
    MacModel.find({}, fieldsIngored, function (err, data) {
        if (err) {
            res.status(500).send(err.message);
            logger.log('error', err.message);
        } else {
            data = __parseDBResponseToJSON(data);
            res.status(200).json(data);
        }
    });
};

macs.addMacs = function (req, res) {
    var operationError = false;

    req.body.forEach(function (item) {
        var sample = {
            mac: item.mac,
            origin: [{
                ID: item.origin.ID,
                time: new Date(item.origin.time.year, item.origin.time.month, item.origin.time.day, item.origin.time.hour, item.origin.time.minutes, item.origin.time.seconds)
            }],
            device: item.device
        };

        MacModel.find({ 'mac': sample.mac }, fieldsIngored, function (err, data) {
            if (data.length === 0) {
                err = __addMac(sample);
            } else if (data.length !== 0) {
                err = __updateMac(sample, data);
            }

            if (err) {
                operationError = true;
                res.status(500).send(err.message);
            }
        });
    });

    if (operationError === false) {
        res.status(200).send('All data saved correctly');
    }
};

macs.findByID = function (req, res) {
    var id = req.params.id;

    MacModel.find({ 'origin.ID': id }, fieldsIngored + ' -origin.ID', function (err, data) {
        if (err) {
            res.status(500).send(err.message);
            logger.log('error', err.message);
        } else {
            data = __parseDBResponseToJSON(data);
            res.status(200).json(data);
        }
    });
};

macs.findByDevice = function (req, res) {
    var device = req.params.device;

    MacModel.find({ 'device': device }, fieldsIngored + ' -device', function (err, data) {
        if (err) {
            res.status(500).send(err.message);
            logger.log('error', err.message);
        } else {
            data = __parseDBResponseToJSON(data);
            res.status(200).json(data);
        }
    });
};

macs.findMac = function (req, res) {
    var mac = req.params.mac;

    MacModel.find({ 'mac': mac }, fieldsIngored + ' -mac', function (err, data) {
        if (err) {
            res.status(500).send(err.message);
            logger.log('error', err.message);
        } else {
            data = __parseDBResponseToJSON(data);
            res.status(200).json(data[0]);
        }
    });
};

macs.findBeforeEnd = function (end, res) {
    end = _dateStringToJSON(end);

    if (end === null) {
        logger.log('error', 'End empty');
        res.status(500).send('End empty');
    } else {
        var endDate = new Date(end.year, end.month, end.day, end.hour, end.minutes, end.seconds);

        MacModel.find({ 'origin.time': { $lte: endDate } }, fieldsIngored, function (err, data) {
            if (err) {
                res.status(500).send(err.message);
                logger.log('error', err.message);
            } else {
                data = __parseDBResponseToJSON(data);
                res.status(200).json(data);
            }
        });
    }
};

macs.findAfterStart = function (start, res) {
    start = _dateStringToJSON(start);

    if (start === null) {
        logger.log('error', 'Start empty');
        res.status(500).send('Start empty');
    } else {
        var startDate = new Date(start.year, start.month, start.day, start.hour, start.minutes, start.seconds);
        MacModel.find({ 'origin.time': { $gte: startDate } }, fieldsIngored, function (err, data) {
            if (err) {
                res.status(500).send(err.message);
                logger.log('error', err.message);
            } else {
                data = __parseDBResponseToJSON(data);
                res.status(200).json(data);
            }
        });
    }
};

macs.findByInterval = function (start, end, res) {
    start = _dateStringToJSON(start);
    end = _dateStringToJSON(end);
    if (start === null || end === null) {
        logger.log('error', 'Start/End empty');
        res.status(500).send('Start/End empty');
    } else {
        var startDate = new Date(start.year, start.month, start.day, start.hour, start.minutes, start.seconds);
        var endDate = new Date(end.year, end.month, end.day, end.hour, end.minutes, end.seconds);

        MacModel.find({ 'origin.time': { $gte: startDate, $lte: endDate } }, fieldsIngored, function (err, data) {
            if (err) {
                res.status(500).send(err.message);
                logger.log('error', err.message);
            } else {
                data = __parseDBResponseToJSON(data);
                res.status(200).json(data);
            }
        });
    }
};

function _dateStringToJSON(dateString) {
    var dateSplit = JSON.parse(dateString).time.split('-');
    var date = dateSplit[0].split('/');
    var hour = dateSplit[1].split(':');

    if (date.length !== 3 && hour.length !== 3) return null;

    return {
        year: date[0],
        month: date[1],
        day: date[2],
        hour: hour[0],
        minutes: hour[1],
        seconds: hour[2]
    };
}

function __dateStringFormat(dateISO) {
    var dateSplit = dateISO.toISOString().replace('Z', '').split('T');
    var date = dateSplit[0].split('-');
    var hour = dateSplit[1].split(':');

    if (date.length !== 3 && hour.length !== 3) {
        logger.log('error', 'Cannot parse date in request');
        return null;
    }
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

module.exports = macs;