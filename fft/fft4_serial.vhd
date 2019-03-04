library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;

-- data appears 9 cycles after the first input word
-- output values are normalized to 1/sqrt(n);
-- input data can be in linear order or bit-reversed order.
-- for linear order, phase should be 0,1,2,3,0,1,2,3,...
-- for bit-reversed order, phase should be 0,2,1,3,0,2,1,3,...


entity fft4_serial is
	generic(dataBits: integer := 18);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft4_serial is
	signal a,aOrig,aMinus,aQuarter,aMinusQuarter: complex;
	signal ph0,ph1,ph2: unsigned(1 downto 0) := "00";
	signal res,resNext,toAdd,toAdd2: complexArray(3 downto 0);
	signal shiftOut,shiftOutNext: complexArray(3 downto 0);
	signal dout0: complex;
	
begin
	a <= din when rising_edge(clk);
	ph0 <= phase when rising_edge(clk);
	-- 1 cycle
	
	aOrig <= a when rising_edge(clk);
	aMinus <= -a when rising_edge(clk);
	aQuarter <= rotate_quarter(a) when rising_edge(clk);
	aMinusQuarter <= rotate_mquarter(a) when rising_edge(clk);
	ph1 <= ph0 when rising_edge(clk);
	-- 2 cycles
	
	-- 0: a0 + a1   + a2 + a3
	-- 1: a0 + a1*q - a2 - a3*q
	-- 2: a0 - a1   + a2 - a3
	-- 3: a0 - a1*q - a2 + a3*q
	
	toAdd(0) <= aOrig;
	toAdd(1) <= aOrig				when ph1=0 else
				aQuarter			when ph1=1 else
				aMinus				when ph1=2 else
				aMinusQuarter;		--when ph1=3;
	
	toAdd(2) <= aOrig 				when ph1=0 else
				aMinus				when ph1=1 else
				aOrig				when ph1=2 else
				aMinus				;--when ph1=3;
	
	toAdd(3) <= aOrig				when ph1=0 else
				aMinusQuarter		when ph1=1 else
				aMinus				when ph1=2 else
				aQuarter			;--when ph1=3;
	
	toAdd2 <= toAdd when rising_edge(clk);
	ph2 <= ph1 when rising_edge(clk);
	-- 3 cycles
	
gen1:
	for I in 0 to 3 generate
		resNext(I) <= toAdd2(I) when ph2=0 else
						res(I)+toAdd2(I);
	end generate;
	
	--resNext(0) <= a when ph=0 else
				--res(0) + a;
	
	--resNext(1) <= a							when ph=0 else
				--res(1) + rotate_quarter(a)	when ph=1 else
				--res(1) - a					when ph=2 else
				--res(1) - rotate_quarter(a);	--when ph=3;
	
	--resNext(2) <= a							when ph=0 else
				--res(2) - a					when ph=1 else
				--res(2) + a					when ph=2 else
				--res(2) - a					;--when ph=3;
	
	--resNext(3) <= a							when ph=0 else
				--res(3) - rotate_quarter(a)	when ph=1 else
				--res(3) - a					when ph=2 else
				--res(3) + rotate_quarter(a)	;--when ph=3;
	
	res <= resNext when rising_edge(clk);
	-- 4 cycles
	-- when ph2 is 0, res contains previous group of results
	
	shiftOutNext <= res when ph2=0 else
					to_complex(0,0) & shiftOut(3 downto 1);
	shiftOut <= shiftOutNext when rising_edge(clk);
	-- 5 cycles
	
	--dout <= saturate(shiftOut(0)/2, dataBits) when rising_edge(clk);
	dout <= keepNBits(shift_right(shiftOut(0),1), dataBits) when rising_edge(clk);
	-- 6 cycles
end ar;
