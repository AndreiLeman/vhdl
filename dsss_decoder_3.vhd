library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.dcram;
use work.sr_bit;
use work.sr_unsigned;
use work.sr_signed;
use work.dsssCode1;
entity dsssDecoder3 is
	generic(clkdiv: integer := 225;
			clkdiv_order: integer := 8;
			inbits: integer := 10;
			outbits: integer := 17);
	port(
		-- divclk runs at Fs (din sample rate); coreclk runs at Fs * clkdiv
		coreclk,divclk: in std_logic;
		
		--ensure din is never at the minimum value for a 2's complement int
		-- of inbits bits
		din: signed(inbits-1 downto 0);
		
		--divclkPhase should be 0 right after the rising edge of divclk
		divclkPhase: in unsigned(clkdiv_order-1 downto 0);
		
		--output (synchronous to coreclk)
		outValid: out std_logic;
		outAddr: out unsigned(clkdiv_order-1 downto 0);
		outData: out signed(outbits-1 downto 0));
end entity;
architecture a of dsssDecoder3 is
	constant codeLen_order: integer := 10;
	constant codeLen: integer := 2**codeLen_order;
	
	--divclk phase
	signal divclkPhase1,divclkPhase2,divclkPhase3,divclkPhase5: unsigned(clkdiv_order-1 downto 0);
	
	--code phase
	signal codeStartPhase,codeStartPhaseNext: unsigned(codeLen_order-1 downto 0);
	signal codePhase,codePhaseNext: unsigned(codeLen_order-1 downto 0);
	signal shouldOutput,resetContents,resetContents1,resetContents2: std_logic;
	
	--input preprocessing
	signal dinU,dinPreprocessed,dinPreprocessed3: signed(inbits-1 downto 0);
	
	--code rom
	signal code: std_logic;
	
	--accumulator ram
	signal accWAddr,accRAddr: unsigned(clkdiv_order-1 downto 0);
	signal accWData,accRData: signed(outbits-1 downto 0);
	signal accWData_tmp,accRData_tmp: std_logic_vector(outbits-1 downto 0);
	
	--accumulator intermediate signals
	signal accOperand,accOperandNext: signed(inbits-1 downto 0);
	signal accBase,accBaseNext: signed(outbits-1 downto 0);
	signal accSum: signed(outbits-1 downto 0);
	
	--output registers
	signal outValid0, outValidS1: std_logic;
	signal outAddr0, outAddrS1: unsigned(clkdiv_order-1 downto 0);
	signal outData0, outDataS1: signed(outbits-1 downto 0);
begin
	--preprocessing
	dinU <= din when din>=0 else -din;
	dinPreprocessed <= dinU when rising_edge(divclk);
	
	--ram
	ram: entity dcram generic map(width=>outbits, depthOrder=>clkdiv_order,
			outputRegistered=>true)
		port map(rdclk=>coreclk,wrclk=>coreclk,						--clocks
			rden=>'1',rdaddr=>accRAddr,rddata=>accRData_tmp,		--read side
			wren=>'1',wraddr=>accWAddr,wrdata=>accWData_tmp);		--write side
	accRData <= signed(accRData_tmp);
	accWData_tmp <= std_logic_vector(accWData);

	--increment codeStartPhase every datain cycle
	codeStartPhaseNext <= codeStartPhase+1;
	codeStartPhase <= codeStartPhaseNext when rising_edge(divclk);
	
	--start codePhase at codeStartPhase, and increment every coreclk cycle
	codePhaseNext <= codeStartPhase when divclkPhase=0 else codePhase+1;
	codePhase <= codePhaseNext when rising_edge(coreclk);
	resetContents <= '1' when codePhase=0 else '0';
	
	divclkPhase1 <= divclkPhase when rising_edge(coreclk);
	--synchronized: divclkPhase1, codePhase

		--read from code rom and accumulator ram
		cg: entity dsssCode1 port map(coreclk,codePhase,code);	--2 cycles of delay
		accRAddr <= divclkPhase1;

	resetContents1 <= resetContents when rising_edge(coreclk);
	resetContents2 <= resetContents1 when rising_edge(coreclk);
	divclkPhase2 <= divclkPhase1 when rising_edge(coreclk);
	divclkPhase3 <= divclkPhase2 when rising_edge(coreclk);
	sr_din: entity sr_signed generic map(bits=>inbits,len=>3) port map(coreclk,dinPreprocessed,dinPreprocessed3);
	--synchronized: resetContents2, divclkPhase3, accRData, code, and dinPreprocessed3

		--output previous ram data if we are the 0th code phase
		outAddr0 <= divclkPhase3;
		outData0 <= accRData;
		outValid0 <= resetContents2;

		--calculate code * input data
		accOperandNext <= dinPreprocessed3 when code='1' else -dinPreprocessed3;
		accOperand <= accOperandNext when rising_edge(coreclk);
		
		--set accumulator to 0 if we are at the first code
		accBaseNext <= to_signed(0,outbits) when resetContents2='1' else accRData;
		accBase <= accBaseNext when rising_edge(coreclk);
		
		--calculate sum
		accSum <= accBase+accOperand when rising_edge(coreclk);

	sr_divclkPhase: entity sr_unsigned generic map(bits=>clkdiv_order,len=>2) port map(coreclk,divclkPhase3,divclkPhase5);
	--synchronized: accSum, divclkPhase5
	
		--write result back to accumulator ram
		accWAddr <= divclkPhase5;
		accWData <= accSum;
	
	
	--latch the output data and address once per divclk cycle
	--outAddrS1 <= outAddr0 when outValid0='1' and rising_edge(coreclk);
	--outData0 <= outAddr0 when outValid0='1' and rising_edge(coreclk);
	
	outAddr <= outAddr0;
	outData <= outData0;
	outValid <= outValid0;
end a;
