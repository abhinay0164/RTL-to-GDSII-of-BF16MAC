# innovus_init.tcl
set init_top_cell bf16_mac
set init_verilog bf16_mac_netlist.v

set init_pwr_net VDD
set init_gnd_net VSS

# The Tech LEF MUST be loaded first, followed by the Macro LEF
set init_lef_file [list \
    /home/DDF_workshop/SCL_PDK_v2/scl_pdk_v2/stdlib/fs120/tech_data/lef/tsl180l4.lef \
    /home/DDF_workshop/SCL_PDK_v2/scl_pdk_v2/stdlib/fs120/lef/tsl18fs120_scl.lef \
]

# Link the MMMC file you just created
set init_mmmc_file mmmc_setup.tcl
