library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.sineGenerator;
entity spectrum2 is
	generic(inbits: integer := 8;
				outbits: integer := 16;
				membits: integer := 10);
	port(clk: in std_logic;
			datain: in signed(inbits-1 downto 0);
			freqStep: in unsigned(23 downto 0);
			wrClk: out std_logic;
			wrAddr: out unsigned(membits-1 downto 0);
			wrData: out unsigned(outbits-1 downto 0));
end entity;

architecture a of spectrum2 is
	constant stateBits: integer := 10;
	signal state,stateNext: unsigned(stateBits-1 downto 0);
	signal freqIndex: unsigned(membits-1 downto 0);
	signal freq: unsigned(membits+24-1 downto 0);
	signal integrator,integratorNext: signed(inbits+stateBits+8-1 downto 0);
	signal wrClkNext: std_logic;
	
	signal lo: signed(8 downto 0);
	signal mixerOut: signed(inbits+9-1 downto 0);
	
	signal tmpOut: signed(outbits-1 downto 0);
	signal tmpOut2: unsigned(outbits-1 downto 0);
begin
	state <= stateNext when rising_edge(clk);
	stateNext <= state+1;
	
	sg: sineGenerator port map(clk,freq(23 downto 0) & (28-24-1 downto 0=>'0'),lo);
	mixerOut <= lo*datain when rising_edge(clk);
	
	freqIndex <= freqIndex+1 when state=0 and rising_edge(clk);
	freq <= freqIndex*freqStep when rising_edge(clk);
	integratorNext <= to_signed(0,inbits+stateBits+8) when state=2 else
		integrator+mixerOut;
	integrator <= integratorNext when rising_edge(clk);
	tmpOut <= integrator(inbits+stateBits+8-1 downto inbits+stateBits+8-outbits)
		when state=2 and rising_edge(clk);
	tmpOut2 <= unsigned(tmpOut) when tmpOut>=0 else unsigned(signed(-tmpOut));
	
	wrAddr <= freqIndex;
	wrData <= tmpOut2 when rising_edge(clk);
	wrClk <= state(stateBits-1);
end architecture;

