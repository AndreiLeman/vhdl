library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.slow_clock;
use work.fsm;
use work.fib;
use work.hexdisplay;

entity mytest1 is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(17 downto 0);
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(17 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7: out std_logic_vector(6 downto 0));
end entity;
architecture a of mytest1 is
	signal sclk,fclk: std_logic;
	signal K: std_logic_vector(3 downto 0);
	--signal cnt1,cnt2: unsigned(3 downto 0);
	
	signal asdfg: unsigned(127 downto 0);
begin
	K <= not KEY;
	--cnt1 <= cnt2 when rising_edge(sclk);
	--cnt2 <= cnt1+1;
	--LEDR(9 downto 6) <= std_logic_vector(cnt1);
	
	--pll1: altpll1 port map(inclk0 => CLOCK_50, c0 => fclk);
	fclk <= CLOCK_50;
	c: slow_clock port map(clk => fclk, o => sclk);
	--sclk <= CLOCK_50;
	
	LEDR(0) <= sclk;
	a: fsm port map(clk => sclk,
						inp => K(0),
						outp => LEDR(1),
						state => LEDR(5 downto 2));
						
						
	h0: hexdisplay port map(inp=>asdfg(3 downto 0),outp=>HEX7);
	h1: hexdisplay port map(inp=>asdfg(7 downto 4),outp=>HEX6);
	h2: hexdisplay port map(inp=>asdfg(11 downto 8),outp=>HEX5);
	h3: hexdisplay port map(inp=>asdfg(15 downto 12),outp=>HEX4);
	h4: hexdisplay port map(inp=>asdfg(19 downto 16),outp=>HEX3);
	h5: hexdisplay port map(inp=>asdfg(23 downto 20),outp=>HEX2);
	h6: hexdisplay port map(inp=>asdfg(27 downto 24),outp=>HEX1);
	h7: hexdisplay port map(inp=>asdfg(31 downto 28),outp=>HEX0);
	fib1: fib port map(clk=>sclk,outp=>asdfg);
end;
