library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity slow_clock3 is
	generic (bits: integer := 32);
	port (clk: in std_logic;
			period1: in unsigned(bits-1 downto 0); --off
			period2: in unsigned(bits-1 downto 0); --on
			o: out std_logic);
end;
architecture a of slow_clock3 is
	signal period,cs,ns: unsigned(bits downto 0);
	signal next_out: std_logic;
begin
	cs <= ns when rising_edge(clk);
	ns <= cs+1 when cs<period else to_unsigned(0,bits+1);
	period <= ("0"&period1)+("0"&period2);
	
	next_out <= '1' when cs<("0"&period2) else '0';
	o <= next_out when rising_edge(clk);
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.hexdisplay;
use work.base10_display;
use work.simple_altera_pll;
use work.slow_clock3;
entity test4 is
	port(GPIO_0,GPIO_1: inout std_logic_vector(35 downto 0);
			CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			SW: in std_logic_vector(9 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0);
			VGA_CLK,VGA_SYNC_N,VGA_BLANK_N,VGA_VS,VGA_HS: out std_logic;
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0));
end entity;

architecture a of test4 is
	signal cnt2: unsigned(31 downto 0);
	signal CLOCK_200,CLOCK_4,led_out,led_out0: std_logic;
begin
	pll: simple_altera_pll generic map("50 MHz","200 MHz") port map(CLOCK_50,CLOCK_200);
	pll2: simple_altera_pll generic map("50 MHz","4 MHz") port map(CLOCK_50,CLOCK_4);
	GPIO_1(2) <= CLOCK_4;
	GPIO_1(3) <= not CLOCK_4;
	--GPIO_1(3) <= led_out;
	--GPIO_1(5) <= not led_out;
	--GPIO_1(2) <= '1';
	--GPIO_1(4) <= '0';
	sc: slow_clock3 generic map(10) port map(CLOCK_200,unsigned(SW),unsigned(SW),led_out0);
	led_out <= led_out0; --CLOCK_200 when SW="0000000000" else led_out0;
	LEDR <= (others=>led_out);
end architecture;
