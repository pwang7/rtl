#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

# Spinal HDL simulation demo
sbt "runMain CounterSim"
sbt test

# Cocotb simulation demo
export CODEGEN=`realpath codegen`
mkdir -p $CODEGEN
sbt "runMain Adder $CODEGEN"
cd src/test/python/adder
make SIM=icarus
