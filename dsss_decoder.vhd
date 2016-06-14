----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:36:58 06/11/2016 
-- Design Name: 
-- Module Name:    dsss_decoder - a 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

--user must ensure datain never reaches -2^(inbits-1)
entity dsssUnit is
	generic(inbits: integer := 10;
				outbits: integer := 20);
    Port(clk,rst: in std_logic;
			datain: in signed(inbits-1 downto 0); --unregistered
			codein: in std_logic; --unregistered
			dataout: out signed(outbits-1 downto 0) --registered
			);
end dsssUnit;
architecture a of dsssUnit is
	signal mult1,mult2: signed(inbits-1 downto 0);
	signal acc,accNext: signed(outbits-1 downto 0);
begin
	mult1 <= datain when codein='1' else -datain;
	mult2 <= mult1 when rising_edge(clk);
	
	--prevent overflow; if acc(msb) != acc(msb-1),
	--then overflow is imminent
	accNext <= resize(mult2,outbits) when rst='1'
		else acc when acc(outbits-1)/=acc(outbits-2)
		else acc+resize(mult2,outbits);
	acc <= accNext when rising_edge(clk);
	dataout <= acc when rst='1' and rising_edge(clk);
end architecture;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
use work.dsssCode1;
use work.dsssUnit;
use work.slow_clock;
use work.sr_unsigned;
use work.sr_bit;
use work.sr_signed;
use work.pulseExtender;
entity dsssDecoder is
	generic(inbits: integer := 10);
    Port(clk: in std_logic;
			--registered
			datain: in signed(inbits-1 downto 0);
			debug1: out unsigned(15 downto 0);
			debug2,debug3: out std_logic;
			debug4: in std_logic;
			up,down: out std_logic);
end dsssDecoder;

architecture a of dsssDecoder is
	constant codeLen_order: integer := 10;
	constant codeLen: integer := 2**codeLen_order;
	constant codeStretch: integer := 20;
	constant despread_bits: integer := inbits+13;
	
	signal in1: signed(inbits-1 downto 0);
	signal in2: signed(inbits*2-1 downto 0);
	constant in3_bits: integer := inbits*2-1;
	constant in3_max: integer := (2**(in3_bits-1))-1;
	signal in3,in4: signed(in3_bits-1 downto 0);
	
	
	--code generation
	--codeposReal is the address that 'code' is associated with
	signal codepos,codeposNext,codeposReal: unsigned(codeLen_order-1 downto 0);
	constant b: integer := integer(ceil(log2(real(codeStretch))));
	signal codephase,codephaseNext: unsigned(b-1 downto 0);
	signal code_en,code_en_prev: std_logic; --code_en is high when code rom is to be advanced
	signal code_rst0: std_logic;
	signal code_rst: std_logic; --high when 'code' is referring to the 0th bit of the stretched code
	signal code: std_logic;
	
	--delay & correlate
	constant shifts: integer := 8;
	type shifted_t is array(0 to shifts-1) of signed(in3_bits-1 downto 0);
	signal shifted: shifted_t;
	
	type outputs_t is array(0 to shifts-1) of signed(despread_bits-1 downto 0);
	signal outputs: outputs_t;
	
	--compare correlation sample points
	type abs1_t is array(0 to shifts-1) of unsigned(despread_bits-1 downto 0);
	signal abs1,abs1Next: abs1_t;
	
	type trunc1_t is array(0 to shifts-1) of unsigned(despread_bits-1 downto 0);
	signal trunc1: trunc1_t;
	
	signal sum1,sum2: unsigned(despread_bits-1 downto 0);
	signal dir,dirNext: std_logic; -- 1 means sum1 too high, 0 means sum2 too high
	
	--keep track of how many bitslip indications there are
	signal cnt,cntNext: signed(3 downto 0); -- counter of dir
	
	signal delayTooLow,delayTooHigh: std_logic;
	signal doIncrDelay,doDecrDelay: std_logic;
	signal prevIncr,prevDecr: std_logic;
	signal codepos_is_0: std_logic;
	signal doAdjustDelay_2,doAdjustDelay_1,doAdjustDelay: std_logic;
	
	--outputs
	signal upNext,downNext: std_logic;
