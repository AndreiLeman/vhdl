
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft3step_bram_generic2;
use work.twiddleGenerator;
use work.transposer;
use work.reorderBuffer;
use work.twiddleRom1024;
use work.twiddleRom64;
use work.twiddleGenerator16;
use work.fft4_serial3;

-- data input bit order: 6,7,8,9,4,5,2,3,0,1
-- data output bit order: 8,9,6,7,4,5,2,3,0,1
-- phase should be 0,1,2,3,4,5,6,...
-- delay is 1215
entity fft1024_generated is
	generic(dataBits: integer := 24);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(10-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of fft1024_generated is
	-- ====== FFT instance 'top' (N=1024) ======
	constant top_N: integer := 1024;
	constant top_twiddleBits: integer := 16;
	constant top_twiddleDelay: integer := 6;
	constant top_order: integer := 10;
	constant top_delay: integer := 1215;

		-- ====== FFT instance 'A' (N=64) ======
		constant A_N: integer := 64;
		constant A_twiddleBits: integer := 12;
		constant A_twiddleDelay: integer := 6;
		constant A_order: integer := 6;
		constant A_delay: integer := 125;

			-- ====== FFT instance 'AA' (N=16) ======
			constant AA_N: integer := 16;
			constant AA_twiddleBits: integer := 12;
			constant AA_twiddleDelay: integer := 2;
			constant AA_order: integer := 4;
			constant AA_delay: integer := 44;

				-- ====== FFT instance 'AAA' (N=4) ======
				constant AAA_N: integer := 4;
				constant AAA_order: integer := 2;
				constant AAA_delay: integer := 11;

				-- ====== FFT instance 'AAB' (N=4) ======
				constant AAB_N: integer := 4;
				constant AAB_order: integer := 2;
				constant AAB_delay: integer := 11;

			-- ====== FFT instance 'AB' (N=4) ======
			constant AB_N: integer := 4;
			constant AB_order: integer := 2;
			constant AB_delay: integer := 11;

		-- ====== FFT instance 'B' (N=16) ======
		constant B_N: integer := 16;
		constant B_twiddleBits: integer := 12;
		constant B_twiddleDelay: integer := 2;
		constant B_order: integer := 4;
		constant B_delay: integer := 44;

			-- ====== FFT instance 'BA' (N=4) ======
			constant BA_N: integer := 4;
			constant BA_order: integer := 2;
			constant BA_delay: integer := 11;

			-- ====== FFT instance 'BB' (N=4) ======
			constant BB_N: integer := 4;
			constant BB_order: integer := 2;
			constant BB_delay: integer := 11;

	--=======================================

	-- ====== FFT instance 'top' (N=1024) ======
	signal top_in, top_out, top_rbIn: complex;
	signal top_phase: unsigned(top_order-1 downto 0);
	signal top_bitPermIn,top_bitPermOut: unsigned(A_order-1 downto 0);
	-- twiddle generator
	signal top_twAddr: unsigned(top_order-1 downto 0);
	signal top_twData: complex;
	signal top_romAddr: unsigned(top_order-4 downto 0);
	signal top_romData: std_logic_vector(top_twiddleBits*2-3 downto 0);
	signal top_rP0: unsigned(4-1 downto 0);
	signal top_rP1: unsigned(4-1 downto 0);
	signal top_rP2: unsigned(4-1 downto 0);
	signal top_rCnt: unsigned(2-1 downto 0);

		-- ====== FFT instance 'A' (N=64) ======
		signal A_in, A_out, A_rbIn: complex;
		signal A_phase: unsigned(A_order-1 downto 0);
		signal A_bitPermIn,A_bitPermOut: unsigned(AA_order-1 downto 0);
		-- twiddle generator
		signal A_twAddr: unsigned(A_order-1 downto 0);
		signal A_twData: complex;
		signal A_romAddr: unsigned(A_order-4 downto 0);
		signal A_romData: std_logic_vector(A_twiddleBits*2-3 downto 0);

			-- ====== FFT instance 'AA' (N=16) ======
			signal AA_in, AA_out, AA_rbIn: complex;
			signal AA_phase: unsigned(AA_order-1 downto 0);
			signal AA_bitPermIn,AA_bitPermOut: unsigned(AAA_order-1 downto 0);
			-- twiddle generator
			signal AA_twAddr: unsigned(AA_order-1 downto 0);
			signal AA_twData: complex;
			signal AA_romAddr: unsigned(AA_order-4 downto 0);
			signal AA_romData: std_logic_vector(AA_twiddleBits*2-3 downto 0);

				-- ====== FFT instance 'AAA' (N=4) ======
				signal AAA_in, AAA_out: complex;
				signal AAA_phase: unsigned(2-1 downto 0);

				-- ====== FFT instance 'AAB' (N=4) ======
				signal AAB_in, AAB_out: complex;
				signal AAB_phase: unsigned(2-1 downto 0);

			-- ====== FFT instance 'AB' (N=4) ======
			signal AB_in, AB_out: complex;
			signal AB_phase: unsigned(2-1 downto 0);

		-- ====== FFT instance 'B' (N=16) ======
		signal B_in, B_out, B_rbIn: complex;
		signal B_phase: unsigned(B_order-1 downto 0);
		signal B_bitPermIn,B_bitPermOut: unsigned(BA_order-1 downto 0);
		-- twiddle generator
		signal B_twAddr: unsigned(B_order-1 downto 0);
		signal B_twData: complex;
		signal B_romAddr: unsigned(B_order-4 downto 0);
		signal B_romData: std_logic_vector(B_twiddleBits*2-3 downto 0);

			-- ====== FFT instance 'BA' (N=4) ======
			signal BA_in, BA_out: complex;
			signal BA_phase: unsigned(2-1 downto 0);

			-- ====== FFT instance 'BB' (N=4) ======
			signal BB_in, BB_out: complex;
			signal BB_phase: unsigned(2-1 downto 0);
begin
	top_in <= din;
	top_phase <= phase;
	dout <= top_out;
	-- ====== FFT instance 'top' (N=1024) ======
	top_core: entity fft3step_bram_generic2
		generic map(
			dataBits=>dataBits,
			twiddleBits=>top_twiddleBits,
			subOrder1=>A_order,
			subOrder2=>B_order,
			twiddleDelay=>top_twiddleDelay,
			subDelay1=>A_delay,
			subDelay2=>60,
			customSubOrder=>true)
		port map(
			clk=>clk, din=>top_in, phase=>top_phase, dout=>top_out, phaseOut=>open,
			subIn1=>A_in, subIn2=>top_rbIn,
			subPhase1=>A_phase, subPhase2=>B_phase,
			subOut1=>A_out, subOut2=>B_out,
			twAddr=>top_twAddr, twData=>top_twData,
			bitPermIn=>top_bitPermIn, bitPermOut=>top_bitPermOut);
		
	top_bitPermOut <= top_bitPermIn(1)&top_bitPermIn(0)&top_bitPermIn(3)&top_bitPermIn(2)&top_bitPermIn(5)&top_bitPermIn(4);
	top_tw: entity twiddleGenerator generic map(top_twiddleBits, top_order)
		port map(clk, top_twAddr, top_twData, top_romAddr, top_romData);
	top_rom: entity twiddleRom1024 port map(clk, top_romAddr,top_romData);
	top_rP1 <= top_rP0(1)&top_rP0(0)&top_rP0(3)&top_rP0(2) when top_rCnt(0)='1' else top_rP0;
	top_rP2 <= top_rP1(3)&top_rP1(2)&top_rP1(1)&top_rP1(0) when top_rCnt(1)='1' else top_rP1;
		
	top_rb: entity reorderBuffer
		generic map(N=>4, dataBits=>dataBits, bitPermDelay=>0)
		port map(clk, din=>top_rbIn, phase=>B_phase, dout=>B_in,
			bitPermIn=>top_rP0, bitPermCount=>top_rCnt, bitPermOut=>top_rP2);

		-- ====== FFT instance 'A' (N=64) ======
		A_core: entity fft3step_bram_generic2
			generic map(
				dataBits=>dataBits,
				twiddleBits=>A_twiddleBits,
				subOrder1=>AA_order,
				subOrder2=>AB_order,
				twiddleDelay=>A_twiddleDelay,
				subDelay1=>AA_delay,
				subDelay2=>11,
				customSubOrder=>true)
			port map(
				clk=>clk, din=>A_in, phase=>A_phase, dout=>A_out, phaseOut=>open,
				subIn1=>AA_in, subIn2=>AB_in,
				subPhase1=>AA_phase, subPhase2=>AB_phase,
				subOut1=>AA_out, subOut2=>AB_out,
				twAddr=>A_twAddr, twData=>A_twData,
				bitPermIn=>A_bitPermIn, bitPermOut=>A_bitPermOut);
			
		A_bitPermOut <= A_bitPermIn(1)&A_bitPermIn(0)&A_bitPermIn(3)&A_bitPermIn(2);
		A_tw: entity twiddleGenerator generic map(A_twiddleBits, A_order)
			port map(clk, A_twAddr, A_twData, A_romAddr, A_romData);
		A_rom: entity twiddleRom64 port map(clk, A_romAddr,A_romData);

			-- ====== FFT instance 'AA' (N=16) ======
			AA_core: entity fft3step_bram_generic2
				generic map(
					dataBits=>dataBits,
					twiddleBits=>AA_twiddleBits,
					subOrder1=>AAA_order,
					subOrder2=>AAB_order,
					twiddleDelay=>AA_twiddleDelay,
					subDelay1=>AAA_delay,
					subDelay2=>11,
					customSubOrder=>true)
				port map(
					clk=>clk, din=>AA_in, phase=>AA_phase, dout=>AA_out, phaseOut=>open,
					subIn1=>AAA_in, subIn2=>AAB_in,
					subPhase1=>AAA_phase, subPhase2=>AAB_phase,
					subOut1=>AAA_out, subOut2=>AAB_out,
					twAddr=>AA_twAddr, twData=>AA_twData,
					bitPermIn=>AA_bitPermIn, bitPermOut=>AA_bitPermOut);
				
			AA_bitPermOut <= AA_bitPermIn(1)&AA_bitPermIn(0);
			AA_tw: entity twiddleGenerator16 port map(clk, AA_twAddr, AA_twData);

				-- ====== FFT instance 'AAA' (N=4) ======
				AAA_inst: entity fft4_serial3
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>AAA_in, phase=>AAA_phase, dout=>AAA_out);

				-- ====== FFT instance 'AAB' (N=4) ======
				AAB_inst: entity fft4_serial3
					generic map(dataBits=>dataBits, scale=>SCALE_NONE)
					port map(clk=>clk, din=>AAB_in, phase=>AAB_phase, dout=>AAB_out);

			-- ====== FFT instance 'AB' (N=4) ======
			AB_inst: entity fft4_serial3
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_SQRT_N)
				port map(clk=>clk, din=>AB_in, phase=>AB_phase, dout=>AB_out);

		-- ====== FFT instance 'B' (N=16) ======
		B_core: entity fft3step_bram_generic2
			generic map(
				dataBits=>dataBits,
				twiddleBits=>B_twiddleBits,
				subOrder1=>BA_order,
				subOrder2=>BB_order,
				twiddleDelay=>B_twiddleDelay,
				subDelay1=>BA_delay,
				subDelay2=>11,
				customSubOrder=>true)
			port map(
				clk=>clk, din=>B_in, phase=>B_phase, dout=>B_out, phaseOut=>open,
				subIn1=>BA_in, subIn2=>BB_in,
				subPhase1=>BA_phase, subPhase2=>BB_phase,
				subOut1=>BA_out, subOut2=>BB_out,
				twAddr=>B_twAddr, twData=>B_twData,
				bitPermIn=>B_bitPermIn, bitPermOut=>B_bitPermOut);
			
		B_bitPermOut <= B_bitPermIn(1)&B_bitPermIn(0);
		B_tw: entity twiddleGenerator16 port map(clk, B_twAddr, B_twData);

			-- ====== FFT instance 'BA' (N=4) ======
			BA_inst: entity fft4_serial3
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
				port map(clk=>clk, din=>BA_in, phase=>BA_phase, dout=>BA_out);

			-- ====== FFT instance 'BB' (N=4) ======
			BB_inst: entity fft4_serial3
				generic map(dataBits=>dataBits, scale=>SCALE_DIV_N)
				port map(clk=>clk, din=>BB_in, phase=>BB_phase, dout=>BB_out);
end ar;

