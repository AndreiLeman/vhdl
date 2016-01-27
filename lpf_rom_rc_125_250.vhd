library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- raised cosine filter rom
-- clock division factor: 125
-- signal frequency division factor: 250
-- depth: 6 periods
entity lpf_rom_rc_125_250 is
	port(addr1,addr2: in unsigned(6 downto 0);
			clk: in std_logic;
			--output consists of 16 8-bit signed 2's complement
			--fractions (all bits fractional);
			--data[0] is sinc(0)&sinc(1)&sinc(2)...
			--data[1] is sinc(0+1/125)&sinc(1+1/125)&...
			q1,q2: out signed(127 downto 0));
end entity;
architecture a of lpf_rom_rc_125_250 is
	type rom1t is array(0 to 124) of signed(127 downto 0);
	signal rom1: rom1t := (
X"ff0302fdfc0307fdf6030ffde503537f",
X"ff0303fdfc0307fdf6030ffde503527f",
X"ff0303fdfc0307fdf6030ffde502517f",
X"ff0303fdfc0307fdf6030ffee502517f",
X"ff0303fdfc0307fdf6020ffee501507f",
X"ff0303fdfb0307fdf6020ffee5014f7f",
X"ff0303fdfb0307fef6020ffee5004f7f",
X"ff0303fdfb0307fef6020fffe6004e7f",
X"ff0303fdfb0307fef6020fffe6ff4d7f",
X"ff0303fdfb0207fef6020fffe6ff4d7f",
X"ff0303fdfb0207fef6020fffe6fe4c7f",
X"ff0303fdfb0207fef6010f00e6fe4c7f",
X"ff0303fdfb0207fef6010f00e6fd4b7f",
X"ff0303fdfb0207fef6010f00e6fd4a7e",
X"ff0303fefb0207fef6010f00e6fc4a7e",
X"ff0303fefb0207fef6010f01e6fc497e",
X"ff0303fefb0207fff6010f01e6fb487e",
X"ff0303fefb0207fff6000f01e6fb487e",
X"ff0303fefb0207fff6000f01e6fa477e",
X"ff0303fefb0207fff6000f01e7fa467e",
X"ff0303fefb0207fff6000f02e7fa467e",
X"ff0303fefb0207fff6000f02e7f9457e",
X"fe0303fefb0207fff6000f02e7f9447d",
X"fe0303fefb0107fff6000f02e7f8447d",
X"fe0303fefb0107fff6ff0f03e7f8437d",
X"fe0203fefb010700f6ff0f03e7f7427d",
X"fe0203fefb010700f6ff0f03e7f7427d",
X"fe0203fefb010700f6ff0f03e8f7417d",
X"fe0203fefb010700f6ff0f04e8f6407c",
X"fe0203fefb010700f6ff0f04e8f6407c",
X"fe0203fefb010700f6ff0f04e8f53f7c",
X"fe0203fefb010700f6fe0e04e8f53e7c",
X"fe0203fefb010700f6fe0e04e8f53e7c",
X"fe0203fefb010700f6fe0e05e8f43d7c",
X"fe0203fefb010700f6fe0e05e8f43c7b",
X"fe0203fffb010701f6fe0e05e9f43c7b",
X"fe0203fffb010701f6fe0e05e9f33b7b",
X"fe0203fffb000701f6fe0e05e9f33a7b",
X"fe0203fffb000701f6fd0e06e9f2397a",
X"fe0203fffb000701f6fd0e06e9f2397a",
X"fe0203fffb000701f6fd0e06e9f2387a",
X"fe0203fffb000701f6fd0e06eaf1377a",
X"fe0203fffb000701f6fd0e06eaf13779",
X"fe0203fffb000701f6fd0e07eaf13679",
X"fe0203fffb000701f7fd0e07eaf03579",
X"fe0203fffb000701f7fd0d07eaf03579",
X"fe0204fffb000702f7fc0d07eaf03478",
X"fe0204fffb000702f7fc0d07ebef3378",
X"fe0204fffb000702f7fc0d08ebef3378",
X"fe0204fffb000702f7fc0d08ebef3277",
X"fe0204fffb000702f7fc0d08ebef3177",
X"fe0204fffbff0702f7fc0d08ebee3177",
X"fe0204fffbff0702f7fc0d08ecee3077",
X"fe0204fffbff0702f7fc0d08ecee2f76",
X"fe0204fffbff0702f7fb0d09eced2f76",
X"fe020400fbff0702f7fb0d09eced2e76",
X"fe020400fbff0702f7fb0c09eced2d75",
X"fe020400fbff0703f7fb0c09eded2d75",
X"fe010400fbff0703f7fb0c09edec2c74",
X"fe010400fbff0703f7fb0c09edec2b74",
X"fe010400fbff0703f7fb0c0aedec2b74",
X"fe010400fbff0603f7fb0c0aedec2a73",
X"fe010400fbff0603f7fa0c0aeeeb2973",
X"fd010400fbff0603f8fa0c0aeeeb2973",
X"fd010400fbff0603f8fa0c0aeeeb2872",
X"fd010400fbff0603f8fa0b0aeeeb2772",
X"fd010400fbfe0603f8fa0b0befea2771",
X"fd010400fbfe0603f8fa0b0befea2671",
X"fd010400fbfe0604f8fa0b0befea2571",
X"fd010400fbfe0604f8fa0b0befea2570",
X"fd010400fbfe0604f8fa0b0befea2470",
X"fd010400fbfe0604f8f90b0bf0e9236f",
X"fd010400fbfe0604f8f90b0bf0e9236f",
X"fd010400fbfe0604f8f90b0cf0e9226f",
X"fd010400fbfe0604f8f90a0cf0e9216e",
X"fd010400fbfe0604f8f90a0cf1e9216e",
X"fd010401fbfe0604f8f90a0cf1e8206d",
X"fd010401fbfe0604f8f90a0cf1e81f6d",
X"fd010401fbfe0604f9f90a0cf1e81f6c",
X"fd010401fbfe0604f9f90a0cf2e81e6c",
X"fd010401fbfe0604f9f90a0cf2e81d6b",
X"fd010401fbfe0604f9f9090cf2e81d6b",
X"fd010401fbfe0605f9f8090df2e71c6b",
X"fd010401fbfd0605f9f8090df2e71b6a",
X"fd010401fbfd0605f9f8090df3e71b6a",
X"fd010401fcfd0505f9f8090df3e71a69",
X"fd010401fcfd0505f9f8090df3e71a69",
X"fd000401fcfd0505f9f8090df3e71968",
X"fd000401fcfd0505f9f8090df4e71868",
X"fd000401fcfd0505f9f8080df4e71867",
X"fd000401fcfd0505faf8080df4e61767",
X"fd000401fcfd0505faf8080ef4e61666",
X"fd000401fcfd0505faf8080ef5e61666",
X"fd000401fcfd0505faf8080ef5e61565",
X"fd000401fcfd0505faf8080ef5e61565",
X"fd000401fcfd0505faf7080ef5e61464",
X"fd000401fcfd0505faf7070ef6e61363",
X"fd000401fcfd0506faf7070ef6e61363",
X"fd000402fcfd0506faf7070ef6e61262",
X"fd000402fcfd0506faf7070ef6e61262",
X"fd000402fcfd0506faf7070ef7e61161",
X"fd000302fcfd0506fbf7070ef7e51061",
X"fd000302fcfd0506fbf7070ef7e51060",
X"fd000302fcfc0406fbf7060ef7e50f60",
X"fd000302fcfc0406fbf7060ef8e50f5f",
X"fd000302fcfc0406fbf7060ff8e50e5e",
X"fd000302fcfc0406fbf7060ff8e50d5e",
X"fd000302fcfc0406fbf7060ff8e50d5d",
X"fd000302fcfc0406fbf7060ff9e50c5d",
X"fd000302fcfc0406fbf7050ff9e50c5c",
X"fd000302fcfc0406fbf7050ff9e50b5c",
X"fd000302fcfc0406fcf7050ff9e50b5b",
X"fd000302fcfc0406fcf7050ffae50a5a",
X"fd000302fcfc0406fcf6050ffae5095a",
X"fd000302fcfc0406fcf6050ffae50959",
X"fdff0302fdfc0406fcf6050ffae50859",
X"fdff0302fdfc0406fcf6040ffbe50858",
X"fdff0302fdfc0406fcf6040ffbe50757",
X"fdff0302fdfc0406fcf6040ffbe50757",
X"fdff0302fdfc0307fcf6040ffbe50656",
X"fdff0302fdfc0307fcf6040ffce50656",
X"fdff0302fdfc0307fdf6040ffce50555",
X"fdff0302fdfc0307fdf6040ffce50554",
X"fdff0302fdfc0307fdf6030ffce50454",
X"fdff0302fdfc0307fdf6030ffde50453"
);
	signal addr11,addr21: unsigned(6 downto 0);
begin
	addr11 <= addr1 when rising_edge(clk);
	addr21 <= addr2 when rising_edge(clk);
	q1 <= rom1(to_integer(addr11)) when rising_edge(clk);
	q2 <= rom1(to_integer(addr21)) when rising_edge(clk);
end architecture;
