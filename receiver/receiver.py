#!/usr/bin/python3
import sys
import pyshark
import requests
import time
import configparser
import os.path
import urllib
import hashlib
from datetime import datetime

if len(sys.argv) == 1 or (len(sys.argv) > 1 and sys.argv[1] == 'help'):
    print('Usage: receiver.py {start|full|help}')
    print('\tOptions:')
    print('\t\tstart:\tOnly start receiver')
    print('\t\tfull:\tPerform initial tasks and start receiver')
    print('\t\thelp:\tShow this help')
    print('Config file must be placed in the same directory and named `default.conf`.')
    sys.exit()

print('Starting WiFi sniffer...')

config = configparser.ConfigParser()
config.read('default.conf')
id = config.getint('general', 'Receiver ID')
url = config.get('general', 'API URL')
port = config.get('general', 'API Port')
mode = config.get('general', 'Mode')
interval = int(config.get('general', 'Interval'))

if len(sys.argv) > 1 and sys.argv[1] == 'full':
    print('Performing initial tasks:')
    os.system('sudo airmon-ng start wlan0')
    time.sleep(5)

macList = []  # macJSON = { "mac": "mac", "seq": "seq", "time", "time"}


def getmac(packet):
    mac = packet.wlan.sa
    vendor = checkmac(mac)
    if vendor:
        send_mac(packet, mac, "fixed", vendor)
    else:
        send_mac(packet, mac, "random", "Undefined")


def checkmac(mac):
    if not os.path.isfile("vendorDB"):
        try:
            urllib.request.urlretrieve(
                "https://code.wireshark.org/review/gitweb?p=wireshark.git;a=blob_plain;f=manuf", "vendorDB")
        except Exception:
            print("Couldn't download vendor DB, next step will fail...")
    with open('vendorDB') as f:
        lines = f.read().splitlines()
        for line in lines:
                split = line.split()
                if split and mac.upper().startswith(split[0]):
                        return split[1]
        return None


def datetime_to_seconds(packet):
    timestring = packet.sniff_time.strftime("%Y/%m/%d-%H:%M:%S")
    return datetime.strptime(timestring, "%Y/%m/%d-%H:%M:%S")


def datetime_to_string(packet):
    timestring = packet.sniff_time.strftime("%Y/%m/%d-%H:%M:%S")
    return timestring


def stringtime_to_seconds(timestring):
    return datetime.strptime(timestring, "%Y/%m/%d-%H:%M:%S")


def send_mac(packet, mac, type, vendor):
    hash = hashlib.sha256((mac + '_Dr0j4N0C0l4c40_').encode('utf-8'))
    time_ = packet.sniff_time.strftime("%Y/%m/%d-%H:%M:%S")
    json = {"mac": hash.hexdigest(), "origin": {"ID": id, "time": time_},
            "device": vendor, "type": type}
    requests.put('http://' + url + ':' + port + '/macs', json=json)


def add_to_list(packet):
    macJSON = {
        "mac": packet.wlan.sa,
        "seq": packet.wlan.seq,
        "time": packet.sniff_time.strftime("%Y/%m/%d-%H:%M:%S")
    }
    global macList
    macList.append(macJSON)


try:
    if mode == 'live':
        interface = config.get('live', 'Interface')
        print('Using interface', interface)
        capture = pyshark.LiveCapture(
            interface=interface, display_filter='wlan.fc.type_subtype==4')
        for packet in capture.sniff_continuously():
            getmac(packet)

    elif mode == 'file':
        file = config.get('file', 'File Name')
        print('Using file', file)
        capture = pyshark.FileCapture(
            input_file=file, display_filter='wlan.fc.type_subtype==4')
        for packet in capture:
            getmac(packet)

except KeyboardInterrupt:
    print('Shutting down...')
    sys.exit()
