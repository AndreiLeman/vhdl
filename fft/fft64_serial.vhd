library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic2;
use work.fft4_serial3;
use work.fft16_serial3;
use work.twiddleGenerator;
use work.twiddleRom64;

-- data input/output are in transposed order, with columns also in transposed order:
-- 0, 16, 32, 48, 4, 20, 36, 52, ..., 1, 17, 31, 49, ...
-- phase should be 0,1,2,3,4,5,6,...
-- output values are normalized to 1/sqrt(n)
-- delay is fft16_delay + 64 + mult_delay + fft4_delay cycles
entity fft64_serial is
	generic(dataBits: integer := 18);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(5 downto 0);
		dout: out complex;
		phaseOut: out unsigned(5 downto 0)
		);
end entity;

architecture ar of fft64_serial is
	constant twiddleBits: integer := 12;
	constant N: integer := 64;
	constant subN1: integer := 16;
	constant subN2: integer := 4;
	constant order: integer := 6;
	constant subOrder1: integer := 4;
	constant subOrder2: integer := 2;
	constant subSubOrder1: integer := 2;
	
	signal subIn1,subIn2: complex;
	signal subPhase1: unsigned(subOrder1-1 downto 0);
	signal subPhase2: unsigned(subOrder2-1 downto 0);
	signal subOut1,subOut2: complex;
	
	signal bitPermIn,bitPermOut: unsigned(subOrder1-1 downto 0);
	
	-- twiddle generator
	signal twAddr: unsigned(order-1 downto 0);
	signal twData: complex;
	
	signal romAddr: unsigned(2 downto 0);
	signal romData: std_logic_vector(21 downto 0);
begin
	fft: entity fft3step_bram_generic2 generic map(
			dataBits=>dataBits,
			twiddleBits=>twiddleBits,
			subOrder1=>subOrder1,
			subOrder2=>subOrder2,
			twiddleDelay=>6,
			subDelay1=>44,
			subDelay2=>11,
			customSubOrder=>true)
		port map(
			clk, din, phase, dout, phaseOut,
			subIn1,subIn2,subPhase1,subPhase2,subOut1,subOut2,
			twAddr,twData,
			bitPermIn,bitPermOut
			);
	
	-- sub-fft 1 accepts data and outputs data in transposed order
	bitPermOut <= bitPermIn(subSubOrder1-1 downto 0) & bitPermIn(bitPermIn'left downto subSubOrder1);
	
	subFFT1: entity fft16_serial3
		generic map(dataBits=>dataBits)
		port map(clk,subIn1,subPhase1,subOut1);
	
	subFFT2: entity fft4_serial3
		generic map(dataBits=>dataBits)
		port map(clk,subIn2,subPhase2,subOut2);
	
	--tw: entity twiddleGenerator16 port map(clk, twAddr, twData);
	tw: entity twiddleGenerator generic map(twiddleBits, order)
		port map(clk, twAddr, twData, romAddr, romData);
	rom: entity twiddleRom64 port map(clk, romAddr,romData);
end ar;
