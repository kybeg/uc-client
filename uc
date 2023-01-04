#!/usr/bin/python3

import requests
import argparse
import hashlib
import os

from colorama import Style, Fore, Back

parser = argparse.ArgumentParser(prog='uc')
subparser = parser.add_subparsers(dest='command')

status = subparser.add_parser('status')
setcommand = subparser.add_parser('set')


subparser_set = setcommand.add_subparsers()

setoptions = subparser_set.add_parser('endpoint')

parser.add_argument('-v','--verbose',dest="verbose",help='Turn verbosity on',default=False,action="store_true")
parser.add_argument('-s','--server-ip',dest="server",help="What API to connect to",default="192.168.128.23")
parser.add_argument('-p','--port',dest="port",help="What port to connect to",default="2003")

setoptions.add_argument('-i','--ip',dest="ip",help="The IP of the service to be checked")


# arg = parser.parse_args()
arg, end = parser.parse_known_args()

def verbose(text):
    if arg.verbose :
        print(text)


def getToken():
    username = os.environ.get('OS_USERNAME')
    password = os.environ.get('OS_PASSWORD')
    
    if not username or not password:
        print("Could not find authentication information. Did you source the OpenStack RC file?")
        quit(1)
    
    tokenstring = username + password
    return hashlib.md5(tokenstring.encode('UTF-8')).hexdigest()

if arg.command == 'status':
    
    token = getToken()
    endpoint = "http://" + arg.server + ":" + arg.port + "/get/me"
    verbose("executing the following url: " + endpoint)
    headers = {"Authorization": "Bearer " + token}
    print(requests.get(endpoint, headers=headers).json())

if arg.command == 'set':    
    verbose("Requesting new endpoint to be set to " + end[0] )
    token = getToken()
    headers = {"Authorization": "Bearer " + token}
    endpoint = "http://" + arg.server + ":" + arg.port + "/set/endpoint?ip=" + end[0]
    print(requests.get(endpoint, headers=headers).json())
    
    