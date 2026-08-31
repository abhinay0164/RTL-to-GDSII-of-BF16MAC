# mmmc_setup.tcl
# 1. Define the Timing Library
create_library_set -name SCL180_LIB -timing [list /home/DDF_workshop/SCL_PDK_v2/scl_pdk_v2/stdlib/fs120/liberty/lib_flow_ss/tsl18fs120_scl_ss.lib]

# 2. Define RC and Delay Corners
create_rc_corner -name default_rc -T 25
create_delay_corner -name delay_default -library_set SCL180_LIB -rc_corner default_rc

# 3. Link your SDC Constraints
create_constraint_mode -name bf16_constraints -sdc_files [list bf16_mac.sdc]

# 4. Create Analysis Views
create_analysis_view -name view_default -constraint_mode bf16_constraints -delay_corner delay_default
set_analysis_view -setup [list view_default] -hold [list view_default]
