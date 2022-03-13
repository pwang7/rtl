#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

export RTL_PATH=`realpath e203_cpu_top/rtl`
export TB_FILE=`realpath e203_cpu_top/tb/tb_top.v`
export TOP_MODULE=e203_cpu_top
export CLK_NAME=clk
export CLK_PERIOD=10
export RST_NAME=rst_n

# export RTL_PATH=`realpath others/sdram_controller/sdram/`
# export TB_FILE=`realpath others/sdram_controller/sdram/tb_sdram_top.v`
# export TOP_MODULE=sdram_top
# export CLK_NAME=sclk
# export CLK_PERIOD=10
# export RST_NAME=s_rst_n

# export RTL_PATH=`realpath src/sdram/`
# export TB_FILE=`realpath src/sdram/tb_sdram_top.v`
# export TOP_MODULE=sdram_top
# export CLK_NAME=sclk
# export CLK_PERIOD=10
# export RST_NAME=reset

# export RTL_PATH=`realpath others/basic_circuits/`
# export TB_FILE=`pwd`
# export TOP_MODULE=Odd_Div
# export CLK_NAME=clk_in
# export CLK_PERIOD=10
# export RST_NAME=rst_n

# export RTL_PATH=`realpath FIFO_Verdi/rtl`
# export TB_FILE=`realpath FIFO_Verdi/tb/tb_afifo.v`
# export TOP_MODULE=afifo
# export CLK_NAME=wclk_i
# export CLK_PERIOD=10
# export RST_NAME=wrst_n_i

# export RTL_PATH=`realpath others/fsm`
# export TB_FILE=`realpath others/fsm/tb_seq_1011.v`
# export TOP_MODULE=detect_1011
# export CLK_NAME=clk_i
# export CLK_PERIOD=10
# export RST_NAME=rst_n_i

# export RTL_PATH=`realpath src/mips32`
# export TB_FILE=`realpath src/mips32/tb_mips32_test3.v`
# export TOP_MODULE=MIPS32
# export CLK_NAME=clk
# export CLK_PERIOD=10
# export RST_NAME=rst

export PROJ_ROOT_PATH=`pwd`

export BUILD_PATH=$PROJ_ROOT_PATH/build
export CONFIG_PATH=$BUILD_PATH/config
export SCRIPT_PATH=$BUILD_PATH/script
export MAPPED_PATH=$BUILD_PATH/mapped
export REPORT_PATH=$BUILD_PATH/report
export UNMAPPED_PATH=$BUILD_PATH/unmapped
export WORK_PATH=$BUILD_PATH/work

mkdir -p $BUILD_PATH
mkdir -p $CONFIG_PATH
mkdir -p $SCRIPT_PATH
mkdir -p $MAPPED_PATH
mkdir -p $REPORT_PATH
mkdir -p $UNMAPPED_PATH
mkdir -p $WORK_PATH

cp $PROJ_ROOT_PATH/synopsys_dc.setup $WORK_PATH/.synopsys_dc.setup
cp $PROJ_ROOT_PATH/compile.tcl $SCRIPT_PATH
cp $PROJ_ROOT_PATH/synopsys_pre_run.sh $SCRIPT_PATH
cp $PROJ_ROOT_PATH/simulate.sh $SCRIPT_PATH


#docker run --rm -it -p 5902:5902 --hostname lizhen --mac-address 02:42:ac:11:00:02 \
docker run --rm -it -p 5902:5902 --hostname `hostname` --mac-address 02:42:ac:11:00:02 \
    -e DISPLAY \
    -v /tmp/.X11-unix/:/tmp/.X11-unix/:ro \
    -v $HOME/.Xauthority:/root/.Xauthority:ro \
    -e PROJ_ROOT_PATH \
    -e RTL_PATH \
    -e INCLUDE_PATH \
    -e LIBRARY_PATH \
    -e TB_FILE \
    -e BUILD_PATH \
    -e TOP_MODULE \
    -e CLK_NAME \
    -e CLK_PERIOD \
    -e RST_NAME \
    -e DC_HOME \
    -e VERDI_HOME \
    -v $PROJ_ROOT_PATH:$PROJ_ROOT_PATH \
    -v `realpath ~/Downloads/rust_cargo/rtl/apt`:/etc/apt \
    -w $WORK_PATH \
    --entrypoint $SCRIPT_PATH/synopsys_pre_run.sh \
    phyzli/ubuntu18.04_xfce4_vnc4server_synopsys2016
