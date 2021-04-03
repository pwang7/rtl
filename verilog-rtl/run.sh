#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

## Ubuntu
# sudo apt install iverilog
# sudo apt install gtkwave
# sudo apt install yosys
## MacOS
# brew install icarus-verilog
# brew install verilator
# brew cask insatll gtkwave
# # fix gtkwave following: https://ughe.github.io/2018/11/06/gtkwave-osx
# cpan install Switch
# brew install yosys

SHOW_WAVE=${SHOW_WAVE:-"true"}

WAVE_SBIN=wave.sbin
WAVE_LXT=wave.vcd
BUILD_DIR=build
GFLAGS="-S ../gtkw.tcl"

mkdir -p $BUILD_DIR
cd $BUILD_DIR

# Simulation
for TB in `ls ../src/tb*.v`
do
    iverilog -v -g2012 -Wall -Winfloop -o $WAVE_SBIN -I ../src -y ../src $TB
    vvp -v -N -lxt2 $WAVE_SBIN
done

# MIPS32 simulation
MIPS32_SBIN=mips32.sbin
iverilog -v -g2012 -Wall -Winfloop -o $MIPS32_SBIN -I ../src -y ../src ../src/mips32/mips32.v ../src/mips32/tb_mips32*.v
vvp -v -N -lxt2 $MIPS32_SBIN

# Synthesis
if command -v yosys; then
    yosys ../synth.ys
    # yosys -p "hierarchy -check; proc; opt; fsm; opt; write_json schematic.json" ../src/bin_counter.v
fi

if [ "$SHOW_WAVE" = "true" ]; then
    GTKWAVE_PID=`pgrep gtkwave || echo "none"`
    if [ "$GTKWAVE_PID" != "none" ]; then
        pkill gtkwave
    fi
    OS=`uname -s`
    if [ "$OS" = "Darwin" ]; then
        /Applications/gtkwave.app/Contents/Resources/bin/gtkwave $GFLAGS $WAVE_LXT &
    else
        gtkwave $GFLAGS $WAVE_LXT &
    fi
fi

# Pipe grep output into cat to avoid grep return non-zero when no matches
FAILURE_NUM=`grep -c 'FAIL' *.log | cat`
if [ $FAILURE_NUM -gt 0 ]; then
    echo "SIMULATION FAILED"
    cat *.log
    exit 1
else
    echo "SIMULATION SUCCESS"
fi
