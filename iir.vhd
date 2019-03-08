library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity iir is
	generic(bits: integer := 12;
			bitGrowth: integer := 4);
    Port (clk: in std_logic;
		inp: in signed(bits-1 downto 0);
		outp: out signed(bits+bitGrowth-1 downto 0)
		);
end;

architecture a of iir is
	constant coeffBits: integer := 12;
	constant internalBits: integer := bits+bitGrowth;
	constant order: integer := 15;
	
	
	-- coefficients
	type coeffArrInt is array(0 to order-1) of integer;
	signal coeffAint, coeffBint: coeffArrInt;
	type coeffArr is array(0 to order-1) of signed(coeffBits-1 downto 0);
	signal coeffB, coeffA: coeffArr;
	
	-- nonrecursive part (FIR filter)
	type arrSrIn is array(0 to order*2-1) of signed(bits-1 downto 0);
	signal firSrIn: arrSrIn; -- new values come in at 0
	type multArr is array(0 to order-1) of signed(bits+coeffBits-1 downto 0);
	signal firMult1: multArr;
	type addArr is array(0 to order-1) of signed(internalBits-1 downto 0);
	signal firTrunc1,firAdd1: addArr;
	
	-- recursive part
	signal iirOut: signed(internalBits-1 downto 0);
	type iirMultArr is array(0 to order-1) of signed(internalBits+coeffBits-1 downto 0);
	signal iirMult1: iirMultArr;
	type iirSumArr is array(0 to order-1) of signed(internalBits-1 downto 0);
	signal iirSum1: iirSumArr;
begin

	-- coefficients
	coeffAint <= (0, -1, 0, 62, 344, 962, 1703, 2047, 1703, 962, 344, 62, 0, -1, 0);
	coeffBint <= (0, 0, 0, 16, 86, 241, 426, 512, 426, 241, 86, 16, 0, 0, 0);
g0:
	for I in 0 to order-1 generate
		coeffA(I) <= to_signed(coeffAint(I), coeffBits);
		coeffB(I) <= to_signed(coeffBint(I), coeffBits);
	end generate;

	--#################################
	--###### FIR filter
	--#################################
	
	-- input shift register
	firSrIn <= (inp) & firSrIn(0 to order*2-2) when rising_edge(clk);
	
	-- multipliers
g1:
	for I in 0 to order-1 generate
		firMult1(I) <= firSrIn(I*2+1) * coeffB(I) when rising_edge(clk);
		firTrunc1(I) <= firMult1(I)(firMult1(I)'left downto firMult1(I)'left-internalBits+1);
	end generate;
	
	-- adders
g3:
	for I in 1 to order-1 generate
		firAdd1(I) <= firTrunc1(I) + firAdd1(I-1) when rising_edge(clk);
	end generate;
	firAdd1(0) <= firTrunc1(0) when rising_edge(clk);
	
	--#################################
	--###### recursive filter
	--#################################
g4:
	for I in 1 to order-1 generate
		iirMult1(I) <= iirOut*coeffA(I);
		iirTrunc1(I) <= iirMult1(I)(iirMult1(I)'left downto iirMult1(I)'left-internalBits+1);
	end generate;
g5:
	for I in 1 to order-2 generate
		iirSum1(I) <= iirSum1(I+1) + iirTrunc1(I) when rising_edge(clk);
	end generate;
	
	-- todo: recursive part
	outp <= firAdd1(order-1) when rising_edge(clk);
end a;
