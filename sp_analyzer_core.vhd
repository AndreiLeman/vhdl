library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity spAnalyzerCore is
	generic(inbits: integer := 8;
				outbits: integer := 12;
				membits: integer := 10);
	port(clk: in std_logic;
			datain: in signed(inbits-1 downto 0);
			freqStep: in unsigned(15 downto 0);
			wrClk: out std_logic;
			wrAddr: out unsigned(membits-1 downto 0);
			wrData: out unsigned(outbits-1 downto 0));
end entity;

architecture a of spAnalyzerCore is
	constant filtOrder: integer := 5;
	-- set to channels/5 for ~ -3dB adjacent channel sensitivity
	constant filtLen: integer := 200;
	constant filtTotalLen: integer := filtLen*filtOrder;
	
	signal curFreqIndex,nextFreqIndex: unsigned(membits-1 downto 0);
	signal curIndex,nextIndex: unsigned(7 downto 0);
	
	signal doIncrement, doIncrementFreq,wrClk0 std_logic;
	
	-- lowpass filter
	type filtDataArray is array() of signed(inbits+8-1 downto 0);
	signal curPhase,nextPhase: unsigned(7 downto 0);
	signal filtIn: signed(inbits-1 downto 0);
	signal integrators: filtDataArray(0 to filtOrder-1);
	signal filtDecimator: filtDataArray(0 to filtOrder*2-1);
	signal filtOut: signed(inbits+8-1 downto 0);
begin
	curFreqIndex <= nextFreqIndex when rising_edge(clk);
	nextFreqIndex <= curFreqIndex+1 when doIncrementFreq='1' else curFreqIndex;
	
	curIndex <= nextIndex when rising_edge(clk);
	doIncrementFreq <= '1' when curIndex=(filtOrder*2+1) else '0';
	wrClk0 <= '1' when curIndex<filtOrder else '0';
	
	nextIndex <= to_unsigned(0,8) when doIncrementFreq='1' else
				curIndex+1 when doIncrement='1' else curIndex;
	
	-- lowpass filter
	curPhase <= nextPhase when rising_edge(clk);
	doIncrement <= '1' when curPhase=filtLen else '0';
	nextPhase <= to_unsigned(0,8) when doIncrement='1' else curPhase+1;
	integrators(0) <= integrators(0)+filtIn when rising_edge(clk);
g1:for i in 1 to filtOrder-1 generate
		integrators(i) <= integrators(i)+integrators(i-1)(inbits+8-1 downto 8) when rising_edge(clk);
	end generate;
	filtDecimator(0) <= integrators(filtOrder-1) when doIncrement='1' and rising_edge(clk);
	filtDecimator(1) <= filtDecimator(0) when doIncrement='1' and rising_edge(clk);
g2:for i in 1 to filtOrder-1 generate
		filtDecimator(i*2) <= filtDecimator(i*2-2)-filtDecimator(i*2-1) when doIncrement='1' and rising_edge(clk);
		filtDecimator(i*2+1) <= filtDecimator(i*2) when doIncrement='1' and rising_edge(clk);
	end generate;
	filtOut <= filtDecimator(filtOrder*2-2)-filtDecimator(filtOrder*2-1) when doIncrement='1' and rising_edge(clk);

	wrData <= filtOut(inbits+8-1 downto inbits+8-outbits);
	wrAddr <= curFreqIndex;
	wrClk <= wrClk0 when rising_edge(clk);
end architecture;

