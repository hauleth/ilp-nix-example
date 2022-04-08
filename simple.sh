#!/bin/bash

printf "Creating Alice's account on Node A...\n"
ilp-as alice accounts create alice \
    --ilp-address example.alice \
    --asset-code ABC \
    --asset-scale 9 \
    --ilp-over-http-incoming-token alice-password \
    | jq .

printf "Creating Node B's account on Node A...\n"
ilp-as alice accounts create bob \
    --asset-code ABC \
    --asset-scale 9 \
    --ilp-address example.bob \
    --ilp-over-http-outgoing-token ilp_alice \
    --ilp-over-http-url "http://localhost:10100/accounts/bob/ilp" \
    | jq .

# Insert accounts on Node B
# One account represents Bob and the other represents Node A's account with Node B

printf "Creating Bob's account on Node B...\n"
ilp-as bob accounts create bob \
    --ilp-address example.bob \
    --asset-code ABC \
    --asset-scale 9 \
    | jq .

printf "Creating Node A's account on Node B...\n"
ilp-as bob accounts create alice \
    --ilp-address example.alice \
    --asset-code ABC \
    --asset-scale 9 \
    --ilp-over-http-incoming-token ilp_alice \
    | jq .
