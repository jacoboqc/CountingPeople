# Counting People Server

## Requirements

- MongoDB
- NodeJS 4.6

## Installation

Run the command 'npm install' in the root directory of the module.

## Configuration

The file 'config/config.js' constains the configuration of the server. The parameters are:

- dbAddres:  Contains the address of the database.
- debug:  Configure the debug level in the server. The possible leves are:
    - info
    - error
    - warn
    - debug
- port: port where the server listen.
- logFile: Turn off/on the log by file.
- logConsole: Turn off/on the log by console.
- logFilePath: path to the file on the logs are saved.

## Deployment

Run the command 'node app.js' in the root directory of the module.

## API

By default API sends response in JSON, but if the header Accept=text/csv, the response will be in CSV.


- /macs
    - GET

        Return all the macs in the database with their information.

        Response body form:

         ```JSON
        [{
            "mac": "F0:E1:D2:C3:B4:A5",
            "device": "Android",
            "origin": [
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            }
            ]
        }]
        ```

    - PUT

        Add macs to database.

        Request body form:

        ```JSON
        {
            "mac":"F0:E1:D2:C3:B4:A5",
            "origin":{
                "ID":"1",
                "time": "1995/07/29-18:30:56"
            },
            "device": "Android"
        }
        ```

- /macs/id/:id

    - GET

        Return all the macs captured by the receiver with the ID indicated in the url.

        Response body form:

        ```JSON
        [{
            "mac": "F0:E1:D2:C3:B4:A5",
            "device": "Android",
            "origin": [
            {
                "time": "1995/07/29-18:30:56"
            },
            {
                "time": "1995/07/29-18:30:56"
            },
            {
                "time": "1995/07/29-18:30:56"
            }
            ]
        }]
        ```

- /macs/device/:device

    - GET

        Return all the macs that belong to the operating system indicated in the url.

        Response body form:

        ```JSON
        [{
            "mac": "F0:E1:D2:C3:B4:A5",
            "origin": [
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            }]
        }]
        ```

- /macs/mac/:mac

    - GET

        Return all the information of the mac indicated in the url.

        Response body form:

        ```JSON
        {
        "device": "Android",
        "origin": [
            {
            "ID": 1,
            "time": "1995/07/29-18:30:56"
            },
            {
            "ID": 1,
            "time": "1995/07/29-18:30:56"
            },
            {
            "ID": 1,
            "time": "1995/07/29-18:30:56"
            }
        ]}
        ```

- /macs/interval?start='start'

    - GET

        Return all the macs captured after the time indicated in the url.

        Request form example:

        `
        http://localhost:3000/macs/interval?start=1993/01/01-22:10:30       `

        Response body form example:

        ```JSON
        [{
            "mac": "F0:E1:D2:C3:B4:A5",
            "device": "Android",
            "origin": [
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            }
            ]
        }]
        ```

- /macs/interval?end='end'

    - GET

        Return all the macs captured before the time indicated in the url.

        Request form example:

        `
        http://localhost:3000/macs/interval?end=1995/01/01-22:10:30        `

        Response body form example:

        ```JSON
        [{
            "mac": "F0:E1:D2:C3:B4:A5",
            "device": "Android",
            "origin": [
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            }
            ]
        }]
        ```

- /macs/interval?start='start'&end='end'

    - GET

        Return all the macs captured between 'start' and 'end' the time indicated in the url.

        Request form example:

        `
        http://localhost:3000/macs/interval?start=1993/01/01-22:10:30&end=1995/01/01-22:10:30        `

        Response body form example:

         ```JSON
        [{
            "mac": "F0:E1:D2:C3:B4:A5",
            "device": "Android",
            "origin": [
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            },
            {
                "ID": 1,
                "time": "1995/07/29-18:30:56"
            }
            ]
        }]
        ```
