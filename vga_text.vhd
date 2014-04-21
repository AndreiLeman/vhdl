library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity vga_text is
	generic(wchars: integer; hchars: integer);
	port(clk: in std_logic;
			cx,cy: in unsigned(11 downto 0);
			VGA_R,VGA_G,VGA_B: out unsigned(7 downto 0));
end entity;
architecture a of vga_text is
	constant charw: integer;
begin
	
end architecture;

