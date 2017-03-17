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
i = int(0)
almacenadas = int(0)
wps = int(0)
fabricante = int(0)
asociada = int(0)
noEnviada = int(0)
packetList = []
macList = []
INTERVAL = 5


def getmac(packet):
    mac = packet.wlan.sa
    global almacenadas
    global wps
    global fabricante
    global asociada
    global noEnviada
    alreadyStored = False
    for packetStored in packetList:
        if packet.wlan.sa == packetStored.wlan.sa:
            packetList.remove(packetStored)
            packetList.append(packet)
            alreadyStored = True
            break
    try:
        mac_asociated = asociate_secuence(packet)
        if alreadyStored is True:
            almacenadas += 1
            hash = hashlib.sha256((mac + '_Dr0j4N0C0l4c40_').encode('utf-8'))
            time_ = time.strftime("%Y/%m/%d-%X")
            json = {"mac": hash.hexdigest(), "origin": {"ID": id, "time": time_},
                    "device": "Android"}
            requests.put('http://' + url + ':' + port + '/macs', json=json)
            return

        elif checkmac(mac):
            packetList.append(packet)
            fabricante += 1
            hash = hashlib.sha256((mac + '_Dr0j4N0C0l4c40_').encode('utf-8'))
            time_ = time.strftime("%Y/%m/%d-%X")
            json = {"mac": hash.hexdigest(), "origin": {"ID": id, "time": time_},
                    "device": "Android"}
            requests.put('http://' + url + ':' + port + '/macs', json=json)
            return
        
        elif mac_asociated is not None:
            asociada += 1
            print("MAC capturada ", mac, " MAC asociada ", mac_asociated)
            hash = hashlib.sha256(
                (mac_asociated + '_Dr0j4N0C0l4c40_').encode('utf-8'))
            time_ = time.strftime("%Y/%m/%d-%X")
            json = {"mac": hash.hexdigest(), "origin": {"ID": id, "time": time_},
                    "device": "Android"}
            requests.put('http://' + url + ':' + port + '/macs', json=json)
            return
        elif packet.wlan_mgt.wps_uuid_e:
            packetList.append(packet)
            wps += 1
            print(wps)
            hash = hashlib.sha256(
                (mac + '_Dr0j4N0C0l4c40_').encode('utf-8'))
            time_ = time.strftime("%Y/%m/%d-%X")
            json = {"mac": hash.hexdigest(), "origin": {"ID": id, "time": time_},
                    "device": "Android"}
            requests.put('http://' + url + ':' + port + '/macs', json=json)
            return
    except:
        packetList.append(packet)
        noEnviada += 1 
    

def checkmac(mac):
    if not os.path.isfile("vendorDB"):
        try:
            urllib.request.urlretrieve(
                "https://code.wireshark.org/review/gitweb?p=wireshark.git;a=blob_plain;f=manuf", "vendorDB")
        except Exception:
            print("Couldn't download vendor DB, next step will fail...")
    return mac[:8].upper() in open('vendorDB').read()


def asociate_secuence(packet):
    for packetStored in packetList:

        timePacket = datetime_to_seconds(packet)
        timePacketStored = datetime_to_seconds(packetStored)
        diff = timePacket - timePacketStored

        if int(packet.wlan.seq) <= int(packetStored.wlan.seq) + INTERVAL and int(packet.wlan.seq) >= int(packetStored.wlan.seq):
            if diff < 175  and diff >= 0: 
                packetList.remove(packetStored)
                packetList.append(packet)
                return packetStored.wlan.sa
    return None

def datetime_to_seconds(packet):
    timestring = packet.sniff_time.strftime("%d/%m/%Y %H:%M:%S")
    d = datetime.strptime(timestring, "%d/%m/%Y %H:%M:%S")
    return time.mktime(d.timetuple())

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
        capture = pyshark.FileCapture(input_file='Captura_Peritos.pcapng', display_filter='wlan.fc.type_subtype==4')
        for packet in capture:
            getmac(packet)
    
    print("ALMACENADAS: ", almacenadas)
    print("WPS: ", wps)
    print("FABRICANTE: ", fabricante)
    print("ASOCIADAS: ", asociada)
    print("NO ENVIADAS: ", noEnviada)

except KeyboardInterrupt:
    print('Shutting down...')
    sys.exit()
