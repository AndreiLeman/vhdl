library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.ram1;

entity delayline is
	generic(b: integer; addrs: integer);
	port(inp: in std_logic_vector(b-1 downto 0);
			outp: out std_logic_vector(b-1 downto 0);
			clk: in std_logic);
end entity;
architecture a of delayline is
	signal curAddr,nextAddr: unsigned(addrs-1 downto 0);
begin
	ram: ram1 port map(clock=>clk,data=>inp,rdaddress=>std_logic_vector(curAddr),
		wraddress=>std_logic_vector(curAddr),wren=>'1',q=>outp);
	curAddr <= nextAddr when falling_edge(clk);
	nextAddr <= curAddr+1;
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemMono;
use work.delayline;
use work.random;
entity delaytest is
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

architecture a of delaytest is
	signal ain,aout: signed(23 downto 0);
	signal tmpout: signed(32 downto 0);
	signal delayout: std_logic_vector(31 downto 0);
	signal aclk: std_logic;
	signal rand: std_logic_vector(9 downto 0);
	signal sawtooth: unsigned(10 downto 0);
begin
	audio1: AudioSubSystemMono port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),MonoIn=>ain,
			RawOut=>std_logic_vector(aout)&std_logic_vector(aout),SamClk=>aclk);
	delay: delayline generic map(b=>32,addrs=>13)
		port map(inp=>std_logic_vector(ain),outp=>delayout,clk=>aclk);
	random1: random generic map(b=>10) port map(clk => aclk, outp => rand);
	sawtooth <= sawtooth+unsigned(SW) when falling_edge(aclk);
	
	tmpout <= signed(delayout&"0")+(ain(31)&ain);
		--+signed((16 downto 10=>rand(9))&rand)+signed("0"&sawtooth);
	aout <= tmpout(32 downto 1) when falling_edge(aclk);
end architecture;
