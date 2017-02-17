import sys
import pyshark

if len(sys.argv) == 1:
    print ('Usage: sniffer.py interface')
    sys.exit()

print ('Starting WiFi sniffer...')
intSniff = sys.argv[1]
print ('Using interface', intSniff)

macsList = list()

capture = pyshark.LiveCapture(interface=intSniff, display_filter='wlan.fc.type_subtype==4')
try:
    for packet in capture.sniff_continuously():
        mac = packet.wlan.sa
        if mac not in macsList:
            macsList.append(mac)
            print ('New device detected:', mac)
except KeyboardInterrupt:
    print ('Shutting down...')
    sys.exit()
