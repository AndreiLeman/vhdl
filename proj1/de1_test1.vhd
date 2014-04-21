library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use ieee.math_real.log2;
use ieee.math_real.ceil;
entity shift_r is
	generic(b: integer);
	port(inp: in signed(b-1 downto 0);
			sh: in unsigned(integer(ceil(log2(real(b))))-1 downto 0);
			outp: out signed(b-1 downto 0));
end entity;
architecture a of shift_r is
	type arr is array(b-1 downto 0) of signed(b-1 downto 0);
	signal a: arr;
begin
gen_values:
	for I in 0 to b-1 generate
		a(I) <= (I downto 1=>inp(b-1)) & inp(b-1 downto I);
	end generate;
	outp <= a(to_integer(sh));
end architecture;



library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemMono;
use work.delayline;
use work.random;
use work.shift_r;
entity de1_test1 is
	port(CLOCK_50: in std_logic;
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7: out std_logic_vector(6 downto 0);
			LEDR: out std_logic_vector(9 downto 0));
end entity;
architecture a of de1_test1 is
	signal ain,aout: std_logic_vector(47 downto 0);
	signal clk,aclk: std_logic;
	signal tmp1: signed(31 downto 0) := to_signed(2**18,32);
	signal tmp2: signed(31 downto 0);
	signal tmp1_1,tmp2_1: signed(31 downto 0);
	signal zxcv: unsigned(4 downto 0);
begin
	clk <= CLOCK_50;
	zxcv <= unsigned(SW(4 downto 0)) when rising_edge(clk);
	audio1: AudioSubSystemMono port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),RawIn=>ain,
			RawOut=>aout,SamClk=>aclk);
	s1: shift_r generic map(b=>32) port map(inp=>tmp1,sh=>zxcv,outp=>tmp1_1);
	s2: shift_r generic map(b=>32) port map(inp=>tmp2,sh=>zxcv,outp=>tmp2_1);
	
	tmp2<=to_signed(0,32) when KEY(1)='0' else tmp2+tmp1_1 when rising_edge(clk);
	tmp1<=to_signed(2**18,32) when KEY(1)='0' else tmp1-tmp2_1 when falling_edge(clk);
	aout <= std_logic_vector(tmp1);
end architecture;
