library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity sin_rom is
	port(addr: in unsigned(8 downto 0);
			clk: in std_logic;
			q: out unsigned(7 downto 0));
end entity;
architecture a of sin_rom is
	type rom1t is array(0 to 511) of unsigned(7 downto 0);
	signal rom1: rom1t := 
	(X"00", X"01", X"02", X"03", X"04", X"04", X"05", X"06", X"07", X"07",
		X"08", X"09", X"0a", X"0b", X"0b", X"0c", X"0d", X"0e", X"0e", X"0f",
		X"10", X"11", X"12", X"12", X"13", X"14", X"15", X"15", X"16", X"17",
		X"18", X"19", X"19", X"1a", X"1b", X"1c", X"1c", X"1d", X"1e", X"1f",
		X"20", X"20", X"21", X"22", X"23", X"23", X"24", X"25", X"26", X"27",
		X"27", X"28", X"29", X"2a", X"2a", X"2b", X"2c", X"2d", X"2e", X"2e",
		X"2f", X"30", X"31", X"31", X"32", X"33", X"34", X"34", X"35", X"36",
		X"37", X"37", X"38", X"39", X"3a", X"3b", X"3b", X"3c", X"3d", X"3e",
		X"3e", X"3f", X"40", X"41", X"41", X"42", X"43", X"44", X"44", X"45",
		X"46", X"47", X"47", X"48", X"49", X"4a", X"4a", X"4b", X"4c", X"4d",
		X"4d", X"4e", X"4f", X"50", X"50", X"51", X"52", X"53", X"53", X"54",
		X"55", X"56", X"56", X"57", X"58", X"58", X"59", X"5a", X"5b", X"5b",
		X"5c", X"5d", X"5e", X"5e", X"5f", X"60", X"60", X"61", X"62", X"63",
		X"63", X"64", X"65", X"66", X"66", X"67", X"68", X"68", X"69", X"6a",
		X"6b", X"6b", X"6c", X"6d", X"6d", X"6e", X"6f", X"6f", X"70", X"71",
		X"72", X"72", X"73", X"74", X"74", X"75", X"76", X"76", X"77", X"78",
		X"79", X"79", X"7a", X"7b", X"7b", X"7c", X"7d", X"7d", X"7e", X"7f",
		X"7f", X"80", X"81", X"81", X"82", X"83", X"83", X"84", X"85", X"85",
		X"86", X"87", X"87", X"88", X"89", X"89", X"8a", X"8b", X"8b", X"8c",
		X"8d", X"8d", X"8e", X"8f", X"8f", X"90", X"91", X"91", X"92", X"93",
		X"93", X"94", X"94", X"95", X"96", X"96", X"97", X"98", X"98", X"99",
		X"99", X"9a", X"9b", X"9b", X"9c", X"9d", X"9d", X"9e", X"9e", X"9f",
		X"a0", X"a0", X"a1", X"a1", X"a2", X"a3", X"a3", X"a4", X"a4", X"a5",
		X"a6", X"a6", X"a7", X"a7", X"a8", X"a9", X"a9", X"aa", X"aa", X"ab",
		X"ac", X"ac", X"ad", X"ad", X"ae", X"ae", X"af", X"b0", X"b0", X"b1",
		X"b1", X"b2", X"b2", X"b3", X"b3", X"b4", X"b5", X"b5", X"b6", X"b6",
		X"b7", X"b7", X"b8", X"b8", X"b9", X"b9", X"ba", X"bb", X"bb", X"bc",
		X"bc", X"bd", X"bd", X"be", X"be", X"bf", X"bf", X"c0", X"c0", X"c1",
		X"c1", X"c2", X"c2", X"c3", X"c3", X"c4", X"c4", X"c5", X"c5", X"c6",
		X"c6", X"c7", X"c7", X"c8", X"c8", X"c9", X"c9", X"ca", X"ca", X"cb",
		X"cb", X"cc", X"cc", X"cd", X"cd", X"ce", X"ce", X"ce", X"cf", X"cf",
		X"d0", X"d0", X"d1", X"d1", X"d2", X"d2", X"d2", X"d3", X"d3", X"d4",
		X"d4", X"d5", X"d5", X"d6", X"d6", X"d6", X"d7", X"d7", X"d8", X"d8",
		X"d8", X"d9", X"d9", X"da", X"da", X"db", X"db", X"db", X"dc", X"dc",
		X"dd", X"dd", X"dd", X"de", X"de", X"de", X"df", X"df", X"e0", X"e0",
		X"e0", X"e1", X"e1", X"e1", X"e2", X"e2", X"e3", X"e3", X"e3", X"e4",
		X"e4", X"e4", X"e5", X"e5", X"e5", X"e6", X"e6", X"e6", X"e7", X"e7",
		X"e7", X"e8", X"e8", X"e8", X"e9", X"e9", X"e9", X"ea", X"ea", X"ea",
		X"eb", X"eb", X"eb", X"eb", X"ec", X"ec", X"ec", X"ed", X"ed", X"ed",
		X"ed", X"ee", X"ee", X"ee", X"ef", X"ef", X"ef", X"ef", X"f0", X"f0",
		X"f0", X"f0", X"f1", X"f1", X"f1", X"f2", X"f2", X"f2", X"f2", X"f2",
		X"f3", X"f3", X"f3", X"f3", X"f4", X"f4", X"f4", X"f4", X"f5", X"f5",
		X"f5", X"f5", X"f5", X"f6", X"f6", X"f6", X"f6", X"f6", X"f7", X"f7",
		X"f7", X"f7", X"f7", X"f8", X"f8", X"f8", X"f8", X"f8", X"f9", X"f9",
		X"f9", X"f9", X"f9", X"f9", X"fa", X"fa", X"fa", X"fa", X"fa", X"fa",
		X"fa", X"fb", X"fb", X"fb", X"fb", X"fb", X"fb", X"fb", X"fc", X"fc",
		X"fc", X"fc", X"fc", X"fc", X"fc", X"fc", X"fd", X"fd", X"fd", X"fd",
		X"fd", X"fd", X"fd", X"fd", X"fd", X"fd", X"fd", X"fe", X"fe", X"fe",
		X"fe", X"fe", X"fe", X"fe", X"fe", X"fe", X"fe", X"fe", X"fe", X"fe",
		X"fe", X"fe", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff",
		X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff", X"ff",
		X"ff", X"ff");
	signal addr1: unsigned(8 downto 0);
begin
	addr1 <= addr when rising_edge(clk);
	q <= rom1(to_integer(addr1));
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sin_rom;
entity sin is
	port(clk: in std_logic;
			t: in unsigned(11 downto 0); -- fraction only
			outp: out signed(8 downto 0)); -- output is sin(2*pi*t)*255
			-- delay is 3 clock cycles
end entity;
architecture a of sin is
	constant lutAddrBits: integer := 9;
	signal lut_addr: unsigned(lutAddrBits-1 downto 0);
	signal lut_q,lut_q1: unsigned(7 downto 0);
	signal out_tmp: signed(8 downto 0);
	signal invert1,invert2: std_logic;
begin
	lut_addr <= t(lutAddrBits-1 downto 0) when t(lutAddrBits)='0'
		else not t(lutAddrBits-1 downto 0);
	rom: sin_rom port map(lut_addr,clk,lut_q);
	lut_q1 <= lut_q when rising_edge(clk);
	invert1 <= t(lutAddrBits+1) when rising_edge(clk);
	invert2 <= invert1 when rising_edge(clk);
	
	out_tmp <= "0"&signed(lut_q1) when invert2='0' else
		("1"&signed(not lut_q1))+1;
	outp <= out_tmp when rising_edge(clk);
end architecture;
