library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.osc;
use work.AudioSubSystemStereo;
use work.lpf_rom_rc_64_100;
use work.lpf;
use work.hexdisplay;
use work.volumeControl;
use work.signedClipper;
use work.sinc_rom_64;
use work.interpolator;

entity lpf_test is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of lpf_test is
	signal adcclk,aclk,lpfClk: std_logic;
	signal samples_per_px,samples_per_px1: unsigned(19 downto 0);
	signal ainL_x,ainR_x,ainL,ainR,aoutL,aoutR,ainL2,ainR2,ainL2_x,ainR2_x: signed(15 downto 0);
	signal ainL1,ainR1,ainL1_x,ainR1_x: signed(19 downto 0);
	signal rom1_addr1,rom1_addr2,rom2_addr1,rom2_addr2: unsigned(5 downto 0);
	signal rom1_clk,rom2_clk: std_logic;
	signal rom1_q1,rom1_q2,rom2_q1,rom2_q2: signed(95 downto 0);
	signal lpfOut,lpfOut_x: signed(15 downto 0);
	signal interpOut: signed(16 downto 0);
	
	signal rom3_addr1,rom3_addr2: unsigned(7 downto 0);
	signal rom3_clk1,rom3_clk2: std_logic;
	signal rom3_q1,rom3_q2: signed(127 downto 0);
begin
gen:
	for I in 0 to 15 generate
		samples_per_px1(I) <= '1' when unsigned(SW(3 downto 0))=to_unsigned(I,4) else '0';
	end generate;
	samples_per_px <= samples_per_px1 when KEY(3)='1' else (others=>'0');
	--samples_per_px <= unsigned(SW)*unsigned(SW) when rising_edge(CLOCK_50);
	o: osc port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
		lpfOut,samples_per_px,CLOCK_50,lpfClk);
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL_x,
			AudioInR=>ainR_x,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	ainL <= ainL_x when rising_edge(aclk);
	ainR <= ainR_x when rising_edge(aclk);
	vc1: volumeControl port map(ainL,ainL1_x,SW(9 downto 7));
	vc2: volumeControl port map(ainR,ainR1_x,SW(9 downto 7));
	ainL1 <= ainL1_x when rising_edge(aclk);
	ainR1 <= ainR1_x when rising_edge(aclk);
	sc1: signedClipper generic map(20,16) port map(ainL1,ainL2_x);
	sc2: signedClipper generic map(20,16) port map(ainR1,ainR2_x);
	ainL2 <= ainL2_x when rising_edge(aclk);
	ainR2 <= ainR2_x when rising_edge(aclk);
	
	rom1: lpf_rom_rc_64_100 port map(rom1_addr1,rom1_addr2,rom1_clk,rom1_q1,rom1_q2);
	lpf1: lpf generic map(64,12,16) port map(ainL2,aclk,lpfOut_x,lpfClk,
		rom1_addr1,rom1_addr2,rom1_clk,rom1_q1,rom1_q2);
	lpfOut <= lpfOut_x when falling_edge(aclk);
		
	interp: interpolator port map(aclk,lpfClk,lpfOut,interpOut,rom3_addr1,rom3_addr2,
		rom3_clk1,rom3_clk2,rom3_q1,rom3_q2);
	rom3: sinc_rom_64 port map(rom3_addr1(5 downto 0),rom3_addr2(5 downto 0),
		rom3_clk1,rom3_clk2,rom3_q1,rom3_q2);
		
	aoutL <= interpOut(16 downto 1) when rising_edge(aclk);
	aoutR <= ainR2 when rising_edge(aclk);
end architecture;
