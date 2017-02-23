# Couting People Receiver

## Requirements

- TShark
- Python 3
- Pip
- Aircrack-ng

## Installation

TShark is the command-line version of Wireshark. It is available in nearly every platform, for example Ubuntu:
```
sudo apt-get install tshark
```
Python 3 or above is needed to run the script. Not tested in previous versions.

Pip is a package manager for Python. It usually comes with your Python distribution, if not run:
```
sudo apt-get install python-pip
```
After that, grab Pyshark (the Python wrapper for TShark) running
```
pip install pyshark
```
Finally, Airmon-ng is needed to put your wireless card in monitor mode. Run
```
sudo apt-get install aircrack-ng
```

## Usage

Put your WiFi interface in monitor mode (replace `wlan0` with yours):
```
sudo airmon-ng start wlan0
```
(you can turn this off with `sudo airmon-ng stop wlan0mon`).

You will need a configuration file. There is an example in this folder.

Be sure the server is online (package `server` of this project) and run `./receiver.py`

## Configuration file

Name this file `default.conf` and put it in the same folder.

Provide the URL and port for the server, the ID of the receiver, and the working mode:

* `live`: Provide the name of your wireless interface.
* `file`: Provide the path to a capture file. There is an example in this folder.
