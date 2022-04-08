#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

for port in `seq 6379 6385`; do
    redis-cli -p $port flushall || true
done
