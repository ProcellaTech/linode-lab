#!/usr/bin/env python3
#  -*- coding: utf-8 -*-

# Use future for Python v2 and v3 compatibility
from __future__ import (
    absolute_import,
    division,
    print_function,
    unicode_literals,
)
from builtins import *


import os
import requests
import json
import sys
import argparse

from onepassword import OnePassword
import json




AUTH_TOKEN=""

def gc_post(PATH,JSON):
  global AUTH_TOKEN
  URL="%s%s" % (GC_URL,PATH)

  r = requests.post(URL,headers={'Content-Type' : 'application/json', 'Authorization' : 'Bearer '+AUTH_TOKEN},json=JSON)
  if r.status_code == 403:
    AUTH_TOKEN=gc_authenticate()
    r = requests.post(URL,headers={'Content-Type' : 'application/json', 'Authorization' : 'Bearer '+AUTH_TOKEN},json=JSON)

  print("{} {}".format(r.status_code,r.text))
  return r

def gc_delete(PATH,JSON):
  global AUTH_TOKEN
  URL="%s%s" % (GC_URL,PATH)

  r = requests.delete(URL,headers={'Content-Type' : 'application/json', 'Authorization' : 'Bearer '+AUTH_TOKEN},json=JSON)
  if r.status_code == 403:
    AUTH_TOKEN=gc_authenticate()
    r = requests.delete(URL,headers={'Content-Type' : 'application/json', 'Authorization' : 'Bearer '+AUTH_TOKEN},json=JSON)

  print("{} {}".format(r.status_code,r.text))
  return r

def gc_get(PATH):
  global AUTH_TOKEN
  URL="%s%s" % (GC_URL,PATH)
  r = requests.get(URL,headers={'Authorization' : 'Bearer '+AUTH_TOKEN})
  if r.status_code == 403:
    AUTH_TOKEN=gc_authenticate()
    r = requests.get(URL,headers={'Authorization' : 'Bearer '+AUTH_TOKEN})

  return r

# auth API
def gc_authenticate():
   URL="%s/authenticate" % GC_URL3
   auth_string = { "username": GC_USER, "password": GC_PASS }
   r = requests.post(URL, json=auth_string)
   if r.status_code != 200:
      sys.exit( "Error %d obtaining access token for %s" % (r.status_code,URL))
   return r.json()['access_token']


def gc_assets(host): 

  result=gc_get("/assets?status=on")

  assets=[]
  for a in result.json()['objects']:
      if a['name'] == host or a['name'] == host.replace('_','-'):
          assets.append({ 'asset_id': a['id']})

  return assets

def gc_bulk_deactivate_asset(assetids):
   result=gc_post("/assets/bulk/deactivate",assetids)

   return result

if __name__ == '__main__':

   parser = argparse.ArgumentParser(description='remove asset from GC')
   parser.add_argument('name', help='asset name eg: foo.procellab.zone')
   args = parser.parse_args()

   vault="jjkz7xwzfg67whlw2cex2tedxa" # Linode Lab vault
   api_uuid="h7tuorfhyvpkcnedz54bxtjbbu" # UUID for Guardicore API login
   
   op = OnePassword()
   
   api = op.get_item(uuid=api_uuid)
   for u in api['urls']:
     if u['primary']:
        GC_URL3 = "%s/api/v3.0" % u['href']
        GC_URL = "%s/api/v4.0" % u['href']
   
   for u in api['fields']:
     if u['id'] == 'username':
        GC_USER = u['value']
     if u['id'] == 'password':
        GC_PASS = u['value']


   assets=gc_assets(args.name)
   if len(assets) > 0:
     gc_bulk_deactivate_asset(assets)


