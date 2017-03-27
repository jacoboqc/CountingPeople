var mongoose = require('mongoose'),
    Schema = mongoose.Schema;

var macs = new Schema({
    mac: String,
    origin: [{
        ID: Number,
        time: Date
    }], 
    device: String,
    type: String
});

module.exports = mongoose.model('macs', macs);