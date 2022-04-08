#!/bin/bash

for port in `seq 6379 6385`; do
    redis-cli -p $port flushall
done
