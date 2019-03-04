library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft4_serial;
use work.fft4_serial2;
use work.fft4_serial3;
use work.sr_unsigned;
use work.complexRam;
use work.twiddleGenerator;
use work.complexMultiply;
use work.transposer;

-- data input and output are in transposed order: 0,4,8,12,1,5,9,13,... (for N=16)
-- sub-fft should accept data and output data in linear order.
-- phase should be 0,1,2,3,4,5,6,...
-- output values are normalized to 1/sqrt(n).

-- If customSubOrder is true, sub-fft 1 accepts and outputs data in an arbitrary order
-- determined by a address bit permutation. bitPermOut and bitPermIn should be connected
-- to the permutation function (purely combinational).
-- The order of data input and output are also affected: row order of the input are permuted
-- (e.g. 0,8,4,12,1,9,5,13,...), and column order of the output are permuted
-- (e.g. 0,4,8,12,2,6,10,14,...). sub-fft 2 must still accept data in linear order,
-- but may output data in permuted order, in which case the rows of the output
-- are permuted.
entity fft3step_bram_generic is
	generic(dataBits: integer := 18;
			twiddleBits: integer := 12;
			subOrder: integer := 4;
			twiddleDelay: integer := 6;
			subDelay: integer := 11;
			customSubOrder: boolean := false
			);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(subOrder*2-1 downto 0);
		dout: out complex;
		phaseOut: out unsigned(subOrder*2-1 downto 0);
		
		-- sub-fft
		subIn1,subIn2: out complex;
		subPhase1,subPhase2: out unsigned(subOrder-1 downto 0);
		subOut1,subOut2: in complex;
		
		-- twiddle generator
		twAddr: out unsigned(subOrder*2-1 downto 0);
		twData: in complex;
		
		bitPermIn: out unsigned(subOrder-1 downto 0) := (others=>'X');
		bitPermOut: in unsigned(subOrder-1 downto 0) := (others=>'0')
		);
end entity;

architecture ar of fft3step_bram_generic is
	constant order: integer := subOrder*2;
	constant N: integer := 2**order;
	constant subN: integer := 2**subOrder;

	signal ph1: unsigned(order-1 downto 0) := (others=>'0');
	signal ph2: unsigned(order downto 0) := (others=>'0');
	
	signal rph0,rph1,rph2,rph3,rph4,rph5,rph6,rph_twiddle: unsigned(order-1 downto 0) := (others=>'0');
	signal twRowAddr: unsigned(subOrder-1 downto 0) := (others=>'0');
	signal raddr: unsigned(order downto 0) := (others=>'0');
	signal rdata: complex;
	signal twAddr0, twAddr0Next: unsigned(order-1 downto 0) := (others=>'0');
	signal multOut: complex;
begin
	-- perform subN ffts of size subN
	-- delay is subDelay cycles
	subIn1 <= din;
	subPhase1 <= phase(subOrder-1 downto 0);
	ph1 <= phase-subDelay+1 when rising_edge(clk); -- subDelay cycles of apparent delay
	-- subOut1 is aligned with ph1
	
	transp: entity transposer generic map(subOrder, subOrder, dataBits)
		port map(clk, subOut1, ph1, rdata);
	rph0 <= ph1;
	-- rdata is aligned with rph0
	-- fft4_delay + 16 cycles
	
	-- fetch twiddle factors
	-- twiddle index is actually rowIndex*colIndex
	rph_twiddle <= rph0+twiddleDelay+2 when rising_edge(clk);
	
	bitPermIn <= rph_twiddle(rph_twiddle'left downto subOrder);
	twRowAddr <= bitPermOut when customSubOrder=true else
		rph_twiddle(rph_twiddle'left downto subOrder);
	
	twAddr0Next <= (others=>'0') when rph_twiddle(subOrder-1 downto 0)=0 else
					twAddr0 + twRowAddr;
	twAddr0 <= twAddr0Next when rising_edge(clk); -- aligned with rph0+twiddleDelay
	twAddr <= twAddr0;
	-- twData is aligned with rph0
	
	-- mutliply by twiddles; delay is 6 cycles
	mult: entity complexMultiply generic map(dataBits,twiddleBits,dataBits)
		port map(clk, rdata, twdata, multOut);
	rph3 <= rph0-6+1 when rising_edge(clk);
	-- fft4_delay + 16 + mult_delay cycles
	
	-- perform subN ffts of size subN
	-- delay is fft4_delay cycles
	subIn2 <= multOut;
	subPhase2 <= rph3(subOrder-1 downto 0);
	dout <= subOut2;
	phaseOut <= rph3-subDelay+1 when rising_edge(clk);
	-- fft4_delay + 16 + mult_delay + fft4_delay cycles
end ar;
