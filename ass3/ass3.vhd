Library ieee;
library work;
Use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;
use work.AudioSubSystemStereo;
use work.Clipper;
entity InputMixer is
	port(SW: in std_logic_vector(17 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			AUD_XCK : out std_logic;
			I2C_SCLK : out std_logic;
			I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			LEDR: out std_logic_vector(17 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of InputMixer is
	signal aclk: std_logic;
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	signal gainL,gainR: signed(4 downto 0);
	signal tmpL,tmpR: signed(20 downto 0);
begin
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>I2C_SCLK,I2C_Sdat=>I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	cl: Clipper port map(inp=>SW(3 downto 0),gainL=>gainL,gainR=>gainR);
	tmpL <= ainL*gainL;
	tmpR <= ainR*gainR;
	aoutL <= tmpL(18 downto 3)+tmpR(18 downto 3);
	aoutR <= aoutL;
	LEDR(15 downto 0) <= std_logic_vector(aoutL(15 downto 0)) when aoutL>0 else std_logic_vector(-aoutL(15 downto 0));
	LEDR(17 downto 16) <= SW(1 downto 0);
end architecture;
