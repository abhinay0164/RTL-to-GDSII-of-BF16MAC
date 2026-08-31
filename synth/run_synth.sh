#!/bin/bash
echo "Cleaning old synthesis files..."
rm -f *.rpt *.v *.sdc *.svf *.log *.mr *.pvl command.log default.svf

echo "Starting Design Compiler..."
dc_shell -f synth_bf16.tcl | tee synth_compile.log

echo "Synthesis Complete! Check synth_compile.log for details."
