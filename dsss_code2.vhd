library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--delay: 2 cycles
entity dsssCode2Outer is
	port(clk: in std_logic;
		addr: in unsigned(6 downto 0);
		data: out std_logic);
end entity;

architecture a of dsssCode2Outer is
	signal rom: std_logic_vector(127 downto 0);
	signal addr1: unsigned(6 downto 0);
	signal data1: std_logic;
begin
	addr1 <= addr when rising_edge(clk);
	data1 <= rom(to_integer(addr1));
	data <= data1 when rising_edge(clk);

	-- ########### WARNING ##########
	-- CODE IS REVERSED!!!!!!!!!! "rom" is declared as "downto"
	rom <=
		"1110000100100010001000010011111110011001011011110010000110110001" &
		"0110101010010110100101111101101111101010100010011000110110011000";
end architecture;


library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--delay: 2 cycles
entity dsssCode2Inner is
	port(clk: in std_logic;
		addr: in unsigned(6 downto 0);
		data: out std_logic);
end entity;

architecture a of dsssCode2Inner is
	signal rom: std_logic_vector(127 downto 0);
	signal addr1: unsigned(6 downto 0);
	signal data1: std_logic;
begin
	addr1 <= addr when rising_edge(clk);
	data1 <= rom(to_integer(addr1));
	data <= data1 when rising_edge(clk);
	
	-- ########### WARNING ##########
	-- CODE IS REVERSED!!!!!!!!!! "rom" is declared as "downto"
	rom <= "1111001101101001100001011101011011110110000100001110011101111000" &
			"1011101000011111010100000010001010010001001111010111100101010000";
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.dsssCode2Outer;
use work.dsssCode2Inner;
--delay: 2 cycles
entity dsssCode2Combined is
	port(clk: in std_logic;
		addr: in unsigned(13 downto 0);
		data: out std_logic);
end entity;

architecture a of dsssCode2Combined is
	signal data1,data2: std_logic;
begin
	outer: entity dsssCode2Outer port map(clk,addr(6 downto 0),data1);
	inner: entity dsssCode2Inner port map(clk,addr(13 downto 7),data2);
	data <= data1 xor data2;
end architecture;
