library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.graphics_types.all;
--delay from p to outp is 4 cycles
--assumes ram delay is 1 cycle
entity generic_bar_display is
	port(clk: in std_logic;
			W,H: in unsigned(11 downto 0);
			p: in position;
			outp: out color; --registered
			ram_addr: out unsigned(11 downto 0);
			ram_data: in unsigned(11 downto 0)
			);
end entity;
architecture a of generic_bar_display is
	signal ram_data1: unsigned(11 downto 0);
	signal y1,y2: unsigned(11 downto 0);
	signal c1: color;
	signal tmp1: unsigned(11 downto 0);
	signal cnt: unsigned(5 downto 0);
	signal cnt2: unsigned(8 downto 0);
begin
	ram_addr <= p(0);
	ram_data1 <= ram_data when rising_edge(clk);
	y1 <= p(1) when rising_edge(clk);
	y2 <= y1 when rising_edge(clk);
	tmp1 <= ram_data1+y2 when rising_edge(clk);
	
	cnt <= "000000" when (p(0)=0 or cnt=39) and rising_edge(clk) else
		cnt+1 when rising_edge(clk);
	cnt2 <= "000000000" when (p(0)=0 or cnt2=399) and rising_edge(clk) else
		cnt2+1 when rising_edge(clk);
	
	c1(0) <= X"ff" when tmp1>H else X"00";
	c1(1) <= X"59" when cnt2=202 else
				X"aa" when cnt2=2 else X"00";
	c1(2) <= X"aa" when cnt=2 else X"00";
	outp <= c1 when rising_edge(clk);
end architecture;
