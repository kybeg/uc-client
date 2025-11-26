#!/usr/bin/python3
from datetime import datetime
import requests
import argparse
import hashlib
import os
import sys
import re
import colorama
import json
from urllib.parse import quote
from requests.utils import requote_uri
from colorama import Style, Fore, Back

VERSION = 0.7

parser = argparse.ArgumentParser(prog='uc')
subparser = parser.add_subparsers(dest='command')

reports = subparser.add_parser('reports')
status = subparser.add_parser('status')
setcommand = subparser.add_parser('set')
traffic_command = subparser.add_parser('traffic')
name_command = subparser.add_parser('name')
store_command = subparser.add_parser('store')


subparser_set = setcommand.add_subparsers()
setoptions = subparser_set.add_parser('endpoint')

store_subparser = store_command.add_subparsers(dest='store_command')
store_subparser.required = True

store_list = store_subparser.add_parser('list')
store_list.add_argument('-P', '--prefix', dest='prefix', help='Filter keys that start with this prefix')

store_put = store_subparser.add_parser('put')
store_put.add_argument('key', help='Storage key')
store_put.add_argument('value', nargs='?', help='Value to store (use -f/--file for file/stdin input)')
store_put.add_argument('-f', '--file', dest='file', help='Read value from file; use "-" to read from STDIN')
store_put.add_argument('--force', action='store_true', help='Overwrite existing key if it already exists')

store_info = store_subparser.add_parser('info')
store_info.add_argument('key', help='Storage key to show metadata for')

store_get = store_subparser.add_parser('get')
store_get.add_argument('key', help='Storage key to fetch')

store_delete = store_subparser.add_parser('delete')
store_delete.add_argument('key', help='Storage key to delete')

store_eget = store_subparser.add_parser('eget')
store_eget.add_argument('key', help='Storage key to fetch with recursive expansion')
store_eget.add_argument('--strict', action='store_true', help='Fail if embedded keys are missing (default: missing keys become empty strings)')

parser.add_argument('-v','--verbose',dest="verbose",help='Turn verbosity on',default=False,action="store_true")
parser.add_argument('-s','--server-ip',dest="server",help="What API to connect to",default="192.168.128.23")
parser.add_argument('-p','--port',dest="port",help="What port to connect to",default="2003")

setoptions.add_argument('-i','--ip',dest="ip",help="The IP of the service to be checked")

colorama.init(autoreset=True)

# arg = parser.parse_args()
arg, end = parser.parse_known_args()

STORAGE_KEY_PATTERN = re.compile(r"^[A-Za-z0-9._:/-]+$")
STORAGE_MAX_KEY_LENGTH = 256
STORAGE_MAX_VALUE_BYTES = 10240

def checkVersion(version):
    if float(version) > float(VERSION):
        print(Fore.WHITE + Back.BLUE + "Warning: Outdated version of uc client. Run the following command to update:\ncurl -s https://raw.githubusercontent.com/kybeg/uc-client/main/install.sh | sudo /bin/bash")
        print()

def verbose(text):
    if arg.verbose :
        print(text)


def printResult(result):
    status = result.get("result")
    message = result.get("message", "No message provided by server.")
    if status == "OK":
        print("Response: " + Fore.GREEN + "OK" )
    elif status:
        print("Response: " + Fore.RED + status )
    else:
        print("Response: " + Fore.RED + "Unknown status")

    print(message)
        
def getToken():
    username = os.environ.get('OS_USERNAME')
    password = os.environ.get('OS_PASSWORD')
    
    if not username or not password:
        print("Could not find authentication information. Did you source the OpenStack RC file?")
        quit(1)
    
    tokenstring = username + password
    return hashlib.md5(tokenstring.encode('UTF-8')).hexdigest()

def validate_key(key):
    if len(key) > STORAGE_MAX_KEY_LENGTH or not STORAGE_KEY_PATTERN.match(key):
        print(Fore.RED + f"Invalid key '{key}'. Keys must match {STORAGE_KEY_PATTERN.pattern} and be at most {STORAGE_MAX_KEY_LENGTH} characters.")
        quit(1)

def encode_key(key):
    # Encode slashes and other reserved characters so keys never alter the API path structure.
    return quote(key, safe="")

