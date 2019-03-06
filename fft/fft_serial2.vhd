library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft4;

-- data appears 7 cycles after the first input word
-- output values are normalized to 1/sqrt(n);
-- input data should be in linear order.
entity fft4_serial2 is
	generic(dataBits: integer := 18);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;

architecture ar of fft4_serial2 is
	signal shiftIn,fftIn,fftOut: complexArray(3 downto 0);
	signal shiftOut,shiftOutNext: complexArray(3 downto 0);
begin
	shiftIn <= din & shiftIn(3 downto 1) when rising_edge(clk);
	fftIn <= shiftIn;
	-- 1 cycle
	
	fft1: entity fft4 generic map(dataBits)
		port map(clk, fftIn, fftOut);
	-- 4 cycles
	
	shiftOutNext <= fftOut when ph=0 else
					to_complex(0,0) & shiftOut(3 downto 1);
	shiftOut <= shiftOutNext when rising_edge(clk);
	-- 5 cycles
	
	dout <= keepNBits(shiftOut(0)/2, dataBits) when rising_edge(clk);
	-- 6 cycles
end ar;
