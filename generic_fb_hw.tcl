# TCL File Generated by Component Editor 15.1
# Sun Jun 19 12:56:06 IST 2016
# DO NOT MODIFY


# 
# generic_fb "generic_fb" v1.0
#  2016.06.19.12:56:06
# 
# 

# 
# request TCL package from ACDS 15.1
# 
package require -exact qsys 15.1


# 
# module generic_fb
# 
set_module_property DESCRIPTION ""
set_module_property NAME generic_fb
set_module_property VERSION 1.0
set_module_property INTERNAL false
set_module_property OPAQUE_ADDRESS_MAP true
set_module_property GROUP asdfg
set_module_property AUTHOR ""
set_module_property DISPLAY_NAME generic_fb
set_module_property INSTANTIATE_IN_SYSTEM_MODULE true
set_module_property EDITABLE true
set_module_property REPORT_TO_TALKBACK false
set_module_property ALLOW_GREYBOX_GENERATION false
set_module_property REPORT_HIERARCHY false


# 
# file sets
# 
add_fileset QUARTUS_SYNTH QUARTUS_SYNTH "" ""
set_fileset_property QUARTUS_SYNTH TOP_LEVEL generic_fb
set_fileset_property QUARTUS_SYNTH ENABLE_RELATIVE_INCLUDE_PATHS false
set_fileset_property QUARTUS_SYNTH ENABLE_FILE_OVERWRITE_MODE false
add_fileset_file generic_fb.vhd VHDL PATH generic_fb.vhd TOP_LEVEL_FILE


# 
# parameters
# 
add_parameter burstLength INTEGER 16
set_parameter_property burstLength DEFAULT_VALUE 16
set_parameter_property burstLength DISPLAY_NAME burstLength
set_parameter_property burstLength TYPE INTEGER
set_parameter_property burstLength UNITS None
set_parameter_property burstLength ALLOWED_RANGES -2147483648:2147483647
set_parameter_property burstLength HDL_PARAMETER true


# 
# display items
# 


# 
# connection point clock_sink
# 
add_interface clock_sink clock end
set_interface_property clock_sink clockRate 0
set_interface_property clock_sink ENABLED true
set_interface_property clock_sink EXPORT_OF ""
set_interface_property clock_sink PORT_NAME_MAP ""
set_interface_property clock_sink CMSIS_SVD_VARIABLES ""
set_interface_property clock_sink SVD_ADDRESS_GROUP ""

add_interface_port clock_sink aclk clk Input 1


# 
# connection point altera_axi4_master
# 
add_interface altera_axi4_master axi4 start
set_interface_property altera_axi4_master associatedClock clock_sink
set_interface_property altera_axi4_master associatedReset reset_sink
set_interface_property altera_axi4_master readIssuingCapability 16
set_interface_property altera_axi4_master writeIssuingCapability 1
set_interface_property altera_axi4_master combinedIssuingCapability 16
set_interface_property altera_axi4_master ENABLED true
set_interface_property altera_axi4_master EXPORT_OF ""
set_interface_property altera_axi4_master PORT_NAME_MAP ""
set_interface_property altera_axi4_master CMSIS_SVD_VARIABLES ""
set_interface_property altera_axi4_master SVD_ADDRESS_GROUP ""

add_interface_port altera_axi4_master arready arready Input 1
add_interface_port altera_axi4_master arvalid arvalid Output 1
add_interface_port altera_axi4_master araddr araddr Output 32
add_interface_port altera_axi4_master arlen arlen Output 8
add_interface_port altera_axi4_master rvalid rvalid Input 1
add_interface_port altera_axi4_master rready rready Output 1
add_interface_port altera_axi4_master rdata rdata Input 64
add_interface_port altera_axi4_master awaddr awaddr Output 32
add_interface_port altera_axi4_master awprot awprot Output 3
add_interface_port altera_axi4_master awvalid awvalid Output 1
add_interface_port altera_axi4_master awready awready Input 1
add_interface_port altera_axi4_master wdata wdata Output 64
add_interface_port altera_axi4_master wlast wlast Output 1
add_interface_port altera_axi4_master wready wready Input 1
add_interface_port altera_axi4_master bvalid bvalid Input 1
add_interface_port altera_axi4_master bready bready Output 1
add_interface_port altera_axi4_master arprot arprot Output 3
add_interface_port altera_axi4_master wvalid wvalid Output 1


# 
# connection point reset_sink
# 
add_interface reset_sink reset end
set_interface_property reset_sink associatedClock clock_sink
set_interface_property reset_sink synchronousEdges DEASSERT
set_interface_property reset_sink ENABLED true
set_interface_property reset_sink EXPORT_OF ""
set_interface_property reset_sink PORT_NAME_MAP ""
set_interface_property reset_sink CMSIS_SVD_VARIABLES ""
set_interface_property reset_sink SVD_ADDRESS_GROUP ""

add_interface_port reset_sink rst reset Input 1


# 
# connection point conf
# 
add_interface conf conduit end
set_interface_property conf associatedClock ""
set_interface_property conf associatedReset ""
set_interface_property conf ENABLED true
set_interface_property conf EXPORT_OF ""
set_interface_property conf PORT_NAME_MAP ""
set_interface_property conf CMSIS_SVD_VARIABLES ""
set_interface_property conf SVD_ADDRESS_GROUP ""

add_interface_port conf conf_addrStart addrstart Input 32
add_interface_port conf conf_addrEnd addrend Input 32
add_interface_port conf conf_deviceEnable deviceenable Input 1


# 
# connection point video
# 
add_interface video conduit end
set_interface_property video associatedClock ""
set_interface_property video associatedReset ""
set_interface_property video ENABLED true
set_interface_property video EXPORT_OF ""
set_interface_property video PORT_NAME_MAP ""
set_interface_property video CMSIS_SVD_VARIABLES ""
set_interface_property video SVD_ADDRESS_GROUP ""

add_interface_port video videoclk videoclk Input 1
add_interface_port video offscreen offscreen Input 1
add_interface_port video dataout dataout Output 32

