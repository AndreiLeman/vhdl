library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic;
use work.fft4_serial3;
use work.twiddleGenerator;
use work.twiddleRom16;
use work.twiddleGenerator16;

-- data input order: 0,8,4,12,1,9,5,13,...
-- phase should be 0,1,2,3,4,5,6,...
-- output values are normalized to 1/sqrt(n)
-- delay is fft4_delay + 16 + mult_delay + fft4_delay cycles
entity fft16_serial2 is
	generic(dataBits: integer := 18);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(3 downto 0);
		dout: out complex;
		phaseOut: out unsigned(3 downto 0)
		);
end entity;

architecture ar of fft16_serial2 is
	constant twiddleBits: integer := 12;
	constant N: integer := 16;
	constant subN: integer := 4;
	constant order: integer := 4;
	constant subOrder: integer := 2;
	
	signal subIn1,subIn2: complex;
	signal subPhase1,subPhase2: unsigned(subOrder-1 downto 0);
	signal subOut1,subOut2: complex;
	
	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;
	
	signal romAddr: unsigned(0 downto 0);
	signal romData: std_logic_vector(21 downto 0);
	
	signal bitPermIn,bitPermOut: unsigned(1 downto 0);
begin
	fft: entity fft3step_bram_generic generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder=>subOrder,
			twiddleDelay=>2,
			subDelay=>11,
			customSubOrder=>true)
		port map(
			clk, din, phase, dout, phaseOut,
			subIn1,subIn2,subPhase1,subPhase2,subOut1,subOut2,
			twAddr,twData,
			bitPermIn,bitPermOut
			);
	
	bitPermOut <= reverse_bits(bitPermIn);
	
	subFFT1: entity fft4_serial3
		generic map(dataBits=>dataBits, bitReversedOrder=>true)
		port map(clk,subIn1,subPhase1,subOut1);
	
	subFFT2: entity fft4_serial3
		generic map(dataBits=>dataBits, bitReversedOrder=>false)
		port map(clk,subIn2,subPhase2,subOut2);
	
	tw: entity twiddleGenerator16 port map(clk, twAddr, twData);
	--tw: entity twiddleGenerator generic map(twiddleBits, order)
	--	port map(clk, twAddr, twData, romAddr, romData);
	--rom: entity twiddleRom16 port map(clk, romAddr,romData);
end ar;
