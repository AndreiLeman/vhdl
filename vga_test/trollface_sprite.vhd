library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity trollface_sprite_rom is
	port(clk: in std_logic;
			addr: in unsigned(13 downto 0);
			q: out std_logic);
end entity;
architecture a of trollface_sprite_rom is
	component trollface1_rom
		PORT (
			address		: IN STD_LOGIC_VECTOR (10 DOWNTO 0);
			clock		: IN STD_LOGIC  := '1';
			q		: OUT STD_LOGIC_VECTOR (7 DOWNTO 0)
		);
	end component;
	signal addr2: unsigned(2 downto 0);
	signal q1: std_logic_vector(7 downto 0);
	signal q2: std_logic_vector(0 to 7);
begin
	rom: trollface1_rom port map(address=>std_logic_vector(addr(13 downto 3)),clock=>clk,q=>q1);
	q2 <= q1;
	addr2 <= addr(2 downto 0) when rising_edge(clk);
	q <= q2(to_integer(addr2));
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.graphics_types.all;
use work.trollface_sprite_rom;
--128x128
--delay is 2 clock cycles
entity trollface_sprite is
	port(x,y: in unsigned(6 downto 0);
			clk: in std_logic;
			color: out color;
			transparent: out std_logic);
end entity;
architecture a of trollface_sprite is
	constant spriteW,spriteH: integer := 128;
	signal t: std_logic;
begin
	color <= (X"00",X"00",X"00");
	rom: trollface_sprite_rom port map(addr=>(y&x),
		clk=>clk,q=>t);
	transparent <= not t when rising_edge(clk);
end architecture;
