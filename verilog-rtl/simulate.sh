#! /bin/sh

set -o errexit
#set -o nounset
set -o xtrace

# export SYNOPSYS_HOME=/usr/synopsys
# export VERDI_HOME=$SYNOPSYS_HOME/verdi-L-2016.06-1
# export LD_LIBRARY_PATH=$VERDI_HOME/share/PLI/VCS/LINUX64
export VERDI_TRACEX_ENABLE=1
export FSDB_GATE=0

if [ -z $INCLUDE_PATH ]; then
    INCLUDE_PATH=$RTL_PATH
fi
if [ -z $LIBRARY_PATH ]; then
    LIBRARY_PATH=$RTL_PATH
fi

RTL_FILES=`find -L $RTL_PATH -type f -name '*v' -not -path '*tb*'`
# RTL_FILE=`find $RTL_PATH -maxdepth 10 -type f -name '*.v' -not -path '*tb*'`
cat <<EOF >sim.f
$TB_FILE
$RTL_FILES
EOF
cat <<EOF >dump_fsdb_vcs.tcl
#global env
fsdbDumpfile "$::env(TOP_MODULE).fsdb"
fsdbDumpvars
run
#fsdbDumpoff
#fsdbDumpon
#run 200ns
EOF

vcs -kdb -lca -sverilog +v2k -debug_access+all+reverse +vcs+lic+wait -full64 -j8 \
    -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
    -notice -y $LIBRARY_PATH +incdir+$INCLUDE_PATH +libext+.sv+.v \
    +lint=all +memcbk -race=all -xzcheck -l vcs.log -f sim.f
./simv -fgp=num_threads:8 -ucli -i dump_fsdb_vcs.tcl -l sim.log +fsdb+autoflush
#./simv -ucli -i dump_fsdb_vcs.tcl -l sim.log +fsdb+autoflush -verdi

verdi -sv -f sim.f -top $TOP_MODULE -ssf $TOP_MODULE.fsdb -nologo
#verdi -dbdir ./simv.daidir -nologo
#verdi -ssf $TOP_MODULE.fsdb -nologo
#verdi -elab ./simv.daidir/kdb -nologo