def read_value(value, file_path):
    if file_path:
        if file_path == "-":
            return sys.stdin.read()
        if not os.path.isfile(file_path):
            print(Fore.RED + f"Could not find file: {file_path}")
            quit(1)
        with open(file_path, "r", encoding="utf-8") as f:
            return f.read()
    if value is not None:
        return value
    print(Fore.RED + "You must provide a value or use -f/--file to read the value.")
    quit(1)

def check_value_size(value):
    size = len(value.encode("utf-8"))
    if size > STORAGE_MAX_VALUE_BYTES:
        print(Fore.RED + f"Value too large ({size} bytes). Max allowed is {STORAGE_MAX_VALUE_BYTES} bytes.")
        quit(1)

def storage_request(method, path, params=None, json_body=None):
    token = getToken()
    headers = {"Authorization": "Bearer " + token}
    url = requote_uri("http://" + arg.server + ":" + arg.port + path)
    verbose(f"{method.upper()} {url} params={params} body={json_body}")
    response = requests.request(method, url, headers=headers, params=params, json=json_body)
    if response.status_code == 401:
        print(Fore.RED + "Authentication failed. This might be because your group is not registered yet, or you did not source the OpenStack RC file.")
        quit(1)
    try:
        data = response.json()
    except ValueError:
        print(Fore.RED + "Unexpected response from server (status " + str(response.status_code) + ").")
        verbose(response.text)
        quit(1)
    return response, data

if arg.command == 'status':
    
    token = getToken()
    endpoint = "http://" + arg.server + ":" + arg.port + "/get/me"
    verbose("executing the following url: " + endpoint)
    headers = {"Authorization": "Bearer " + token}
    response = requests.get(endpoint, headers=headers)
    if response.status_code == 401:
        print(Fore.RED + "Authentication failed. This might be because your group is not registered yet, or you did not source the OpenStack RC file.")
        quit(1)
    try:
        result = response.json()
    except ValueError:
        print(Fore.RED + "Unexpected response from server (status " + str(response.status_code) + ").")
        verbose(response.text)
        quit(1)
#    verbose("Result: " + str(result))
    if "result" not in result:
        print(Fore.RED + "Unexpected response from server (missing 'result' field).")
        verbose(str(result))
        quit(1)
    if "preferred_client" in result:
        checkVersion(result["preferred_client"])
    if result["result"] == "OK":
#        print(result)
        print(Fore.CYAN + "UPTIME CHALLENGE")
        print(Fore.CYAN + "----------------")
        print("Service provider: " + Fore.YELLOW + result["name"])
        print("Service endpoint: " + Fore.YELLOW + result["service_endpoint"])
        print("Balance: " + Fore.YELLOW + result["balance"] + " KC")
        enabled = Fore.RED + "no"
        if result["enabled"] == "yes":
            enabled = Fore.GREEN + "yes"
        print("Enabled: " + enabled)
        if "last_check" in  result:
            check_result = Fore.RED + "DOWN"

            if result["last_check"]["text_found"] == 1:
                check_result = Fore.GREEN + "UP"
                
            timestamp = datetime.fromtimestamp(result["last_check"]["check_time"]).strftime('%Y-%m-%d %H:%M:%S')
            print ("Last check @" + timestamp +": " + check_result )
#            print ("Download time: " + str(result["last_check"]["time_to_download"]) + " seconds")
            reward_color = Fore.RED
            if "calculated_reward" in result["last_check"]:
                if  result["last_check"]["calculated_reward"] > 0:
                    reward_color = Fore.GREEN
                print ("Kyrrecoins earned: " + reward_color + str(result["last_check"]["calculated_reward"]))
            print (Fore.MAGENTA + "Report: ")
            print(result["last_check"]["result"])
    else:
        printResult(result)

