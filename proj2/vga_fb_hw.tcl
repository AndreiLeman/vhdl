# TCL File Generated by Component Editor 13.1
# Sat Apr 12 20:58:23 PDT 2014
# DO NOT MODIFY


# 
# vga_fb "vga_fb" v1.0
# xaxaxa 2014.04.12.20:58:23
# 
# 

# 
# request TCL package from ACDS 13.1
# 
package require -exact qsys 13.1


# 
# module vga_fb
# 
set_module_property DESCRIPTION ""
set_module_property NAME vga_fb
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP asdfg
set_module_property AUTHOR xaxaxa
set_module_property DISPLAY_NAME vga_fb
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property ANALYZE_HDL AUTO
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL vga_fb
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
add_fileset_file vga_fb.vhd VHDL PATH ../vga_fb.vhd TOP_LEVEL_FILE
add_fileset_file vga2.vhd VHDL PATH ../vga2.vhd
add_fileset_file graphics_types.vhd VHDL PATH ../graphics_types.vhd
add_fileset_file simple_counter.vhd VHDL PATH ../simple_counter.vhd
add_fileset_file synchronizer.vhd VHDL PATH ../synchronizer.vhd


# 
# parameters
# 


# 
# display items
# 


# 
# connection point clock
# 
add_interface clock clock end
set_interface_property clock clockRate 0
set_interface_property clock ENABLED true
set_interface_property clock EXPORT_OF ""
set_interface_property clock PORT_NAME_MAP ""
set_interface_property clock CMSIS_SVD_VARIABLES ""
set_interface_property clock SVD_ADDRESS_GROUP ""

add_interface_port clock clk clk Input 1


# 
# connection point memread
# 
add_interface memread avalon start
set_interface_property memread addressUnits SYMBOLS
set_interface_property memread associatedClock clock
set_interface_property memread associatedReset reset
set_interface_property memread bitsPerSymbol 8
set_interface_property memread burstOnBurstBoundariesOnly false
set_interface_property memread burstcountUnits WORDS
set_interface_property memread doStreamReads false
set_interface_property memread doStreamWrites false
set_interface_property memread holdTime 0
set_interface_property memread linewrapBursts false
set_interface_property memread maximumPendingReadTransactions 0
set_interface_property memread readLatency 0
set_interface_property memread readWaitTime 1
set_interface_property memread setupTime 0
set_interface_property memread timingUnits Cycles
set_interface_property memread writeWaitTime 0
set_interface_property memread ENABLED true
set_interface_property memread EXPORT_OF ""
set_interface_property memread PORT_NAME_MAP ""
set_interface_property memread CMSIS_SVD_VARIABLES ""
set_interface_property memread SVD_ADDRESS_GROUP ""

add_interface_port memread addr address Output 32
add_interface_port memread read read Output 1
add_interface_port memread readdata readdata Input 64
add_interface_port memread waitrequest waitrequest Input 1
add_interface_port memread readdatavalid readdatavalid Input 1
add_interface_port memread burstcount burstcount Output 6


# 
# connection point vga
# 
add_interface vga conduit end
set_interface_property vga associatedClock vgaclock
set_interface_property vga associatedReset ""
set_interface_property vga ENABLED true
set_interface_property vga EXPORT_OF ""
set_interface_property vga PORT_NAME_MAP ""
set_interface_property vga CMSIS_SVD_VARIABLES ""
set_interface_property vga SVD_ADDRESS_GROUP ""

add_interface_port vga vga export Output 60


# 
# connection point vgaclock
# 
add_interface vgaclock clock end
set_interface_property vgaclock clockRate 0
set_interface_property vgaclock ENABLED true
set_interface_property vgaclock EXPORT_OF ""
set_interface_property vgaclock PORT_NAME_MAP ""
set_interface_property vgaclock CMSIS_SVD_VARIABLES ""
set_interface_property vgaclock SVD_ADDRESS_GROUP ""

add_interface_port vgaclock vclk clk Input 1


# 
# connection point reset
# 
add_interface reset reset end
set_interface_property reset associatedClock clock
set_interface_property reset synchronousEdges DEASSERT
set_interface_property reset ENABLED true
set_interface_property reset EXPORT_OF ""
set_interface_property reset PORT_NAME_MAP ""
set_interface_property reset CMSIS_SVD_VARIABLES ""
set_interface_property reset SVD_ADDRESS_GROUP ""

add_interface_port reset real_rst reset Input 1


# 
# connection point conf
# 
add_interface conf conduit end
set_interface_property conf associatedClock conf_clock
set_interface_property conf associatedReset reset
set_interface_property conf ENABLED true
set_interface_property conf EXPORT_OF ""
set_interface_property conf PORT_NAME_MAP ""
set_interface_property conf CMSIS_SVD_VARIABLES ""
set_interface_property conf SVD_ADDRESS_GROUP ""

add_interface_port conf conf export Input 128


# 
# connection point conf_clock
# 
add_interface conf_clock clock end
set_interface_property conf_clock clockRate 0
set_interface_property conf_clock ENABLED true
set_interface_property conf_clock EXPORT_OF ""
set_interface_property conf_clock PORT_NAME_MAP ""
set_interface_property conf_clock CMSIS_SVD_VARIABLES ""
set_interface_property conf_clock SVD_ADDRESS_GROUP ""

add_interface_port conf_clock conf_clk clk Input 1

