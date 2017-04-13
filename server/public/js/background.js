var series;
var series;

var timeRequest = 5000;
$(document).ready(function () {
    Highcharts.setOptions({
        global: {
            useUTC: false
        }
    });

    graphics();
});


function graphics() {
    Highcharts.stockChart('totalPeople', {
        chart: {
            type: 'spline',

            //animation: Highcharts.svg, // don't animate in old IE
            events: {
                load: function () {

                    // set up the updating of the chart each second
                    series = this.series;
                    setInterval(updateData, timeRequest);
                }
            }
        },
        title: {
            text: 'Total MACs on system vs Total MACS per origins',
            align: 'Left'
        },

        xAxis: {
            title: {
                text: 'Time',
                style: {
                    fontSize: '15px'
                }
            },
            type: 'datetime',
            tickPixelInterval: 150
        },

        yAxis: {
            title: {
                text: 'People',
                style: {
                    fontSize: '15px'
                }
            },
            plotLines: [{
                value: 0,
                width: 1,
                color: '#808080'
            }],
            min: 0,
        },

        tooltip: {
            formatter: function () {
                return '<b>' + Highcharts.dateFormat('%Y-%m-%d %H:%M:%S', this.x) + '<br/>' +
                    'Activity: ' + Highcharts.numberFormat(this.points[2].y, 0) + '<br/>' +
                    'Total people: ' + Highcharts.numberFormat(this.points[0].y, 0) + '<br/>' +
                    'Total origins: ' + Highcharts.numberFormat(this.points[1].y, 0) + '<br/>' +
                    'Percentage of People in multiple origins ' + Highcharts.numberFormat(this.points[0].y / this.points[1].y * 100, 2) + '%';
            }
        },

        series: [{
            name: 'Total people on system',
            data: []
        },
        {
            name: 'Total people on system per origin',
            data: []
        },
        {
            name: 'Activity on the system',
            data: []
        }],

        legend: {
            enabled: true
        },

        rangeSelector: {
            buttons: [{
                count: 1,
                type: 'minute',
                text: '1M'
            }, {
                count: 5,
                type: 'minute',
                text: '5M'
            }, {
                type: 'all',
                text: 'All'
            }],
            inputEnabled: false,
            selected: 0
        },
    });
}


function updateData() {
    var date = new Date();
    var x = date.getTime(); // current time
    var sec = (date.getSeconds() - (timeRequest/1000));
    if(sec < 0){
        sec = 0;
    }
    var dateRequestStart = date.getFullYear() + '/' + (date.getMonth()+1) + '/' + date.getDate() + '-' + date.getHours() + ':' + date.getMinutes() + ':' + sec;
    var dateRequestEnd = date.getFullYear() + '/' + (date.getMonth()+1) + '/' + date.getDate() + '-' + date.getHours() + ':' + date.getMinutes() + ':' + sec;

    jQuery.get('http://ec2-54-72-240-166.eu-west-1.compute.amazonaws.com:3000/macs/interval?start=' + dateRequestStart + '&end=' + dateRequestEnd, function (response) {
        //console.warn(response);
        //jQuery.get('http://localhost:3000/macs/interval?start={"time":"1993/01/01-22:10:30"}&end={"time":"2000/01/01-22:10:30"}', function (response) {
        series[2].addPoint([x, response.length], true, false);
        //series.addPoint([x, Math.random()], true, false);

    });

    jQuery.get('http://ec2-54-72-240-166.eu-west-1.compute.amazonaws.com:3000/macs', function (response) {
        series[0].addPoint([x, response.length], true, false);

        let totalOrigins = 0;
        response.forEach(function (mac) {
            totalOrigins += mac.origin.length;
        }, this);

        series[1].addPoint([x, totalOrigins], true, false);
    });
}