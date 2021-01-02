#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

## Ubuntu
# sudo apt install iverilog
# sudo apt install gtkwave
## MacOS
# brew install icarus-verilog
# brew install verilator
# brew cask insatll gtkwave
# # fix gtkwave following: https://ughe.github.io/2018/11/06/gtkwave-osx
# cpan install Switch

SHOW_WAVE=${SHOW_WAVE:-"true"}
OS=${OS:-"linux"}
WAVE_FILE=wave

mkdir -p build
cd build
iverilog -g2012 -Wall -Winfloop -o $WAVE_FILE -y ../src ../src/*.v
vvp -n $WAVE_FILE -lxt2
if [ $SHOW_WAVE = "true" ]; then
    if [ $OS = "macos" ]; then
        /Applications/gtkwave.app/Contents/Resources/bin/gtkwave wave.vcd ../wave.gtkw &
    else
        gtkwave wave.vcd ../wave.gtkw &
    fi
fi
