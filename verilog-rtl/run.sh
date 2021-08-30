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
#iverilog -v -g2012 -Wall -Winfloop -o $MIPS32_SBIN -I ../src/mips32 -y ../src/mips32 ../src/mips32/tb_mips32*.v
#vvp -v -N -lxt2 $MIPS32_SBIN

# SDRAM simulation
SDRAM_SBIN=sdram.sbin
#iverilog -v -g2012 -Wall -Winfloop -o $SDRAM_SBIN -I ../src/sdram -y ../src/sdram ../src/sdram/tb_sdram_top.v
#vvp -v -N -lxt2 $SDRAM_SBIN

# RISC-V PLL simulation
RISCV_PLL_SBIN=riscv_pll.sbin
sandpiper-saas -i ../src/riscv_pll/rvmyth.tlv -o rvmyth.v --iArgs --default_includes
iverilog -v -Wall -Winfloop -o $RISCV_PLL_SBIN -I ../src/riscv_pll -y ../src/riscv_pll -I ./includes/ -y ./includes/proj_verilog/ -I ./includes/proj_verilog/ ../src/riscv_pll/rvmyth_pll_tb.v
vvp -v -N -lxt2 $RISCV_PLL_SBIN

# Synthesis
if command -v yosys; then
    # yosys ../synth.ys
    for RTL in `find ../src -maxdepth 1 -type f -name '*.v' -not -path '*tb*'`
    do
        # yosys -p "hierarchy -check; proc; opt; fsm; opt; write_json schematic.json" ../src/bin_counter.v
        yosys -p "read -sv $RTL; synth_xilinx; stat"
    done
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
