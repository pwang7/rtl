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

mkdir -p $BUILD_DIR
cd $BUILD_DIR
iverilog -v -g2012 -Wall -Winfloop -o $WAVE_SBIN -I ../src -y ../src ../src/*.v
vvp -v -N -lxt2 $WAVE_SBIN
yosys ../synth.ys

if [ "$SHOW_WAVE" = "true" ]; then
    GTKWAVE_PID=`pgrep gtkwave || echo "none"`
    if [ "$GTKWAVE_PID" != "none" ]; then
        pkill gtkwave
    fi
    OS=`uname -s`
    if [ "$OS" = "Darwin" ]; then
        /Applications/gtkwave.app/Contents/Resources/bin/gtkwave $WAVE_LXT ../wave.gtkw &
    else
        gtkwave $WAVE_LXT ../wave.gtkw &
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
