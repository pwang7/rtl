#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

# Spinal HDL simulation demo
sbt "runMain CounterSim"
sbt test

# E2E UDP test
cd src/test/python/udp/onnetwork
timeout 5 make &
sleep 3
python3 Client.py

