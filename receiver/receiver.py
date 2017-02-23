#!/usr/bin/python

import sys
import pyshark
import requests
import time
import configparser

if len(sys.argv) > 1 and sys.argv[1] == 'help':
    print ('Usage: receiver.py [help]')
    print ('Config file must be placed in the same directory and named `default.conf`.')
    sys.exit()

c = configparser.ConfigParser()
c.read('default.conf')
id = c.getint('general', 'Receiver ID')
u = c.get('general', 'API URL')
p = c.get('general', 'API Port')

if c.get('general', 'Mode') == 'live':
    i = c.get('live', 'Interface')
elif c.get('general', 'Mode') == 'file':
    f = c.get('file', 'File Name')

print ('Starting WiFi sniffer...')
print ('Using interface', i)

capture = pyshark.LiveCapture(interface=i, display_filter='wlan.fc.type_subtype==4')
try:
    for packet in capture.sniff_continuously():
        m = packet.wlan.sa
        t = time.strftime("%x-%X")
        j = {"mac":m, "origin":{"id":id, "time":t}, "device":"Android"}
        requests.put('http://'+u+':'+p+'/macs', json=j)
        print (m, t)
except KeyboardInterrupt:
    print ('Shutting down...')
    sys.exit()
