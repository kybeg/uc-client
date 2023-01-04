# UC Client

The UC client is a command-line tool for interacting with the "uptime
system" used in DCSG2003 at NTNU. 

# Prerequesites

* You are part of the DCSG2003 course
* You are in a group and have access to SkyHigh
* You have created a VM and are logged in
* You have downloaded the RC script file from SkyHigh

# Installation

The easiest way to install the client is by running the following
command:

curl ... | sudo sh

Test your installation the following way: 

* Run the "source" command on the RC script (unless you have set this
up to happen automatically every time you log in )

* Run the command: `uc status`


# Use

## Check the status of your group

## Register a floating IP address

You can run this command several times. Every time you run it, you
will overwrite the previous one. Please note, that it may take up to
five minutes until the new IP is being used.


## Enable / Disable traffic

This command will allow you to start the uptime challenge. Once you
enable traffic, new users, posts and comments will start to appear on
your site. Note: You need to have a floating IP registered before you
enable traffic.

Disabling traffic is not currently supported. As in real life: once
you go live, you cannot just stop the rest of the world..

