library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity slow_clock2 is
	generic (bits: integer := 32);
	port (clk: in std_logic;
			period: in unsigned(bits-1 downto 0);
			o: out std_logic);
end;

architecture a of slow_clock2 is
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
use work.slow_clock;
use work.slow_clock2;
use work.hexdisplay;
use work.counter;
use work.AudioSubSystemStereo;

entity mytest2 is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0);
			AUD_XCK : out std_logic;
			FPGA_I2C_SCLK : out std_logic;
			FPGA_I2C_SDAT : inout std_logic;
			AUD_BCLK, AUD_ADCLRCK, AUD_DACLRCK, AUD_ADCDAT : in std_logic;
			AUD_DACDAT : out std_logic;
			IRDA_RXD: in std_logic;
			GPIO_0: inout std_logic_vector(35 downto 0));
end entity;
architecture a of mytest2 is
	component pll_100m is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic         -- clk
		);
	end component pll_100m;
	component pll_300m is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic         -- clk
		);
	end component pll_300m;

	signal sclk,clk,aclk: std_logic;
	signal asdfg: unsigned(63 downto 0);
	signal r: std_logic_vector(9 downto 0);
	signal tmp: std_logic_vector(8 downto 0);
	signal n: unsigned(31 downto 0);
	signal tmp1: std_logic_vector(1 downto 0);
	signal a1,a2,a3: std_logic;
	signal CLOCK_1,CLOCK_100,CLOCK_1K: std_logic;
	signal CLOCK_300,fm1: std_logic;
	signal fm_period: unsigned(8 downto 0);
	signal ainL,ainR,aoutL,aoutR: signed(15 downto 0);
	signal ain: signed(16 downto 0);
begin
	audio1: AudioSubSystemStereo port map(CLOCK_50=>CLOCK_50, AudMclk=>AUD_XCK,
			I2C_Sclk=>FPGA_I2C_SCLK,I2C_Sdat=>FPGA_I2C_SDAT,Bclk=>AUD_BCLK,AdcLrc=>AUD_ADCLRCK,
			DacLrc=>AUD_DACLRCK,AdcDat=>AUD_ADCDAT,DacDat=>AUD_DACDAT, Init=>not KEY(0),AudioInL=>ainL,
			AudioInR=>ainR,AudioOutL=>aoutL,AudioOutR=>aoutR,SamClk=>aclk);
	ain <= (ainL(15)&ainL)+(ainR(15)&ainR) when rising_edge(aclk);
			
	cnt: counter generic map(N=>32,max=>9) port map(clk=>not KEY(3),outp=>n);
	pll: pll_100m port map(refclk=>CLOCK_50,outclk_0=>CLOCK_100);
	pll2: pll_300m port map(refclk=>CLOCK_50,outclk_0=>CLOCK_300);
	clk <= CLOCK_50;
	c: slow_clock generic map(20000000,10000000) port map(clk => CLOCK_50, o => sclk);
	c2: slow_clock generic map(50,25) port map(clk => CLOCK_50, o => CLOCK_1);
	c3: slow_clock2 generic map(32) port map(clk => CLOCK_50, o => CLOCK_1K,
		period=>"00000000000000"&unsigned(SW)&"00000000");
	fm: slow_clock2 generic map(9) port map(clk=>CLOCK_300,o=>fm1,period=>fm_period);
	
	fm_period <= unsigned(ain(12 downto 4))+to_unsigned(300,9) when rising_edge(CLOCK_300);
	LEDR(9 downto 1) <= std_logic_vector(ain(11 downto 3)) when ain>0 else std_logic_vector(-ain(11 downto 3));
	
	--asdfg <= asdfg+1 when rising_edge(fclk);
	
	--h2: hexdisplay port map(inp=>asdfg(27 downto 24),outp=>HEX0);
	--h3: hexdisplay port map(inp=>asdfg(31 downto 28),outp=>HEX1);
	--h4: hexdisplay port map(inp=>asdfg(35 downto 32),outp=>HEX2);
	--h5: hexdisplay port map(inp=>asdfg(39 downto 36),outp=>HEX3);
	--h6: hexdisplay port map(inp=>asdfg(43 downto 40),outp=>HEX4);
	--h7: hexdisplay port map(inp=>asdfg(47 downto 44),outp=>HEX5);
	
	--rand: random generic map(b=>10) port map(clk=>CLOCK_50,outp=>r);
	--LEDR <= r when rising_edge(sclk);
	tmp <= "011000000";
	--LEDR(0) <= sclk;
	LEDR(0) <= not IRDA_RXD;
	--GPIO_0(9 downto 0) <= SW(9 downto 0);
	GPIO_0(5) <= CLOCK_100 xor fm1;
	--iob: altlvds_tx1 port map(tx_in=>SW(3 downto 0),tx_inclock=>CLOCK_50,tx_out=>tmp1(0 downto 0));
	--GPIO_0(7) <= tmp1(0);
	--LEDR(1 to 8) <= std_logic_vector(to_unsigned(1,8));
	--a1 <= not a1;
	--LEDR(1) <= a1 when rising_edge(sclk);
	--hd: de1_hexdisplay generic map(b=>8) 
	--	port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
	--		data=>std_logic_vector(n),button1=>not KEY(1),button2=>not KEY(0));
end;
