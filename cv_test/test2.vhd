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
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.base10_display;
use work.simple_altera_pll;
use work.slow_clock2;
entity test2 is
	port(GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0));
end entity;

architecture a of test2 is
	signal cnt,a1,a2,b1,b2,freq: unsigned(25 downto 0);
	signal display: unsigned(31 downto 0);
	signal cnt2: unsigned(31 downto 0);
	signal capture_en,CLOCK_200,led_out,led_out0: std_logic;
begin
	--GPIO_1(0) <= CLOCK_200;
	pll: simple_altera_pll generic map("50 MHz","200 MHz") port map(CLOCK_50,CLOCK_200);
	--pll1: simple_altera_pll generic map("50 MHz","100 MHz") port map(CLOCK_50,GPIO_1(1));
	--GPIO_1(2) <= CLOCK_50;
	--LEDR <= SW;
	cnt2 <= cnt2+1 when cnt2<5000000 and rising_edge(CLOCK_50) else
		(others=>'0') when rising_edge(CLOCK_50);
	capture_en <= '1' when cnt2<2000000 and rising_edge(CLOCK_50) else
		'0' when rising_edge(CLOCK_50);
	--GPIO_1 <= (others=>SW(0));
	--GPIO_1(5 downto 2) <= (others=>(KEY(0) and led_out));
	GPIO_1(3) <= led_out;
	GPIO_1(5) <= not led_out;
	GPIO_1(2) <= '1';
	GPIO_1(4) <= '0';
	sc: slow_clock2 generic map(13) port map(CLOCK_50,unsigned(SW)&"000",led_out0);
	led_out <= led_out0; --CLOCK_200 when SW="0000000000" else led_out0;
	LEDR <= (others=>led_out);
	
	cnt <= cnt+1 when falling_edge(GPIO_0(2));
	a1 <= cnt when rising_edge(capture_en);
	a2 <= a1 when rising_edge(capture_en);
	b1 <= cnt when rising_edge(CLOCK_200);
	b2 <= b1 when rising_edge(CLOCK_200);
	GPIO_1(0) <= '0' when b1=b2 else '1';
	freq <= a1-a2;
	disp: base10_display generic map(26,8) port map(freq,display);
	hd0: hexdisplay port map(display(11 downto 8),HEX0);
	hd1: hexdisplay port map(display(15 downto 12),HEX1);
	hd2: hexdisplay port map(display(19 downto 16),HEX2);
	hd3: hexdisplay port map(display(23 downto 20),HEX3);
	hd4: hexdisplay port map(display(27 downto 24),HEX4);
	hd5: hexdisplay port map(display(31 downto 28),HEX5);
	
	VGA_SYNC_N <= '0';
	VGA_BLANK_N <= '1';
	VGA_R <= unsigned(SW(7 downto 0));
	VGA_G <= unsigned(SW(7 downto 0));
	VGA_B <= unsigned(SW(7 downto 0));
	VGA_CLK <= CLOCK_50;
end architecture;
