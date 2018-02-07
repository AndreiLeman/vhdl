library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.dcram;
use work.sr_bit;
use work.sr_unsigned;
use work.sr_signed;
entity dsssDecoder3 is
	generic(clkDiv: integer := 225;
			clkDivOrder: integer := 8;
			inbits: integer := 10;
			outbits: integer := 17;
			codeLenOrder: integer := 10;
			preprocess: boolean := true;	--whether to take abs() of input
			combSeparationOrder: integer := 0);
	port(
		-- divclk runs at Fs (din sample rate); coreclk runs at Fs * clkdiv
		coreclk,divclk: in std_logic;
		
		--ensure din is never at the minimum value for a 2's complement int
		-- of inbits bits
		din: signed(inbits-1 downto 0);
		
		--divclkPhase should be 0 right after the rising edge of divclk
		divclkPhase: in unsigned(clkDivOrder-1 downto 0);
		
		--code rom signals (for connection to external code rom)
		--clock is coreclk; delay must be 2 clock cycles
		codeAddr: out unsigned(codeLenOrder-1 downto 0);
		code: in std_logic;
		
		--output (synchronous to divclk)
		outValid: out std_logic;
		outAddr: out unsigned(clkDivOrder+combSeparationOrder-1 downto 0);
		outData: out signed(outbits-1 downto 0));
end entity;
architecture a of dsssDecoder3 is
	constant codeLen: integer := 2**codeLenOrder;
	constant combSeparation: integer := 2**combSeparationOrder;
	
	--accumulator index
	signal divclkPhase1: unsigned(clkDivOrder-1 downto 0);
	signal ramPos1,ramPos2,ramPos3,ramPos4,ramPos5: unsigned(clkDivOrder+combSeparationOrder-1 downto 0);
	
	--code phase
	signal codeStartPhase,codeStartPhaseNext: unsigned(codeLenOrder+combSeparationOrder-1 downto 0);
	signal codePhase,codePhaseNext: unsigned(codeLenOrder+combSeparationOrder-1 downto 0);
	signal shouldOutput,resetContents,resetContents1,resetContents2: std_logic;
	
	--input preprocessing
	signal dinU,dinPreprocessed0,dinPreprocessedNext,dinPreprocessed,dinPreprocessed3: signed(inbits-1 downto 0);
	
	--accumulator ram
	signal accWAddr,accRAddr: unsigned(clkDivOrder+combSeparationOrder-1 downto 0);
	signal accWData,accRData: signed(outbits-1 downto 0);
	signal accWData_tmp,accRData_tmp: std_logic_vector(outbits-1 downto 0);
	
	--accumulator intermediate signals
	signal accOperand,accOperandNext: signed(inbits-1 downto 0);
	signal accBase,accBaseNext: signed(outbits-1 downto 0);
	signal accSum,accSumNext: signed(outbits-1 downto 0);
	
	--output registers
	signal outValid0,outValid0Next, outValidS1,outValidS2,outValidS3: std_logic;
	signal outAddr0,outAddr0Next, outAddrS1,outAddrS2,outAddrS3: unsigned(clkDivOrder+combSeparationOrder-1 downto 0);
	signal outData0,outData0Next, outDataS1,outDataS2,outDataS3: signed(outbits-1 downto 0);
begin
	--preprocessing
g1:	if preprocess generate
		dinU <= din when din>=0 else -din;
		dinPreprocessed0 <= dinU when rising_edge(divclk);
	end generate;
