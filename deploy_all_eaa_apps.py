#!/usr/bin/env python3
#  -*- coding: utf-8 -*-

import sys
import requests
from akamai.edgegrid import EdgeGridAuth
from urllib.parse import urljoin
import argparse
import json
from onepassword import OnePassword
import time




parser = argparse.ArgumentParser(description='publish app to EAA')
parser.add_argument('connector', help='app connector', nargs=1)
args = parser.parse_args()


# get API credentials from 1password

vault="jjkz7xwzfg67whlw2cex2tedxa" # Linode Lab vault
api_uuid="hou7gm4kliqzdclkajkiryef4u" # UUID for Guardicore API login
   
op = OnePassword()
   
api = op.get_item(uuid=api_uuid)

for u in api['fields']:
  if u['label'] == 'url':
      baseurl = u['value']
  if u['label'] == 'client_secret':
    client_secret = u['value']
  if u['label'] == 'client_token':
    client_token = u['value']
  if u['label'] == 'access_token':
    access_token = u['value']
      

s = requests.Session()
s.auth = EdgeGridAuth(
  client_secret = client_secret,
  access_token = access_token,
  client_token = client_token
)

deploy_payload = {
  "deploy_note": "terraform deployment"
}


# first wait until connector has deployed.  Check, then wait 3 minutes, then check ever 30 seconds
result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/agents/%s' % args.connector[0]))
if result.status_code > 299:
    output = {
      "text": result.text
    }
    print(json.dumps(output))
    sys.exit()

#print(result.json())
if result.json()['state'] != 6:
    # sleep 3 min
    print("current state is %s" % result.json()['state'])
    print("sleeping 3 min")
    time.sleep(180)
    result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/agents/%s' % args.connector[0]))
    if result.json()['state'] != 6:
      print("current state is %s" % result.json()['state'])
      print("sleeping 2 min")
      time.sleep(120)
      result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/agents/%s' % args.connector[0]))
      if result.json()['state'] != 6:
        print("current state is %s" % result.json()['state'])
        print("sleeping 1 min")
        time.sleep(60)
        result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/agents/%s' % args.connector[0]))
        if result.json()['state'] != 6:
          print("current state is %s" % result.json()['state'])
          print("sleeping 1 more minute then deploying regardless")
          time.sleep(60)
          print("Yawn... hopefully that was good enough but things must be broken if it's not done now so run deploy manually if this doesn't work")

# list all apps
print("Going to deploy all apps")
result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/apps?expand=true'))
for app in result.json()['objects']:
    for conn in app['agents']:
      if conn['uuid_url'] == args.connector[0]:
          print("Deploying %s" % app['name'])
          result = s.post(urljoin(baseurl, '/crux/v1/mgmt-pop/apps/%s/deploy' % app['uuid_url']),json=deploy_payload)
          if result.status_code > 299:
              output = {
                "text": result.text
              }
              print(json.dumps(output))
              
output = {
  "text": "all done"
}
print(json.dumps(output))