if arg.command == 'store':
    if arg.store_command == 'list':
        params = {}
        if arg.prefix:
            params["prefix"] = arg.prefix
        response, data = storage_request("get", "/storage", params=params or None)
        if data.get("result") != "OK":
            printResult(data)
            quit(1)
        items = data.get("items", [])
        if not items:
            print("No stored items found.")
        else:
            print(Fore.CYAN + "Stored items:")
            for item in items:
                updated = item.get("updated_at") or item.get("created_at") or "unknown"
                size = item.get("size_bytes", 0)
                print(f"{item.get('key')}: {size} bytes (updated {updated})")
        print("Count: " + str(data.get("count", len(items))))

    if arg.store_command == 'info':
        validate_key(arg.key)
        encoded_key = encode_key(arg.key)
        response, data = storage_request("get", "/storage/" + encoded_key)
        if response.status_code == 404:
            print(Fore.RED + f"Key '{arg.key}' not found.")
            quit(1)
        if data.get("result") != "OK":
            printResult(data)
            quit(1)
        print(json.dumps(data.get("item", {}), indent=2))

    if arg.store_command == 'get':
        validate_key(arg.key)
        encoded_key = encode_key(arg.key)
        response, data = storage_request("get", "/storage/" + encoded_key)
        if response.status_code == 404:
            print(Fore.RED + f"Key '{arg.key}' not found.")
            quit(1)
        if data.get("result") != "OK":
            printResult(data)
            quit(1)
        item = data.get("item", {})
        print(item.get("value", ""))

    if arg.store_command == 'eget':
        validate_key(arg.key)
        encoded_key = encode_key(arg.key)
        params = {"strict": str(arg.strict).lower()}
        response, data = storage_request("get", "/storage/eget/" + encoded_key, params=params)
        if response.status_code == 404:
            print(Fore.RED + f"Key '{arg.key}' not found.")
            quit(1)
        if data.get("result") != "OK":
            printResult(data)
            quit(1)
        item = data.get("item", {})
        print(item.get("value", ""))

    if arg.store_command == 'put':
        validate_key(arg.key)
        value = read_value(arg.value, arg.file)
        check_value_size(value)
        params = {"force": str(arg.force).lower()}
        encoded_key = encode_key(arg.key)
        response, data = storage_request("post", "/storage/" + encoded_key, params=params, json_body={"value": value})
        if response.status_code == 409:
            print(Fore.RED + f"Key '{arg.key}' already exists. Use --force to overwrite.")
            quit(1)
        if response.status_code == 413:
            print(Fore.RED + "Value too large for storage.")
            quit(1)
        if data.get("result") != "OK":
            printResult(data)
            quit(1)
        action = data.get("action", "created")
        size = data.get("size_bytes", len(value.encode("utf-8")))
        updated = data.get("updated_at", "")
        print(Fore.GREEN + f"{action.title()} key '{arg.key}' ({size} bytes). Updated at {updated}.")

    if arg.store_command == 'delete':
        validate_key(arg.key)
        encoded_key = encode_key(arg.key)
        response, data = storage_request("delete", "/storage/" + encoded_key)
        if response.status_code == 404:
            print(Fore.RED + f"Key '{arg.key}' not found.")
            quit(1)
        if data.get("result") != "OK":
            printResult(data)
            quit(1)
        print(Fore.GREEN + f"Deleted key '{arg.key}'.")

if arg.command == 'set':    
    verbose("Requesting new endpoint to be set to " + end[0] )
    token = getToken()
    headers = {"Authorization": "Bearer " + token}
    endpoint = "http://" + arg.server + ":" + arg.port + "/set/endpoint?ip=" + end[0]
    printResult(requests.get(endpoint, headers=headers).json())

if arg.command == 'traffic':    
    verbose("Traffic is set to " + end[0] )
    token = getToken()
    headers = {"Authorization": "Bearer " + token}
    endpoint = "http://" + arg.server + ":" + arg.port + "/set/traffic?state=" + end[0]
    printResult(requests.get(endpoint, headers=headers).json())

if arg.command == 'reports':    
    verbose("Fetching reports...")
    token = getToken()
    headers = {"Authorization": "Bearer " + token}
    endpoint = "http://" + arg.server + ":" + arg.port + "/get/reports"
    print(requests.get(endpoint, headers=headers).json())

if arg.command == 'name':    
    if input("The name can only be set one time. Are you sure you want to set the name to " + end[0] + "?\n (y/n)") != "y":
        exit()
    verbose("Name is set to " + end[0] )
    token = getToken()
    headers = {"Authorization": "Bearer " + token}
    endpoint = "http://" + arg.server + ":" + arg.port + "/set/name?name=" + end[0]
    printResult(requests.get(endpoint, headers=headers).json())

    
