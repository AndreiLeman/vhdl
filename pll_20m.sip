set_global_assignment -entity "pll_20m" -library "lib_pll_20m" -name IP_TOOL_NAME "altera_pll"
set_global_assignment -entity "pll_20m" -library "lib_pll_20m" -name IP_TOOL_VERSION "15.1"
set_global_assignment -entity "pll_20m" -library "lib_pll_20m" -name IP_TOOL_ENV "mwpim"
set_global_assignment -library "lib_pll_20m" -name SPD_FILE [file join $::quartus(sip_path) "pll_20m.spd"]

set_global_assignment -library "lib_pll_20m" -name MISC_FILE [file join $::quartus(sip_path) "pll_20m_sim/pll_20m.vho"]
