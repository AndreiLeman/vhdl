library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity hello is
	port(KEY: in std_logic_vector(3 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7: out std_logic_vector(6 downto 0);
			CLOCK_50: in std_logic);
end entity;
architecture a of hello is
	type dispt is array(7 downto 0) of std_logic_vector(6 downto 0);
	signal disp: dispt := ("1110001","0111110","0111001","0000000","1100110","0111111","0111110","0000000");
	signal trigger: std_logic;
begin
	trigger <= not KEY(0) when rising_edge(CLOCK_50);
	HEX0 <= not disp(0); HEX1 <= not disp(1); HEX2 <= not disp(2); HEX3 <= not disp(3);
	HEX4 <= not disp(4); HEX5 <= not disp(5); HEX6 <= not disp(6); HEX7 <= not disp(7);
gen_shifts:
	for I in 0 to 6 generate
		disp(I+1) <= disp(I) when rising_edge(trigger);
	end generate;
	disp(0) <= disp(7) when rising_edge(trigger);
end;


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity hello2 is
	port(KEY: in std_logic_vector(3 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5,HEX6,HEX7: out std_logic_vector(6 downto 0));
end entity;
architecture a of hello2 is
	type dispt is array(6 downto 0) of std_logic_vector(7 downto 0);
	
	--signal disp: dispt := ("1000111","0111110","1001110","0000000","0110011","1111110","0111110","0000000");
	signal disp: dispt := ("10100100","01001110","01001110","01100110","11100110","11101110","10001000");
begin
g0:for I in 0 to 6 generate
		HEX0(I) <= disp(I)(0);
	end generate;
g1:for I in 0 to 6 generate
		HEX1(I) <= disp(I)(1);
	end generate;
g2:for I in 0 to 6 generate
		HEX2(I) <= disp(I)(2);
	end generate;
g3:for I in 0 to 6 generate
		HEX3(I) <= disp(I)(3);
	end generate;
g4:for I in 0 to 6 generate
		HEX4(I) <= disp(I)(4);
	end generate;
g5:for I in 0 to 6 generate
		HEX5(I) <= disp(I)(5);
	end generate;
g6:for I in 0 to 6 generate
		HEX6(I) <= disp(I)(6);
	end generate;
g7:for I in 0 to 6 generate
		HEX7(I) <= disp(I)(7);
	end generate;
gen_shifts:
	for I in 0 to 6 generate
		disp(I) <= disp(I)(0) & disp(I)(7 downto 1) when rising_edge(KEY(0));
	end generate;
end;
