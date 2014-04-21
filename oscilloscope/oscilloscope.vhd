library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.osc;
use work.AudioSubSystemStereo;

entity oscilloscope is
	port(VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			CLOCK_50: in std_logic);
end entity;
architecture a of oscilloscope is
	signal osc_data: signed(16 downto 0);
	signal samples_per_px: unsigned(19 downto 0);
	signal aclk: std_logic;
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
begin
gen:
	for I in 0 to 15 generate
		samples_per_px(I) <= '1' when unsigned(SW(3 downto 0))=to_unsigned(I,4) else '0';
	end generate;
	--samples_per_px <= unsigned(SW)*unsigned(SW) when rising_edge(CLOCK_50);
	o: osc port map(VGA_R,VGA_G,VGA_B,VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS,
		osc_data(16 downto 1),samples_per_px,CLOCK_50,aclk);
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	osc_data <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
	aoutL <= ainL;
	aoutR <= ainR;
end architecture;
