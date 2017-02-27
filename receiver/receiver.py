#!/usr/bin/python

import sys
import pyshark
import requests
import time
import configparser
import hashlib

if len(sys.argv) > 1 and sys.argv[1] == 'help':
    print ('Usage: receiver.py [help]')
    print ('Config file must be placed in the same directory and named `default.conf`.')
    sys.exit()

print ('Starting WiFi sniffer...')

config = configparser.ConfigParser()
config.read('default.conf')
id = config.getint('general', 'Receiver ID')
url = config.get('general', 'API URL')
port = config.get('general', 'API Port')
mode = config.get('general', 'Mode')

def getmac(packet):
    mac = packet.wlan.sa
    hash = hashlib.sha256(mac.encode('utf-8'))
    time_ = time.strftime("%x-%X")
    json = {"mac":hash.hexdigest(), "origin":{"id":id, "time":time_}, "device":"Android"}
    requests.put('http://'+url+':'+port+'/macs', json=json)
    print (mac, hash.hexdigest(), time_)

try:
    if mode == 'live':
        interface = config.get('live', 'Interface')
        print ('Using interface', interface)
        capture = pyshark.LiveCapture(interface=interface, display_filter='wlan.fc.type_subtype==4')
        for packet in capture.sniff_continuously():
            getmac(packet)
    elif mode == 'file':
        file = config.get('file', 'File Name')
        print ('Using file', file)
        capture = pyshark.FileCapture(input_file=file, display_filter='wlan.fc.type_subtype==4')
        for packet in capture:
            getmac(packet)
except KeyboardInterrupt:
        print ('Shutting down...')
        sys.exit()
