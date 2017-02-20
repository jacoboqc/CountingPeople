import sys
import pyshark
import requests
import json
from mac import Mac

if len(sys.argv) == 1:
    print ('Usage: python sniffer.py interface')
    sys.exit()

print ('Starting WiFi sniffer...')
intSniff = sys.argv[1]
print ('Using interface', intSniff)

capture = pyshark.LiveCapture(interface=intSniff, display_filter='wlan.fc.type_subtype==4')
try:
    for packet in capture.sniff_continuously():
        mac = Mac(packet.wlan.sa)
        requests.post('localhost:3000/macs', data={json.dumps(mac.__dict__)})
        print (mac.mac, mac.time)
except KeyboardInterrupt:
    print ('Shutting down...')
    sys.exit()
