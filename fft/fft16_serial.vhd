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

-- data should be input in transposed order: 0,4,8,12,1,5,9,13,...
-- phase should be 0,1,2,3,4,5,6,...
-- output values are normalized to 1/sqrt(n)
-- delay is fft4_delay + 16 + mult_delay + fft4_delay cycles
entity fft16_serial is
	generic(dataBits: integer := 18;
			twiddleBits: integer := 12);

	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(3 downto 0);
		dout: out complex;
		phaseOut: out unsigned(3 downto 0);
		
		-- twiddle rom
		romAddr: out unsigned(0 downto 0);
		romData: in std_logic_vector(twiddleBits*2-3 downto 0);
		
		-- debug
		debug1: out integer
		);
end entity;

architecture ar of fft16_serial is
	constant N: integer := 16;
	constant subN: integer := 4;
	constant order: integer := 4;
	constant subOrder: integer := 2;

	constant fft4_delay: integer := 11;
	constant twiddle_delay: integer := 6;
	
	signal fft_in_res: complex;
	signal ph1: unsigned(order-1 downto 0) := (others=>'0');
	signal ph2: unsigned(order downto 0) := (others=>'0');
	
	signal rph0,rph1,rph2,rph3,rph4,rph5,rph6,rph_twiddle: unsigned(order-1 downto 0) := (others=>'0');
	signal raddr: unsigned(order downto 0) := (others=>'0');
	signal rdata: complex;
	signal twaddr,twaddrNext: unsigned(order-1 downto 0) := (others=>'0');
	signal twdata: complex;
	signal multOut: complex;
begin
	-- perform 4 ffts of size 4
	-- delay is fft4_delay cycles
	fft_in: entity fft4_serial3 generic map(dataBits)
		port map(clk,din,phase(subOrder-1 downto 0), fft_in_res);
	
	--del1: entity sr_unsigned generic map(phase'left+1, 7)
	--	port map(clk, phase, ph1); -- delay 3 cycles because we are introducing another cycle of delay later
	ph1 <= phase-fft4_delay+1 when rising_edge(clk); -- fft4_delay cycles of apparent delay
	
	transp: entity transposer generic map(subOrder, subOrder, dataBits)
		port map(clk, fft_in_res, ph1, rdata);
	rph0 <= ph1;
	-- rdata is aligned with rph0
	-- fft4_delay + 16 cycles
	
	-- fetch twiddle factors
	-- twiddle index is actually rowIndex*colIndex
	rph_twiddle <= rph0+twiddle_delay+2 when rising_edge(clk);
	twaddrNext <= (others=>'0') when rph_twiddle(1 downto 0)=0 else
					twaddr + rph_twiddle(3 downto 2);
	twaddr <= twaddrNext when rising_edge(clk); -- aligned with rph0+twiddle_delay
	
	tw: entity twiddleGenerator generic map(twiddleBits, order)
		port map(clk, twaddr, twdata, romAddr, romData);
	-- twdata is aligned with rph0
	
	-- mutliply by twiddles; delay is 6 cycles
	mult: entity complexMultiply generic map(dataBits,twiddleBits,dataBits)
		port map(clk, rdata, twdata, multOut);
	--del4: entity sr_unsigned generic map(rph0'left+1, 8)
	--	port map(clk, rph0, rph3);
	rph3 <= rph0-6+1 when rising_edge(clk);
	-- fft4_delay + 16 + mult_delay cycles
	
	-- perform 4 ffts of size 4
	-- delay is fft4_delay cycles
	fft_out: entity fft4_serial3 generic map(dataBits)
		port map(clk,multOut,rph3(subOrder-1 downto 0), dout);
	del5: entity sr_unsigned generic map(rph2'left+1, fft4_delay)
		port map(clk, rph3, rph4);
	phaseOut <= rph4(3 downto 0);
	-- fft4_delay + 16 + mult_delay + fft4_delay cycles
end ar;
