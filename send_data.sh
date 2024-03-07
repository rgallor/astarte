#!/usr/bin/env bash

set -eEuo pipefail

TOKEN="eyJhbGciOiJFUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3MTAyNjc0MTcsImlhdCI6MTcxMDIzODYxNywiYV9hZWEiOlsiLio6Oi4qIl0sImFfY2giOlsiSk9JTjo6LioiLCJXQVRDSDo6LioiXSwiYV9mIjpbIi4qOjouKiJdLCJhX3JtYSI6WyIuKjo6LioiXSwiYV9wYSI6WyIuKjo6LioiXX0.SFisZyFxtscoWptKxiwz9cyI24hywSZ6STHoS4Hz5XOD6ycNEm801hq4NR7L-doOOXltQZiBMkrWPrYaN_jduA"
ASTARTE_BASE_URL='api.astarte.localhost'
REALM='test'
DEVICE_ID='2TBn-jNESuuHamE2Zo1anA'
INTERFACE='io.edgehog.devicemanager.ForwarderSessionRequest'
INT_PATH="/request"

#DATA='{"session_token":"abcd","port":4000,"host":"localhost"}'
#DATA='{"session_token":"abcd","port":80,"host":"forwarder.astarte.localhost", "secure": false}'
DATA='{"session_token":"abcd","port":443,"host":"forwarder.astarte.localhost", "secure": true}'


curl -v -X POST -H "Accept: application/json" -H "Content-Type: application/json" \
    -H "User-Agent: astarte-go" \
    -H "Authorization: Bearer $TOKEN" \
    --data "{\"data\":$DATA}" \
    "http://$ASTARTE_BASE_URL/appengine/v1/$REALM/devices/$DEVICE_ID/interfaces/$INTERFACE/$INT_PATH"
