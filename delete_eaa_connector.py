#!/usr/bin/env python3.12
#  -*- coding: utf-8 -*-


import requests
from akamai.edgegrid import EdgeGridAuth
from urllib.parse import urljoin
import argparse
from onepassword import OnePassword



parser = argparse.ArgumentParser(description='remove connector from EAA')
parser.add_argument('name', help='connector name', nargs=1)
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

result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/agents'))

for connector in result.json()['objects']:
    if connector['name'] == args.name[0]:
        newresult=s.delete(urljoin(baseurl, '/crux/v1/mgmt-pop/agents/%s' % connector['uuid_url']))
        print(newresult)

