
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity twiddleRom256 is
	port(clk: in std_logic;
			romAddr: in unsigned(5-1 downto 0);
			romData: out std_logic_vector(22-1 downto 0)
			);
end entity;
architecture a of twiddleRom256 is
	constant romDepthOrder: integer := 5;
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := 22;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal data0,data1: std_logic_vector(romWidth-1 downto 0) := (others=>'0');
begin
	addr1 <= romAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	romData <= data1;
	rom <= (
"0000011001011111111110" , "0000110010011111111101" , "0001001011111111111001" , "0001100100111111110101" , "0001111101111111110000" , "0010010110011111101001" , "0010101111011111100001" , "0011000111111111011000" , "0011100000111111001101" , "0011111000111111000010"
, "0100010001011110110101" , "0100101001011110100111" , "0101000001011110011000" , "0101011001011110000111" , "0101110000111101110110" , "0110000111111101100011" , "0110011111011101001111" , "0110110101111100111010" , "0111001100011100100100" , "0111100010111100001101"
, "0111111000111011110101" , "1000001110011011011100" , "1000100011111011000001" , "1000111000111010100110" , "1001001101111010001010" , "1001100001111001101100" , "1001110101111001001110" , "1010001001111000101110" , "1010011100111000001110" , "1010101111110111101101"
, "1011000001110111001011" , "1011010011110110100111"
);
end a;

