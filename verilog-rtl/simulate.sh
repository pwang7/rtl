#! /bin/sh

set -o errexit
set -o nounset
set -o xtrace

# export SYNOPSYS_HOME=/usr/synopsys
# export VERDI_HOME=$SYNOPSYS_HOME/verdi-L-2016.06-1
# export LD_LIBRARY_PATH=$VERDI_HOME/share/PLI/VCS/LINUX64
export VERDI_TRACEX_ENABLE=1
export FSDB_GATE=0

RTL_FILE=`find $RTL_PATH -maxdepth 1 -type f -name '*.v' -not -path '*tb*'`
#RTL_FILE=`ls -1 $RTL_PATH/*.v`
cat <<EOF >sim.f
$TB_FILE
$RTL_FILE
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

vcs -kdb -lca -sverilog -debug_access+all+reverse +vcs+lic+wait \
    -P $VERDI_HOME/share/PLI/VCS/LINUX64/novas.tab $VERDI_HOME/share/PLI/VCS/LINUX64/pli.a \
    +libext+.sv +libext+.v -fpg -l vcs.log -f sim.f
./simv -fgp=num_threads:8 -ucli -i dump_fsdb_vcs.tcl -l sim.log +fsdb+autoflush
#./simv -ucli -i dump_fsdb_vcs.tcl -l sim.log +fsdb+autoflush -verdi

#verdi -sv -f sim.f -top $TOP_MODULE -ssf $TOP_MODULE.fsdb -nologo
#verdi -dbdir ./simv.daidir -nologo
verdi -ssf $TOP_MODULE.fsdb -nologo
