
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
-- read delay is 2 cycles

entity twiddleGenerator16 is
	port(clk: in std_logic;
			twAddr: in unsigned(4-1 downto 0);
			twData: out complex
			);
end entity;
architecture a of twiddleGenerator16 is
	constant romDepthOrder: integer := 4;
	constant romDepth: integer := 2**romDepthOrder;
	constant twiddleBits: integer := 12;
	constant romWidth: integer := twiddleBits*2;
	--ram
	type ram1t is array(0 to romDepth-1) of
		std_logic_vector(romWidth-1 downto 0);
	signal rom: ram1t;
	signal addr1: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal data0,data1: std_logic_vector(romWidth-1 downto 0) := (others=>'0');
begin
	addr1 <= twAddr when rising_edge(clk);
	data0 <= rom(to_integer(addr1));
	data1 <= data0 when rising_edge(clk);
	twData <= to_complex(signed(data1(twiddleBits-1 downto 0)), signed(data1(data1'left downto twiddleBits)));
	rom <= (
"000000000000011111111111" , "001100001111011101100011" , "010110100111010110100111" , "011101100011001100001111" , "011111111111000000000000" , "011101100011110011110001" , "010110100111101001011001" , "001100001111100010011101" , "000000000000100000000001" , "110011110001100010011101"
, "101001011001101001011001" , "100010011101110011110001" , "100000000001000000000000" , "100010011101001100001111" , "101001011001010110100111" , "110011110001011101100011"
);
end a;

