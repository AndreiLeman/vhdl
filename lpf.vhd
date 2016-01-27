library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;

--rom must have pipeline register (data output register)
--and must have a delay of 2 cycles
entity lpf is
	generic(clkDivision: integer;
				romSize: integer; --# of sample groups in rom
				bits: integer := 8
				);
	port(inp: in signed(bits-1 downto 0);
			inclk: in std_logic;
			outp: out signed(bits-1 downto 0);
			outclk: out std_logic;
			
			rom_addr1,rom_addr2: out unsigned(integer(ceil(log2(real(clkDivision))))-1 downto 0);
			rom_clk: out std_logic;
			rom_q1,rom_q2: in signed(8*romSize-1 downto 0));
end entity;
architecture a of lpf is
	constant convSize: integer := romSize*clkDivision;
	constant addrBits: integer := integer(ceil(log2(real(clkDivision))));
	signal cnt,addr1,addr2: unsigned(addrBits-1 downto 0);
	type arr is array(integer range <>)	of signed(7 downto 0);
	type arr2 is array(integer range <>) of signed((bits+8-1) downto 0);
	signal romOut: arr(romSize*2-1 downto 0); --index 0 is newest
	signal multOut: arr2(romsize*2-1 downto 0);
	signal curData,newData: arr2(romsize*2-1 downto 0);
	signal shouldShift,ss1,ss2,ss3,ss4: std_logic;
	signal outp1: signed(bits-1 downto 0);
begin
	rom_clk <= inclk;
	cnt <= to_unsigned(0,addrBits) when cnt=clkDivision-1 and rising_edge(inclk)
		else cnt+1 when rising_edge(inclk);
	addr1 <= clkDivision-cnt-1 when rising_edge(inclk);
	addr2 <= cnt when rising_edge(inclk);
	rom_addr1 <= addr1;
	rom_addr2 <= addr2;
	ss1 <= '1' when cnt=0 else '0';
	ss2 <= ss1 when rising_edge(inclk);
	ss3 <= ss2 when rising_edge(inclk);
	ss4 <= ss3 when rising_edge(inclk);
	shouldShift <= ss4 when rising_edge(inclk);
gen_rom:
	for I in 0 to romSize-1 generate
		romOut(I) <= rom_q1((romSize-I)*8-1 downto (romSize-I-1)*8) when rising_edge(inclk);
		romOut(romSize+I) <= rom_q2((I+1)*8-1 downto I*8) when rising_edge(inclk);
	end generate;
gen_mult:
	for I in 0 to romsize*2-1 generate
		multOut(I) <= inp*romOut(I) when rising_edge(inclk);
	end generate;

gen_chain:
	for I in 1 to romsize*2-1 generate
		newData(I) <= curData(I)+multOut(I)((bits+8-1) downto 7);
		curData(I) <= newData(I-1) when shouldShift='1' and rising_edge(inclk)
				else newData(I) when rising_edge(inclk);
	end generate;
	newData(0) <= curData(0)+multOut(0)((bits+8-1) downto 7);
	curData(0) <= to_signed(0,bits+8) when shouldShift='1' and rising_edge(inclk)
				else newData(0) when rising_edge(inclk);
	outp1 <= curData(romsize*2-1)((bits+8-1) downto 8) when shouldShift='1' and rising_edge(inclk);
	outp <= outp1 when rising_edge(shouldShift);
	outclk <= shouldShift;
end architecture;
