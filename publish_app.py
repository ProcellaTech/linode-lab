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
parser.add_argument('domain', help='domain name', nargs=1)
parser.add_argument('ip', help='private IP of app', nargs=1)
parser.add_argument('connector', help='which connector', nargs=1)
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


baseapp_payload =  {
  "app_profile": 1,
  "app_type": 1,
  "app_profile_id": "Fp3RYok1EeSE6AIy9YR0Dw",
  "name": args.name[0],
  "description": "%s.%s" % (args.name[0], args.domain[0])
}

app_payload = {
  "internal_hostname": "%s.%s" % (args.name[0], args.domain[0]),
  "domain": 2,
  "cname" : "accounting-linode-procellab-zone.go.akamai-access.com",
  "host" : "accounting-linode-procellab-zone",  
  "servers": [
    {
      "orig_tls": False, 
      "origin_host": args.ip[0], 
      "origin_port": 80, 
      "origin_protocol": "http"
    }
  ],
  "idp": {
    "idp_id" : "e68SQkcvRhuwqrkoglJm3g",
  }
}

connector_payload = {
  "agents": [{"uuid_url": args.connector[0]}]
}




#{"data": [{"apps": [app_moniker.uuid], "directories": scanned_directories}]}
#}


# create app
result = s.post(urljoin(baseurl, '/crux/v1/mgmt-pop/apps'),json=baseapp_payload)
appid=result.json()['uuid_url']

updateresult = s.put(urljoin(baseurl, '/crux/v1/mgmt-pop/apps/%s' % appid),json=app_payload)



# attach connectors
connresult = s.post(urljoin(baseurl, '/crux/v1/mgmt-pop/apps/%s/agents' % appid),json=connector_payload)

# attach auth (idp/directory)
idp_payload = {
  "idp" : "e68SQkcvRhuwqrkoglJm3g",
  "app": appid
}

directory_payload = {
  "data": [
  {
    "apps": [appid],
   "directories" : [
      {
        "uuid_url" : "8mLaRCbWQTmK55hWcdcCPA"
      }
   ]
  }
 ]
 } 

idpresult = s.post(urljoin(baseurl, '/crux/v1/mgmt-pop/appidp'),json=idp_payload)
dirresult = s.post(urljoin(baseurl, '/crux/v1/mgmt-pop/appdirectories'),json=directory_payload)

deploy_payload = {
  "deploy_note": "terraform deployment"
}

deployresult = s.post(urljoin(baseurl, '/crux/v1/mgmt-pop/apps/%s/deploy' % appid),json=deploy_payload)