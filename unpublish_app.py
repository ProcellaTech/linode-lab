#!/usr/bin/env python3
#  -*- coding: utf-8 -*-


import requests
from akamai.edgegrid import EdgeGridAuth
from urllib.parse import urljoin
import argparse
import json
from onepassword import OnePassword




parser = argparse.ArgumentParser(description='publish app to EAA')
parser.add_argument('name', help='app name', nargs=1)
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


# list all apps
result = s.get(urljoin(baseurl, '/crux/v1/mgmt-pop/apps'))
for app in result.json()['objects']:
    if app['name'] == args.name[0]:
      appid=app['uuid_url']


deleteresult = s.delete(urljoin(baseurl, '/crux/v1/mgmt-pop/apps/%s' % appid))

