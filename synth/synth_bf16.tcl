# 1. Setup SCL 180nm Library Paths
# (Pointing to the SCL 180nm library you located on the server)
# 1. Library Setup (Using your confirmed SCL 180nm paths)
set target_library "/home/DDF_workshop/SCL_PDK_v2/scl_pdk_v2/stdlib/fs120/liberty/lib_flow_ss/tsl18fs120_scl_ss.db"
set link_library "* /home/DDF_workshop/SCL_PDK_v2/scl_pdk_v2/stdlib/fs120/liberty/lib_flow_ss/tsl18fs120_scl_ss.db"

# 2. Read all three RTL files (Dependencies first, then Top module)
analyze -format verilog {../rtl/bf16_adder.v ../rtl/bf16_multiplier.v ../rtl/bf16_mac.v}
elaborate bf16_mac
current_design bf16_mac
link
check_design

# 3. Define Clock & Timing Constraints (Targeting 500MHz)
#create_clock -name clk -period 2.0 [get_ports clk]
# since max freq is 278.5 running it at slower freq to avoid slack
create_clock -name clk -period 4.0 [get_ports clk]
set_input_delay -max 0.2 -clock clk [all_inputs]
set_output_delay -max 0.2 -clock clk [all_outputs]

# 4. Synthesize to Gates
compile_ultra

# 5. Extract Resume Metrics (Fmax, Area, Power)
report_timing > bf16_timing.rpt
report_area   > bf16_area.rpt
report_power  > bf16_power.rpt

# 6. Save Backend Inputs for Cadence Innovus
write_file -format verilog -hierarchy -output bf16_mac_netlist.v
write_sdc bf16_mac.sdc

# Optional: start_GUI if you want to view the schematic
exit
