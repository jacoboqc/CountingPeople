var series;
var timeRequest = 1000;
$(document).ready(function () {
    Highcharts.setOptions({
        global: {
            useUTC: false
        }
    });

    Highcharts.stockChart('container', {
        chart: {
            type: 'spline',

            //animation: Highcharts.svg, // don't animate in old IE
            events: {
                load: function () {

                    // set up the updating of the chart each second
                    series = this.series[0];
                    setInterval(updateData, timeRequest);
                }
            }
        },
        title: {
            text: 'Counting People'
        },

        subtitle: {
            text: 'People activity in the system in real time'
        },

        xAxis: {
            title: {
                text: 'Time',
                style: {
                    fontSize:'15px'
                }
            },
            type: 'datetime',
            tickPixelInterval: 150
        },

        yAxis: {
            title: {
                text: 'People',
                style: {
                    fontSize:'15px'
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
                    'People: ' + Highcharts.numberFormat(this.y, 0);
            }
        },

        series: [{
            name: 'People',
            data: []
        }],

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
});


function updateData() {
    var date = new Date();
    var x = date.getTime(); // current time
    var dateRequestStart = date.getFullYear + '/' + date.getMonth + '/' + date.getDay + '-' + date.getHours + ':' + date.getMinutes + ':' + (date.getSeconds - timeRequest);
    var dateRequestEnd = date.getFullYear + '/' + date.getMonth + '/' + date.getDay + '-' + date.getHours + ':' + date.getMinutes + ':' + date.getSeconds;


    jQuery.get('http://localhost:3000/macs/interval?start={"time":"' + dateRequestStart + '"}&end={"time":"' + dateRequestEnd + '"}', function (response) {
        //jQuery.get('http://localhost:3000/macs/interval?start={"time":"1993/01/01-22:10:30"}&end={"time":"2000/01/01-22:10:30"}', function (response) {
        //series.addPoint([x, response.length], true, false);
        series.addPoint([x, Math.random()], true, false);

    });
}