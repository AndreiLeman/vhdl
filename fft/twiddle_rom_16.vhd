library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- read delay is 2 cycles

entity twiddleRom16 is
	port(clk: in std_logic;
			romAddr: in unsigned(1-1 downto 0);
			romData: out std_logic_vector(22-1 downto 0)
			);
end entity;
architecture a of twiddleRom16 is
	constant romDepthOrder: integer := 1;
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
"0110000111111101100011" , "1011010011110110100111"
);
end a;
