library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft4;
use work.fft4_noPipeline;

-- data appears 11 cycles after the first input word
-- output values are normalized to 1/sqrt(n);
-- input data should be in linear order if bitReversedOrder is false, 0-2-1-3 order otherwise.

-- be sure to add a multi-cycle timing constraint of 4 cycles
-- from fftIn_mCycle/Q to fftOut_mCycle/D:
-- set_multicycle_path -from [get_pins -hierarchical *fftIn_mCycle*/C] -to [get_pins -hierarchical *fftOut_mCycle*/D] -setup 4
-- set_multicycle_path -from [get_pins -hierarchical *fftIn_mCycle*/C] -to [get_pins -hierarchical *fftOut_mCycle*/D] -hold 3

entity fft4_serial3 is
	generic(dataBits: integer := 18;
			bitReversedOrder: boolean := false);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(1 downto 0);
		dout: out complex
		);
end entity;

architecture ar of fft4_serial3 is
	signal ph1: unsigned(1 downto 0);
	signal shiftIn,fftIn_mCycle,fftOut0,fftOut_mCycle: complexArray(3 downto 0);
	signal fftIn_mCycle_reordered, fftOut0_reordered: complexArray(3 downto 0);
	signal shiftOut,shiftOutNext: complexArray(3 downto 0);
begin
	shiftIn <= din & shiftIn(3 downto 1) when rising_edge(clk);
	fftIn_mCycle <= shiftIn when phase=0 and rising_edge(clk);
	-- 5 cycle
	
g1: if bitReversedOrder generate
		fftIn_mCycle_reordered(0) <= fftIn_mCycle(0);
		fftIn_mCycle_reordered(1) <= fftIn_mCycle(2);
		fftIn_mCycle_reordered(2) <= fftIn_mCycle(1);
		fftIn_mCycle_reordered(3) <= fftIn_mCycle(3);
		fftOut0(0) <= fftOut0_reordered(0);
		fftOut0(1) <= fftOut0_reordered(2);
		fftOut0(2) <= fftOut0_reordered(1);
		fftOut0(3) <= fftOut0_reordered(3);
	end generate;
g2: if not bitReversedOrder generate
		fftIn_mCycle_reordered <= fftIn_mCycle;
		fftOut0 <= fftOut0_reordered;
	end generate;
	
	fft1: entity fft4_noPipeline generic map(dataBits)
		port map(fftIn_mCycle_reordered, fftOut0_reordered);
	fftOut_mCycle <= fftOut0 when phase=0 and rising_edge(clk);
	-- 9 cycles
	
	shiftOutNext <= fftOut_mCycle when phase=1 else
					to_complex(0,0) & shiftOut(3 downto 1);
	shiftOut <= shiftOutNext when rising_edge(clk);
	-- 10 cycles
	
	dout <= shiftOut(0) when rising_edge(clk);
	-- 11 cycles
end ar;
