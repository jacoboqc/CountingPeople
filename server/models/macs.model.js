var mongoose = require('mongoose'),
    Schema = mongoose.Schema;

var macs = new Schema({
    mac: String,
    origin: [{
        ID: Number,
        time: Date
    }], 
    device: String,
    random: Boolean
});

module.exports = mongoose.model('macs', macs);