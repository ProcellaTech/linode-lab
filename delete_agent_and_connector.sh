#!/bin/sh

DIR=$(dirname $0)

$($DIR/delete_agent.py $1)
$($DIR/delete_eaa_connector.py $1)
exit 0
