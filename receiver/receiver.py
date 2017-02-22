import sys
import pyshark
import requests
import time

if len(sys.argv) == 1:
    print ('Usage: python receiver.py interface')
    sys.exit()

print ('Starting WiFi sniffer...')
intSniff = sys.argv[1]
print ('Using interface', intSniff)

capture = pyshark.LiveCapture(interface=intSniff, display_filter='wlan.fc.type_subtype==4')
try:
    for packet in capture.sniff_continuously():
        m = packet.wlan.sa
        t = time.strftime("%x-%X")
        j = {"mac":m, "origin":{"id":1, "time":t}, "device":"Android"}
        requests.put('http://localhost:3001/macs', json=j)
        print (m, t)
except KeyboardInterrupt:
    print ('Shutting down...')
    sys.exit()
