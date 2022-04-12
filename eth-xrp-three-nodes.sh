#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

alice_token="$(get alice token)"
bob_token="$(get bob token)"
charlie_token="$(get charlie token)"

printf "Adding Alice's account...\n"
ilp-as alice accounts create alice \
    --ilp-address example.alice \
    --asset-code ETH \
    --asset-scale 6 \
    --max-packet-amount 100 \
    --ilp-over-http-incoming-token "$alice_token" \
    --settle-to 0 \
    | jq .

printf "Adding Bob's account...\n"
ilp-as bob accounts create bob \
    --ilp-address example.bob \
    --asset-code ETH \
    --asset-scale 6 \
    --max-packet-amount 100 \
    --ilp-over-http-incoming-token "$bob_token" \
    --settle-to 0 \
    | jq .

printf "Adding Bob's account on Alice's node (ETH Peer relation)...\n"
ilp-as alice accounts create bob \
    --ilp-address example.bob \
    --asset-code ETH \
    --asset-scale 6 \
    --max-packet-amount 100 \
    --settlement-engine-url http://localhost:3000 \
    --ilp-over-http-incoming-token "$bob_token" \
    --ilp-over-http-outgoing-token "$alice_token" \
    --ilp-over-http-url http://$BOB_NODE/accounts/alice/ilp \
    --settle-threshold 500 \
    --min-balance -1000 \
    --settle-to 0 \
    --routing-relation Peer \
    | jq .

printf "Adding Alice's account on Bob's node (ETH Peer relation)...\n"
ilp-as bob accounts create alice \
    --ilp-address example.alice \
    --asset-code ETH \
    --asset-scale 6 \
    --max-packet-amount 100 \
    --settlement-engine-url http://localhost:3001 \
    --ilp-over-http-incoming-token "$alice_token" \
    --ilp-over-http-outgoing-token "$bob_token" \
    --ilp-over-http-url http://$ALICE_NODE/accounts/bob/ilp \
    --settle-threshold 500 \
    --min-balance -1000 \
    --settle-to 0 \
    --routing-relation Peer \
    | jq .


printf "Adding Charlie's account on Bob's node (XRP Child relation)...\n"
# you can optionally provide --ilp-address example.bob.charlie as an argument,
# but the node is smart enough to figure it by itself
# Prefunds up to 1 XRP from Bob to Charlie, topped up after every packet is fulfilled
ilp-as bob accounts create charlie \
    --asset-code XRP \
    --asset-scale 6 \
    --settlement-engine-url http://localhost:3002 \
    --ilp-over-http-incoming-token "$charlie_token" \
    --ilp-over-http-outgoing-token "$bob_token" \
    --ilp-over-http-url http://$CHARLIE_NODE/accounts/bob/ilp \
    --settle-threshold 0 \
    --settle-to -1000000 \
    --min-balance -10000000 \
    --routing-relation Child | jq .

printf "Adding Charlie's Account...\n"
# initially, Charlie gets added as local.host.charlie
ilp-as charlie accounts create charlie \
    --asset-code XRP \
    --asset-scale 6 \
    --ilp-over-http-incoming-token "$charlie_token" \
    --settle-to 0 | jq .

printf "Adding Bob's account on Charlie's node (XRP Parent relation)...\n"
# Once a parent is added, Charlie's node address is updated to `example.bob.charlie,
# and then subsequently the addresses of all NonRoutingAccount and Child accounts get
# updated to ${NODE_ADDRESS}.${CHILD_USERNAME}, with the exception of the account whose
# username matches the suffix of the node's address.
# So in this case, Charlie's account address gets updated from local.host.charlie to example.bob.charlie
# If Charlie had another Child account saved, say `alice`, Alice's address would become
# `example.bob.charlie.alice`
ilp-as charlie accounts create bob \
    --ilp-address example.bob \
    --asset-code XRP \
    --asset-scale 6 \
    --settlement-engine-url http://localhost:3003 \
    --ilp-over-http-incoming-token "$bob_token" \
    --ilp-over-http-outgoing-token "$charlie_token" \
    --ilp-over-http-url http://$BOB_NODE/accounts/charlie/ilp \
    --settle-threshold 200000 \
    --settle-to -1000000 \
    --min-balance -10000000 \
    --routing-relation Parent | jq .
