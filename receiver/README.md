# Counting People Receiver

## Requirements

- TShark + Pyshark
- Python 3 w/ Pip
- Aircrack-ng

## Installation

Check the [Installation](Installation.md) file.

## Usage

Put your wireless interface in monitor mode:
```
sudo airmon-ng start wlan0
```
(you can turn this off with `sudo airmon-ng stop mon0`).

You will need a configuration file. There is an example in this folder.

Be sure the server is online (package `server` of this project) and run `./receiver.py`

## Configuration file

Name this file `default.conf` and put it in the same folder.

Provide the URL and port for the server, the ID of the receiver, and the working mode:

* `live`: Provide the name of your wireless interface.
* `file`: Provide the path to a capture file. There is an example in this folder.
