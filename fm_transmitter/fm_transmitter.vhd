library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity generic_clock_divider is
	generic (bits: integer := 32);
	port (clk: in std_logic;
			period: in unsigned(bits-1 downto 0);
			o: out std_logic);
end;

architecture a of generic_clock_divider is
	signal cs,ns: unsigned(bits-1 downto 0);
	signal next_out: std_logic;
begin
	cs <= ns when rising_edge(clk);
	ns <= cs+1 when cs<period else to_unsigned(0,bits);
	next_out <= '1' when cs<("0"&period(bits-1 downto 1)) else '0';
	o <= next_out when rising_edge(clk);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.AudioSubSystemStereo;
use work.sineGenerator;
use work.hexdisplay;
entity fm_transmitter is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in unsigned(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			GPIO_0,GPIO_1: inout std_logic_vector(0 to 35));
end entity;
architecture a of fm_transmitter is
	component pll_100 is
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component pll_100;
	component pll_300 is
		PORT
		(
			inclk0		: IN STD_LOGIC  := '0';
			c0		: OUT STD_LOGIC 
		);
	end component pll_300;

	signal sclk,clk,aclk: std_logic;
	signal asdfg: unsigned(63 downto 0);
	signal r: std_logic_vector(9 downto 0);
	signal tmp: std_logic_vector(8 downto 0);
	signal n: unsigned(31 downto 0);
	signal tmp1: std_logic_vector(1 downto 0);
	signal a1,a2,a3: std_logic;
	signal CLOCK_1,CLOCK_100,CLOCK_1K: std_logic;
	signal CLOCK_300: std_logic;
	signal fm_freq: unsigned(27 downto 0);
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	signal ain: signed(16 downto 0);
	signal ain_scaled: signed(27 downto 0);
	signal fm1: signed(8 downto 0);
	signal fm2: unsigned(8 downto 0);
	signal base_freq: unsigned(27 downto 0);
	
	signal freq_int,freq_int_d0,freq_int_d1,freq_int_d2: unsigned(6 downto 0);
	signal lastk3,lastk2,k3,k2: std_logic;
	signal freq_f: unsigned(3 downto 0);
	signal freq_int1,freq_f1,freq_sum: unsigned(31 downto 0);
begin
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	ain <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
	ain_scaled <= ain*("0"&signed(SW(4 downto 0)*SW(4 downto 0))) when rising_edge(aclk);
	
	pll: pll_100 port map(CLOCK_50,CLOCK_100);
	pll2: pll_300 port map(CLOCK_50,CLOCK_300);
	clk <= CLOCK_50;
	
	freq_int <= SW(9 downto 5)+to_unsigned(80,7);
	freq_int1 <= freq_int*to_unsigned(14316558,25);
	
	lastk3 <= KEY(3) when rising_edge(CLOCK_50);
	lastk2 <= KEY(2) when rising_edge(CLOCK_50);
	k3 <= '1' when KEY(3)='0' and lastk3='1' and rising_edge(CLOCK_50) else
		'0' when rising_edge(CLOCK_50);
	k2 <= '1' when KEY(2)='0' and lastk2='1' and rising_edge(CLOCK_50) else
		'0' when rising_edge(CLOCK_50);
	freq_f <= freq_f-1 when k3='1' and (not (freq_f=0)) and rising_edge(CLOCK_50) else
		freq_f+1 when k2='1' and (not (freq_f=9)) and rising_edge(CLOCK_50);
	freq_f1 <= freq_f*to_unsigned(1431655,28);
	freq_sum <= freq_int1+freq_f1;
	
	freq_int_d2 <= freq_int/100;
	freq_int_d1 <= (freq_int/10) mod 10;
	freq_int_d0 <= freq_int mod 10;
	hd0: hexdisplay port map(freq_f,HEX0);
	hd1: hexdisplay port map(freq_int_d0(3 downto 0),HEX1);
	hd2: hexdisplay port map(freq_int_d1(3 downto 0),HEX2);
	hd3: hexdisplay port map(freq_int_d2(3 downto 0),HEX3);
	HEX4 <= (others=>'1');
	HEX5 <= (others=>'1');
	
	base_freq <= freq_sum(31 downto 4);
	fm_freq <= base_freq+((5 downto 0=>ain_scaled(27))&unsigned(ain_scaled(27 downto 6)))
		when rising_edge(aclk);
	sg: sineGenerator port map(CLOCK_300,fm_freq,fm1);
	fm2 <= unsigned(fm1)+"100000000" when rising_edge(CLOCK_300);
	--GPIO_1(2 to 10) <= std_logic_vector(fm2);
	GPIO_1(11 to 35) <= (others=>'0');
	GPIO_1(0 to 1) <= (others=>'0');
	
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= '1';
	VGA_R <= fm2(8 downto 1) when falling_edge(CLOCK_300);
	VGA_G <= fm2(8 downto 1) when falling_edge(CLOCK_300);
	VGA_B <= fm2(8 downto 1) when falling_edge(CLOCK_300);
	VGA_CLK <= CLOCK_300;
end;
