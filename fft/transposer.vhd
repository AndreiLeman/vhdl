library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.fft_types.all;
use work.fft4_serial;
--use work.fft4_serial2;
use work.sr_unsigned;
use work.complexRam;
use work.twiddleGenerator;
use work.complexMultiply;
use work.transposer_addrGen;
use work.sr_complex;

-- phase should be 0,1,2,3,4,5,6,... up to (2**N1)*(2**N2)-1
-- transpose from 2**N1 groups of 2**N2 words to 2**N2 groups of 2**N1 words.
-- din:  aa,ab,ac,ad,ba,bb,bc,bd,ca,cb,cc,cd,...
-- dout: aa,ba,ca,ab,bb,cb,ac,bc,cc,ad,bd,cd,...
entity transposer is
	generic(N1,N2: integer; -- N1 is the major size and N2 the minor size (input perspective)
			dataBits: integer);
	port(clk: in std_logic;
		din: in complex;
		phase: in unsigned(N1+N2-1 downto 0);
		dout: out complex
		);
end entity;
architecture ar of transposer is
	signal din2: complex;
	signal iaddr, iaddr2, oaddr: unsigned(N1+N2-1 downto 0);
	constant myDelays: integer := 2;
begin
	-- read side
	addrGen: entity transposer_addrGen generic map(N1, N2, myDelays)
		port map(clk, phase, oaddr);
	-- -myDelays cycles
	
	ram: entity complexRam generic map(dataBits, N1+N2)
		port map(clk, clk, oaddr, dout, '1', iaddr2, din2);
	-- -myDelays+2 cycles
	
	-- write side
	sr1: entity sr_unsigned generic map(N1+N2, myDelays)
		port map(clk, oaddr, iaddr);
	din2 <= din when rising_edge(clk);
	iaddr2 <= iaddr when rising_edge(clk);
end ar;
