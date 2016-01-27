set_global_assignment -entity "adcpll" -library "lib_adcpll" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "adcpll" -library "lib_adcpll" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "adcpll" -library "lib_adcpll" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_adcpll" -name SPD_FILE [file join $::quartus(sip_path) "adcpll.spd"]

set_global_assignment -library "lib_adcpll" -name MISC_FILE [file join $::quartus(sip_path) "adcpll_sim/adcpll.vho"]
