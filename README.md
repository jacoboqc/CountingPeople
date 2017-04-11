# Counting People

This project aims to provide a simple way for counting people in big crowds, detecting the Wi-Fi signal from their personal smartphones.

## Structure

Consists of several modules:

- `receiver`: Python script for sniffing and detecting devices. Should be deployed in a Raspberry Pi.
- `server`: Node.js + MongoDB database for handling all the data fetched by the receivers. Can be deployed in a personal computer or a server in the cloud.

## Requirements

Check each module in this project for specifics. 

Or you can fetch yourself a working environment for the `server` module doing `vagrant up`. You will need to install [Vagrant](https://www.vagrantup.com/downloads.html).

___

Developed for the Lab Project subject of the Degree in Telecommunication Technologies Engineering, University of Vigo - 2016/17. More info: http://teleco.uvigo.es