g2: if not preprocess generate
		dinPreprocessed0 <= din when rising_edge(divclk);
	end generate;
	
	dinPreprocessedNext <= dinPreprocessed0 when falling_edge(divclk);
	dinPreprocessed <= dinPreprocessedNext when divclkPhase=(clkDiv-1) and rising_edge(coreclk);

	--ram
	ram: entity dcram generic map(width=>outbits,
			depthOrder=>clkDivOrder+combSeparationOrder,
			outputRegistered=>true)
		port map(rdclk=>coreclk,wrclk=>coreclk,						--clocks
			rden=>'1',rdaddr=>accRAddr,rddata=>accRData_tmp,		--read side
			wren=>'1',wraddr=>accWAddr,wrdata=>accWData_tmp);		--write side
	accRData <= signed(accRData_tmp);
	accWData_tmp <= std_logic_vector(accWData);

	--increment codeStartPhase every datain cycle
	codeStartPhaseNext <= codeStartPhase+1;
	codeStartPhase <= codeStartPhaseNext when divclkPhase=0 and rising_edge(coreclk);
	
	--start codePhase at codeStartPhase, and increment every coreclk cycle
	codePhaseNext <= codeStartPhase when divclkPhase=0 else codePhase+combSeparation;
	codePhase <= codePhaseNext when rising_edge(coreclk);
	resetContents <= '1' when codePhase(codeLenOrder+combSeparationOrder-1 downto combSeparationOrder)=0 else '0';
	
	divclkPhase1 <= divclkPhase when rising_edge(coreclk);
	ramPos1 <= divclkPhase1 & (not codePhase(combSeparationOrder-1 downto 0));
	--synchronized: divclkPhase1, codePhase, ramPos1

		--read from code rom and accumulator ram
		codeAddr <= codePhase(codeLenOrder+combSeparationOrder-1 downto combSeparationOrder);
			--2 cycles of delay between codeAddr and code
		accRAddr <= ramPos1;
			--2 cycles of delay between accRAddr and accRData

	resetContents1 <= resetContents when rising_edge(coreclk);
	resetContents2 <= resetContents1 when rising_edge(coreclk);
	ramPos2 <= ramPos1 when rising_edge(coreclk);
	ramPos3 <= ramPos2 when rising_edge(coreclk);
	sr_din: entity sr_signed generic map(bits=>inbits,len=>3) port map(coreclk,dinPreprocessed,dinPreprocessed3);
	--synchronized: resetContents2, ramPos3, accRData, code, and dinPreprocessed3

		--output previous ram data if we are the 0th code phase
		outAddr0Next <= not ramPos3 when resetContents2='1' else outAddr0;
		outData0Next <= accRData when resetContents2='1' else outData0;
		outValid0Next <= resetContents2 when ramPos3(clkDivOrder+combSeparationOrder-1 downto combSeparationOrder)=0
			else '1' when resetContents2='1'
			else outValid0;
		outAddr0 <= outAddr0Next when rising_edge(coreclk);
		outData0 <= outData0Next when rising_edge(coreclk);
		outValid0 <= outValid0Next when rising_edge(coreclk);

		--calculate code * input data
		accOperandNext <= dinPreprocessed3 when code='1' else -dinPreprocessed3;
		accOperand <= accOperandNext when rising_edge(coreclk);
		
		--set accumulator to 0 if we are at the first code
		accBaseNext <= to_signed(0,outbits) when resetContents2='1' else accRData;
		accBase <= accBaseNext when rising_edge(coreclk);
		
		--calculate sum
		accSumNext <= accBase when accBase(outbits-1)/=accBase(outbits-2) else accBase+accOperand;
		accSum <= accSumNext when rising_edge(coreclk);

	ramPos4 <= ramPos3 when rising_edge(coreclk);
	--synchronized: outAddr0, outData0, outValid0, ramPos4
		
		--latch the output once per divclk cycle (so we can resample it to divclk)
		outAddrS1 <= outAddr0 when ramPos3(clkDivOrder+combSeparationOrder-1 downto combSeparationOrder)=0 and rising_edge(coreclk);
		outDataS1 <= outData0 when ramPos3(clkDivOrder+combSeparationOrder-1 downto combSeparationOrder)=0 and rising_edge(coreclk);
		outValidS1 <= outValid0 when ramPos3(clkDivOrder+combSeparationOrder-1 downto combSeparationOrder)=0 and rising_edge(coreclk);
	
	ramPos5 <= ramPos4 when rising_edge(coreclk);
	--synchronized: accSum, ramPos5
	
		--write result back to accumulator ram
		accWAddr <= ramPos5;
		accWData <= accSum;

	outAddrS2 <= outAddrS1 when divclkPhase=clkDiv/2 and rising_edge(coreclk);
	outDataS2 <= outDataS1 when divclkPhase=clkDiv/2 and rising_edge(coreclk);
	outValidS2 <= outValidS1 when divclkPhase=clkDiv/2 and rising_edge(coreclk);

	outAddr <= outAddrS2 when rising_edge(divclk);
	outData <= outDataS2 when rising_edge(divclk);
	outValid <= outValidS2 when rising_edge(divclk);
end a;
