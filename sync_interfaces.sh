#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ];  then
    echo path required
    exit 1
fi

mkdir -p /tmp/edgehog/edgehog-updates/
mkdir -p /tmp/edgehog/store/
mkdir -p /tmp/edgehog/astarte-interfaces/
cp "$1"/*.json /tmp/edgehog/astarte-interfaces/
echo "copied interfaces on /tmp"

astartectl realm-management interfaces sync -u http://api.astarte.localhost -r test -k \
    /home/rgwork/SECOMind/repo/astarte/test_private.pem \
    "$1"/*.json
echo "sync done"
