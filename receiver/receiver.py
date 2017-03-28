#!/usr/bin/python3

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
interval = int(config.get('general', 'Interval'))
macList = []  # macJSON = { "mac": "mac", "seq": "seq", "time", "time"}


def getmac(packet):
    mac = packet.wlan.sa
    vendor = checkmac(mac)
    if vendor:
        send_mac(packet, mac, "fixed", vendor)
    else:
        macAsociated = asociate_mac(packet)
        if macAsociated is not None:
            send_mac(packet, macAsociated, "asociated", "Undefined")
        else:
            global macList
            add_to_list(packet)
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

def asociate_mac(packet):
    global macList
    for mac in macList:
        timePacket = datetime_to_seconds(packet)
        timePacketStored = stringtime_to_seconds(mac["time"])
        diff = (timePacket - timePacketStored).total_seconds()
        seqRecv = packet.wlan.seq
        if int(seqRecv) <= int(mac["seq"]) + interval and int(seqRecv) >= int(mac["seq"]):
            if diff < 175:
                macList.remove(mac)
                macJSON = {
                    "mac": mac["mac"],
                    "seq": packet.wlan.seq,
                    "time": datetime_to_string(packet)
                }
                macList.append(macJSON)
                return mac["mac"]
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


def clean_list():
    global macList
    for index, mac in enumerate(macList):
        timeMac = stringtime_to_seconds(mac["time"])
        now = stringtime_to_seconds(time.strftime("%Y/%m/%d-%H:%M:%S"))
        diff = (now - timeMac).total_seconds()
        if diff > 170:
            macList.remove(mac)


try:
    if mode == 'live':
        interface = config.get('live', 'Interface')
        print('Using interface', interface)
        capture = pyshark.LiveCapture(
            interface=interface, display_filter='wlan.fc.type_subtype==4')
        for packet in capture.sniff_continuously():
            getmac(packet)
            clean_list()

    elif mode == 'file':
        file = config.get('file', 'File Name')
        print('Using file', file)
        capture = pyshark.FileCapture(
            input_file='Captura_Peritos.pcapng', display_filter='wlan.fc.type_subtype==4')
        for packet in capture:
            getmac(packet)

except KeyboardInterrupt:
    print('Shutting down...')
    sys.exit()
