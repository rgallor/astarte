#!/usr/bin/env bash

set -eEuo pipefail

ASTARTE_API=""

p=''

function prompt() {
    read -rp "$1 (y/n) " p

    if [ "$p" == "y" ]; then
        p="y"
    else
        p="n"
    fi
}

function run() {
    local cmd
    cmd=$(echo "$1" | paste -sd' ' | sed 's/[[:space:]]\{2,\}/ /g')

    printf '\n$ %s\n' "$cmd"
    echo "==="
    $cmd
    echo "==="
}

function ask() {
    prompt "$1"
    if [ "$p" == "y" ]; then
        shift
        for cmd in "$@"; do
            run "$cmd"
        done
    fi
}

run 'sudo sysctl -w fs.aio-max-nr=1048576'

ask "Cleanup docker?" \
    'docker compose down -v'

ask "Run docker commands?" \
    "docker run -v $(pwd)/compose:/compose astarte/docker-compose-initializer:1.1" \
    'docker compose pull' \
    'docker compose up -d'

ask "Generate keys?" \
    'astartectl utils gen-keypair test'

ask "Create realm?" \
    'astartectl housekeeping realms create test
        --astarte-url http://api.astarte.localhost
        --realm-public-key test_public.pem
        -k compose/astarte-keys/housekeeping_private.pem' \
    'astartectl housekeeping realms ls
        --astarte-url http://api.astarte.localhost
        -k compose/astarte-keys/housekeeping_private.pem'

ask 'Register device?' \
    'astartectl pairing agent register
        --astarte-url http://api.astarte.localhost
        --realm-key test_private.pem
        -r test
        2TBn-jNESuuHamE2Zo1anA'

ask 'Re-Register device?' \
    'astartectl pairing agent unregister
        --astarte-url http://api.astarte.localhost
        --realm-key test_private.pem
        -r test
        2TBn-jNESuuHamE2Zo1anA' \
    'astartectl pairing agent register
        --astarte-url http://api.astarte.localhost
        --realm-key test_private.pem
        -r test
        2TBn-jNESuuHamE2Zo1anA'

ask 'Generate Token for the Dashboard?' \
    'astartectl utils gen-jwt all-realm-apis -k test_private.pem'

ask 'Open the Dashboard?' \
    'xdg-open http://dashboard.astarte.localhost'
