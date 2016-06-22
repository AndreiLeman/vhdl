library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.dcram;
use work.sr_bit;
use work.dsssCode1;
entity dsssDecoder2 is
	generic(clkdiv: integer := 225;
			clkdiv_order: integer := 8;
			inbits: integer := 10;
			outbits: integer := 17);
	port(coreclk,divclk: in std_logic;
	
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
architecture a of dsssDecoder2 is
	constant codeLen_order: integer := 10;
	constant codeLen: integer := 2**codeLen_order;
	
	--preprocessing
	signal din1,din2: signed(inbits-1 downto 0);

	--addressable shift register
	type sr_t is array(0 to clkdiv) of signed(inbits-1 downto 0);
	signal sr: sr_t;	--higher numbered elements are more recent samples
	signal srRamAddr: unsigned(clkdiv_order-1 downto 0);
	signal srRamData: signed(inbits-1 downto 0);
	
	--accumulator ram
	signal accWAddr,accRAddr: unsigned(clkdiv_order-1 downto 0);
	signal accWData,accRData: signed(outbits-1 downto 0);
	signal accWData_tmp,accRData_tmp: std_logic_vector(outbits-1 downto 0);
	
	--accumulator phase (which accumulator we are adding to)
	signal accPhase,accPhase1,accPhase2,accPhase3,accPhase4: unsigned(clkdiv_order-1 downto 0);
	
	--accumulator intermediate signals
	signal accOperand,accOperandNext: signed(inbits-1 downto 0);
	signal accBase,accBaseNext: signed(outbits-1 downto 0);
	signal accSum: signed(outbits-1 downto 0);
	
	--code phase
	signal codePhase,codePhaseNext: unsigned(codeLen_order-1 downto 0);
	signal shouldOutput,resetContents,resetContents1: std_logic;
	
	--code rom
	signal code: std_logic;
begin
	--preprocessing
	din1 <= din when din>=0 else -din;
	din2 <= din1 when rising_edge(divclk);


g1:	for I in 0 to clkdiv-1 generate
		sr(I) <= sr(I+1) when rising_edge(divclk);
	end generate;
	sr(clkdiv) <= din2 when rising_edge(divclk);
	
	--addressable shift register (read side)
	process(coreclk)
	begin
		 if(rising_edge(coreclk)) then
			  srRamData <= sr(to_integer(srRamAddr));
		 end if;
	end process;
	
	--ram
	ram: entity dcram generic map(width=>outbits, depthOrder=>clkdiv_order,
			outputRegistered=>true)
		port map(rdclk=>coreclk,wrclk=>coreclk,						--clocks
			rden=>'1',rdaddr=>accRAddr,rddata=>accRData_tmp,		--read side
			wren=>'1',wraddr=>accWAddr,wrdata=>accWData_tmp);		--write side
	accRData <= signed(accRData_tmp);
	accWData_tmp <= std_logic_vector(accWData);
	
	accPhase <= divclkPhase;
	
	--################# main logic #################
	--##### each indented section is one stage #####
	--##############################################
	
		--read from accumulator ram
		accRAddr <= accPhase;
		
		--read from shift register ram
		srRamAddr <= accPhase when rising_edge(coreclk);

	accPhase1 <= accPhase when rising_edge(coreclk);
	accPhase2 <= accPhase1 when rising_edge(coreclk); -- synchronized to accRData and srRamData
	
		--calculate code * input data
		accOperandNext <= srRamData when code='1' else -srRamData;
		accOperand <= accOperandNext when rising_edge(coreclk);
		
		--set accumulator to 0 if we are at the first code
		accBaseNext <= to_signed(0,outbits) when resetContents1='1' else accRData;
		accBase <= accBaseNext when rising_edge(coreclk);
	
	--resynchronize counter
	accPhase3 <= accPhase2 when rising_edge(coreclk); --synchronized to accBase and accOperand
	
		--calculate sum
		accSum <= accBase+accOperand when rising_edge(coreclk);
	
	--resynchronize counter
	accPhase4 <= accPhase3 when rising_edge(coreclk); --synchronized to accSum
	
		--write result back to accumulator ram
		accWAddr <= accPhase4;
		accWData <= accSum;
	
	--put the writeback data on the output bus, but only assert outValid
	--when we are on the last code phase
	outAddr <= accWAddr;
	outData <= accWData;
	
	shouldOutput <= '1' when codePhase=codeLen-1 else '0';		--synchronized to divClkPhase
	
	--output is synchronized to accPhase4
	sr_outp: entity sr_bit generic map(4) port map(coreclk,shouldOutput,outValid);
	
	
	--################# code generation #################
	codePhaseNext <= codePhase+1;
	codePhase <= codePhaseNext when rising_edge(divclk);	--synchronized to divClkPhase
	cg: entity dsssCode1 port map(coreclk,codePhase,code);	--code is synchronized to accPhase2
	resetContents <= '1' when codePhase=0 else '0';			--synchronized to divClkPhase
	--synchronized to accPhase2
	sr_rst: entity sr_bit generic map(2) port map(coreclk,resetContents,resetContents1);
	
end architecture;
