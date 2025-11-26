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

```curl -s https://raw.githubusercontent.com/kybeg/uc-client/main/install.sh | sudo /bin/bash```

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

# Storage key/value

The API now supports per-user key/value storage. Keys must match
`^[A-Za-z0-9._:/-]+$` and are limited to 256 chars; values are limited
to 10 KiB. Slashes are allowed in keys (they are treated as literal
characters on the server).

## Basic commands

- List keys (optionally by prefix): `uc store list --prefix app/`
- Write or overwrite: `uc store put my/key "some value"` or
  `uc store put my/key -f file.txt` or `uc store put my/key -f -` to
  read from STDIN. Add `--force` to overwrite existing keys.
- Fetch value: `uc store get my/key`
- Show metadata: `uc store info my/key`
- Delete: `uc store delete my/key`
- Expanded fetch (expands embedded placeholders):  
  `uc store eget my/key` (add `--strict` to fail if a nested key is
  missing)

## Example with embedded values

```
uc store put db1/ip 10.10.10.1
uc store put curl_command "curl http://{db1/ip}/index.html"
uc store get curl_command
curl http://{db1/ip}/index.html
uc store eget curl_command
curl http://10.10.10.1/index.html
```

`uc store eget` performs server-side recursive expansion of
`{some/key}` placeholders (up to the server’s depth limit), letting you
template commands or configuration snippets from stored values.
