#!/usr/bin/python

import sys
import pyshark
import requests
import time
import configparser
import os.path
import urllib
import hashlib
import time
from datetime import datetime

if len(sys.argv) > 1 and sys.argv[1] == 'help':
    print('Usage: receiver.py [help]')
    print('Config file must be placed in the same directory and named `default.conf`.')
    sys.exit()

print('Starting WiFi sniffer...')

config = configparser.ConfigParser()
config.read('default.conf')
id = config.getint('general', 'Receiver ID')
url = config.get('general', 'API URL')
port = config.get('general', 'API Port')
mode = config.get('general', 'Mode')
macList = []  # macJSON = { "mac": "mac", "seq": "seq", "time", "time"}
INTERVAL = 5


def getmac(packet):
    mac = packet.wlan.sa

    if checkmac(mac):
        send_mac(mac, "fixed")
    else:
        macAsociated = asociate_mac(packet)
        if macAsociated is not None:
            send_mac(macAsociated, "asociated")
        else:
            send_mac(mac, "random")


def checkmac(mac):
    if not os.path.isfile("vendorDB"):
        try:
            urllib.request.urlretrieve(
                "https://code.wireshark.org/review/gitweb?p=wireshark.git;a=blob_plain;f=manuf", "vendorDB")
        except Exception:
            print("Couldn't download vendor DB, next step will fail...")
    return mac[:8].upper() in open('vendorDB').read()


def asociate_mac(packet):
    for mac in macList:
        timePacket = datetime_to_seconds(packet)
        timePacketStored = datetime_to_seconds(mac.time)
        diff = timePacket - timePacketStored
        seqRecv = packet.wlan
        if int(seqRecv) <= int(mac.seq) + INTERVAL and int(seqRecv) >= int(mac.seq):
            if diff < 175:
                macList.remove(mac)
                macJSON = {
                    "mac": mac.mac,
                    "seq": packet.wlan.seq,
                    "time": datetime_to_string(packet)
                }
                macList.append(macJSON)
                return mac.mac
    return None


def datetime_to_seconds(packet):
    timestring = packet.strftime("%d/%m/%Y %H:%M:%S")
    d = datetime.strptime(timestring, "%d/%m/%Y %H:%M:%S")
    return time.mktime(d.timetuple())


def datetime_to_string(packet):
    timestring = packet.sniff_time.strftime("%d/%m/%Y %H:%M:%S")
    return timestring


def stringtime_to_seconds(timestring):
    d = datetime.strptime(timestring, "%d/%m/%Y %H:%M:%S")
    return time.mktime(d.timetuple())


def send_mac(mac, type):
    hash = hashlib.sha256((mac + '_Dr0j4N0C0l4c40_').encode('utf-8'))
    time_ = packet.sniff_time.strftime("%Y/%m/%d-%X")
    json = {"mac": hash.hexdigest(), "origin": {"ID": id, "time": time_},
            "device": "Android", "type": type}
    requests.put('http://' + url + ':' + port + '/macs', json=json)


def clean_list():
    for mac in macList:
        timeMac = stringtime_to_seconds(mac.time)
        now = time.strftime("%d/%m/%Y %H:%M:%S")
        if(diff > 170):
            macList.remove(mac)


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
            input_file='Captura_Peritos.pcapng', display_filter='wlan.fc.type_subtype==4')
        for packet in capture:
            getmac(packet)
            clean_list()

except KeyboardInterrupt:
    print('Shutting down...')
    sys.exit()
