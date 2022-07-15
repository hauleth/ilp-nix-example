#!/bin/sh

set -o errexit
set -o nounset
set -o pipefail

alice_token="$(get alice token)"
bob_token="$(get bob token)"
charlie_token="$(get charlie token)"

ilp-as alice accounts create alice \
    --ilp-address example.alice \
    --asset-code ABC \
    --asset-scale 6 \
    --ilp-over-http-incoming-token "$alice_token" \
    --settle-threshold 0 | jq .

printf "Adding Charlie's account on Alice's node (XRP Child relation)...\n"
ilp-as alice accounts create charlie \
    --asset-code ABC \
    --asset-scale 6 \
    --ilp-over-http-incoming-token "$charlie_token" \
    --ilp-over-http-outgoing-token "$alice_token" \
    --ilp-over-http-url http://$(get charlie node)/accounts/alice/ilp \
    --settle-threshold 0 \
    --routing-relation Child | jq .

printf "Adding Charlie's Account...\n"
# initially, Charlie gets added as local.host.charlie
ilp-as charlie accounts create charlie \
    --asset-code ABC \
    --asset-scale 6 \
    --ilp-over-http-incoming-token "$charlie_token" \
    --settle-to 0 | jq .

ilp-as charlie accounts create alice \
    --asset-code ABC \
    --asset-scale 6 \
    --ilp-over-http-incoming-token "$alice_token" \
    --ilp-over-http-outgoing-token "$charlie_token" \
    --ilp-over-http-url http://$(get alice node)/accounts/charlie/ilp \
    --routing-relation Parent | jq .
