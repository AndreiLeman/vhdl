library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic;
use work.fft16_serial3;
use work.twiddleGenerator;
use work.twiddleRom256;
use work.transposer;

-- data input/output order is transposed order: 0,4,8,12,1,5,9,13,...
-- phase should be 0,1,2,3,4,5,6,...
-- output values are normalized to 1/sqrt(n)
-- delay is fft16_delay + 256 + mult_delay + 16 + fft16_delay cycles
entity fft256_serial is
	generic(dataBits: integer := 24);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(7 downto 0);
		dout: out complex;
		phaseOut: out unsigned(7 downto 0)
		);
end entity;

architecture ar of fft256_serial is
	constant twiddleBits: integer := 12;
	constant N: integer := 256;
	constant subN: integer := 16;
	constant order: integer := 8;
	constant subOrder: integer := 4;
	constant subSubOrder: integer := 2;
	constant transposerDelay: integer := subN;
	
	signal subIn1,subIn2,subTransposedIn2: complex;
	signal subPhase1,subPhase2: unsigned(subOrder-1 downto 0);
	signal subOut1,subOut2: complex;
	
	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;
	
	signal romAddr: unsigned(4 downto 0);
	signal romData: std_logic_vector(21 downto 0);
	
	signal bitPermIn,bitPermOut: unsigned(subOrder-1 downto 0);
begin
	fft: entity fft3step_bram_generic generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder=>subOrder,
			twiddleDelay=>6,
			subDelay=>44,
			customSubOrder=>true)
		port map(
			clk, din, phase, dout, phaseOut,
			subIn1,subIn2,subPhase1,subPhase2,subOut1,subOut2,
			twAddr,twData,
			bitPermIn,bitPermOut
			);
	
	-- sub-fft accepts data and outputs data in transposed order
	bitPermOut <= bitPermIn(subSubOrder-1 downto 0) & bitPermIn(bitPermIn'left downto subSubOrder);
	
	subFFT1: entity fft16_serial3
		generic map(dataBits=>dataBits, scale=>SCALE_NONE)
		port map(clk,subIn1,subPhase1,subOut1);
	
	-- sub-fft 2 must accept data in linear order, so we need to transpose the input
	transp: entity transposer
		generic map(subSubOrder, subSubOrder, dataBits)
		port map(clk,subIn2,subPhase2,subTransposedIn2);
	
	subFFT2: entity fft16_serial3
		generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
		port map(clk,subTransposedIn2,subPhase2,subOut2);
	
	tw: entity twiddleGenerator generic map(twiddleBits, order)
		port map(clk, twAddr, twData, romAddr, romData);
	rom: entity twiddleRom256 port map(clk, romAddr,romData);
end ar;
