Library ieee;
Use ieee.std_logic_1164.all;
Use ieee.numeric_std.all;

entity Clipper is
	port(inp: std_logic_vector(3 downto 0);
			gainL,gainR: out signed(4 downto 0));
end entity;
architecture a of Clipper is
	signal tmp: signed(4 downto 0);
	signal clipped: signed(4 downto 0);
begin
	tmp <= signed("0" & inp);
	clipped <= tmp when tmp<"01000" else "01000";
	gainL <= clipped;
	gainR <= "01000"-clipped;
end architecture;
