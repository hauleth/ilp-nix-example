#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

alice_token="$(get alice token)"
bob_token="$(get bob token)"

printf "Adding Alice's account...\n"
ilp-as alice accounts create alice \
    --ilp-address example.alice \
    --asset-code ETH \
    --asset-scale 18 \
    --max-packet-amount 100 \
    --ilp-over-http-incoming-token "$alice_token" \
    --settle-to 0 | jq .

printf "Adding Bob's Account...\n"
ilp-as bob accounts create bob \
    --ilp-address example.bob \
    --asset-code ETH \
    --asset-scale 18 \
    --max-packet-amount 100 \
    --ilp-over-http-incoming-token "$bob_token" \
    --settle-to 0 | jq .

printf "Adding Bob's account on Alice's node...\n"
ilp-as alice accounts create bob \
    --ilp-address example.bob \
    --asset-code ETH \
    --asset-scale 18 \
    --max-packet-amount 100 \
    --settlement-engine-url http://localhost:3000 \
    --ilp-over-http-incoming-token "$bob_token" \
    --ilp-over-http-outgoing-token "$alice_token" \
    --ilp-over-http-url http://$BOB_NODE/accounts/alice/ilp \
    --settle-threshold 500 \
    --min-balance -1000 \
    --settle-to 0 \
    --routing-relation Peer | jq .

printf "Adding Alice's account on Bob's node...\n"
ilp-as bob accounts create alice \
    --ilp-address example.alice \
    --asset-code ETH \
    --asset-scale 18 \
    --max-packet-amount 100 \
    --settlement-engine-url http://localhost:3001 \
    --ilp-over-http-incoming-token "$alice_token" \
    --ilp-over-http-outgoing-token "$bob_token" \
    --ilp-over-http-url http://$ALICE_NODE/accounts/bob/ilp \
    --settle-threshold 500 \
    --settle-to 0 \
    --routing-relation Peer | jq .