begin
	--square the input signal
	in1 <= datain when rising_edge(clk);
	in2 <= in1*in1 when rising_edge(clk);
	in3 <= to_signed(in3_max,in3_bits) when in2=(in3_max+1)
		else signed(in2(in3_bits-1 downto 0));
	in4 <= in3 when rising_edge(clk);
	
	--generate code
	codephaseNext <=
		codephase+2 when doDecrDelay='1' and doAdjustDelay='1' else
		codephase when doIncrDelay='1' and doAdjustDelay='1' else
		to_unsigned(0,b) when codephase=codeStretch-1 else
		codephase+1;
	codephase <= codephaseNext when rising_edge(clk);
	code_en <= '1' when codephase=0 else '0';
	--sc_code: entity slow_clock generic map(codeStretch,1) port map(clk,code_en);
	codeposNext <=
		--to_unsigned(0,codeLen_order)
		--	when doDecrDelay='1' and codepos=(codeLen-2)
		--else to_unsigned(0,codeLen_order)
		--	when doIncrDelay='1' and codepos=0
		--else
			codepos+1;
	codepos <= codeposNext when code_en='1' and rising_edge(clk);
	code_gen: entity dsssCode1 port map(clk=>clk,addr=>codepos,data=>code);
	code_en_prev <= code_en when rising_edge(clk);
	code_rst0 <= '1' when codepos=0 and code_en_prev='1' else '0';
	
	sr_codepos: entity sr_unsigned generic map(bits=>codeLen_order,len=>2)
		port map(clk=>clk,din=>codepos,dout=>codeposReal);
	sr_rst: entity sr_bit generic map(2)
		port map(clk=>clk,din=>code_rst0,dout=>code_rst);
	
	--shift and correlate
	shifted(0) <= in4;
	sr1: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(0),dout=>shifted(1));
	sr2: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(1),dout=>shifted(2));
	sr3: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(2),dout=>shifted(3));
	sr4: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(3),dout=>shifted(4));
	sr5: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(4),dout=>shifted(5));
	sr6: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(5),dout=>shifted(6));
	sr7: entity sr_signed generic map(bits=>in3_bits,len=>20)
		port map(clk=>clk,din=>shifted(6),dout=>shifted(7));

g:	for I in 0 to shifts-1 generate
		unit: entity dsssUnit generic map(inbits=>in3_bits,
				outbits=>despread_bits)
			port map(clk=>clk,rst=>code_rst,datain=>shifted(I),
				codein=>code,dataout=>outputs(I));
	end generate;
	
	--compare sample points and decide whether to skip
	--take absolute value of all sample points
g2:for I in 0 to shifts-1 generate
		abs1Next(I) <= unsigned(outputs(I)) when outputs(I)(despread_bits-1)='0'
			else unsigned(-outputs(I));
	end generate;
	abs1 <= abs1Next when rising_edge(clk);
g3:for I in 0 to shifts-1 generate
		trunc1(I) <= "00" & abs1(I)(despread_bits-1 downto 2);
	end generate;
	--sum all the points on the left (sum1) and on the right (sum2)
	sum1 <= trunc1(0)+trunc1(1)+trunc1(2)+trunc1(3) when rising_edge(clk);
	sum2 <= trunc1(4)+trunc1(5)+trunc1(6)+trunc1(7) when rising_edge(clk);
	
	debug1 <= abs1(2)(despread_bits-3 downto despread_bits-6) &
				abs1(3)(despread_bits-3 downto despread_bits-6) &
				abs1(4)(despread_bits-3 downto despread_bits-6) &
				abs1(5)(despread_bits-3 downto despread_bits-6);
	--calculate which side is higher (plus some bias)
	dirNext <= '1' when (sum1+sum1/16)>(sum2) else '0';
	dir <= dirNext xor debug4 when rising_edge(clk);
	
	--keep count of which side has been high
	cntNext <= cnt+1 when cnt/="0111" and dir='1' else
		cnt-1 when cnt/="1001" and dir='0' else
		cnt;
	cnt <= cntNext when codeposReal=10 and rising_edge(clk);
	
	--if counter reaches maximum/minimum, request to decrease/increase delay
	--delayTooLow <= '1' when cnt="1001" else '0';
	--delayTooHigh <= '1' when cnt="0111" else '0';
	delayTooLow <= not dir;
	delayTooHigh <= dir;
	
	debug2 <= delayTooLow;
	debug3 <= delayTooHigh;
	
	--only adjust delay if there hasn't been an adjustment in the same
	--direction in the previous code period
	codepos_is_0 <= '1' when codepos=0 else '0';
	doIncrDelay <= delayTooLow when rising_edge(clk);
	doDecrDelay <= delayTooHigh when rising_edge(clk);
	--take note of adjustment (to be used in the next code period)
	prevIncr <= doIncrDelay when codeposReal=12 and rising_edge(clk);
	prevDecr <= doDecrDelay when codeposReal=12 and rising_edge(clk);
	
	--only perform adjustment at certain points of the code
	doAdjustDelay_2 <= '1' when codepos=0 and
		(codephase=0) else '0';
	ext1: entity pulseExtender generic map(true,2)
		port map(clk=>clk,inp=>doAdjustDelay_2,outp=>doAdjustDelay);
	--doAdjustDelay_1 <= doAdjustDelay_2 when rising_edge(clk);
	--doAdjustDelay <= doAdjustDelay_2 when rising_edge(clk);
	
	--outputs
	upNext <= '1' when doIncrDelay='1' and codeposReal=12 and codephase=0 else '0';
	downNext <= '1' when doDecrDelay='1' and codeposReal=12 and codephase=0 else '0';
	up <= upNext when rising_edge(clk);
	down <= downNext when rising_edge(clk);
end a;


