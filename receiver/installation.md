# Installation

## Set up the Raspberry Pi

First you need to install the OS and all software needed on the Pi, and configure the network:

1. Go to the [official Raspberry Pi website](https://www.raspberrypi.org/downloads/) and download the latest image of Raspbian. Follow [this tutorial](https://www.raspberrypi.org/documentation/installation/installing-images/) to burn the image on the SD card.
2. Plug the card into the Pi, attach a screen to it using an HDMI cable, and boot it.
3. Once it has finished booting, go into `Menu>Preferences>Raspberry Pi Configuration>Interfaces`, and enable SSH. Then reboot.

## Network configuration

We will configure a laptop to have SSH connection with the Pi and provide it with Internet access. Connect an Ethernet cable to the Pi and your laptop and boot the Pi.

### On Linux

You will need to set up a new Ethernet interface using the `Shared with other computers` method for IPv4. Check your distro's doc for more information (if you use Linux, we expect you can do this all by yourself).

### On Windows
This is trickier on Windows.
Go to the Network and Sharing Center in the Control Panel.  Select your connection to the Internet and click on `Properties`. In the `Sharing` tab, check `Allow Other Network Users to Connect through This Computer’s Internet Connection` and select the Ethernet connection with your Pi. Then click `Settings` and select the corresponding profile to allow HTTP traffic (port 80). Check that box and edit that profile to specify your Pi's IP (find it using `nmap`, as it is explained next). Save and exit.

Once you have done this, your Pi should have connection with your laptop (and vice versa), and to the Internet. Now:

1. Using `nmap` and [this tutorial](https://www.raspberrypi.org/documentation/remote-access/ip-address.md), find out your Pi's IP address (it should have been automatically negotiated with your laptop).
2. SHH into it with `ssh pi@<your_pi_address>` or Putty.
3. :tada: You're in!

## Software installation

1. Update your Pi:

        sudo apt-get update
        sudo apt-get upgrade
        sudo rpi-update
Then reboot. You can check your kernel version after `rpi-update` running `uname -a`.
        
2. Install TShark with

        sudo apt-get install tshark
        sudo chgrp myusername /usr/bin/dumpcap
        sudo chmod 750 /usr/bin/dumpcap
        sudo setcap cap_net_raw,cap_net_admin+eip /usr/bin/dumpcap
and Aircrack-ng with

        sudo apt-get install aircrack-ng
        
3. Install Pyshark and some dependencies with

        sudo apt-get install libxml2-dev libxslt1-dev
        sudo apt-get install python-dev python3-dev
        sudo pip3 install lxml
        sudo pip3 install pyshark

## WiFi dongle configuration

Plug the WiFi dongle in a USB port.

1. Run `lsusb` to check if it has been detected. You should get something like this:

        pi@raspberrypi:~ $ lsusb
        Bus 001 Device 004: ID 0bda:8178 Realtek Semiconductor Corp. RTL8192CU 802.11n WLAN Adapter
        ...
The important bit is `RTL8192CU`. This is the chipset of your dongle. This project has not been tested in any other chipset.

2. Run `ifconfig` and `iwconfig` to check if a wireless interface has been created (typically named `wlan0`).

3. Check if the appropriate driver for this chipset has been loaded with `dmesg | grep 8192`:

        pi@raspberrypi:~ $ dmesg | grep 8192
        [   13.981972] usbcore: registered new interface driver rtl8192cu

4. Check if the dongle allows monitor mode with `iw list`. Look under `Supported interface modes`:

        pi@raspberrypi:~ $ iw list
        Wiphy phy0
        ...
        Supported interface modes:
        * IBSS
        * managed
        * AP
        * monitor
        * P2P-client
        * P2P-GO
        ...
If all is good until this point, the dongle is perfectly compatible.

5. Check if `wpa_supplicant` is running:

        sudo airmon-ng check
If not, start it in the background.

6. Finally! Try to put the WiFi dongle in monitor mode, run:

        sudo airmon-ng start wlan0
with `wlan0` being the name of your wireless interface. You should have a new `mon0` interface created, check with `ifconfig`.