library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vnaTx is
	generic(adcBits: integer := 10;
			sgBits: integer := 9
			);
	port(clk: in std_logic;
		adcData: in signed(adcBits-1 downto 0);
		sg_im,sg_re: in signed(sgBits-1 downto 0);
		
		-- serial data out
		txdat: out std_logic_vector(7 downto 0);
		txval: out std_logic
	);
end entity;

architecture a of vnaTx is
	constant resultBits: integer := adcBits+sgBits;
	constant accumBits: integer := 35;


	-- state machine
	signal accumPhase: unsigned(11 downto 0);

	-- mixer
	signal mixed_re,mixed_im: signed(adcBits+sgBits-1 downto 0);
	-- accumulator
	signal accum_re,accum_im,accum_reNext,accum_imNext: signed(accumBits-1 downto 0);
	
	-- serial tx
	type txSR_t is array(9 downto 0) of signed(7 downto 0);
	signal txSR, txSRNext, txValue: txSR_t;
	signal txvalNext: std_logic;
	
	
begin
	-- state machine
	accumPhase <= accumPhase+1 when rising_edge(clk);

	-- quadrature mixer
	mixed_re <= adcData*sg_re when rising_edge(clk);
	mixed_im <= adcData*sg_im when rising_edge(clk);
	
	-- accumulator
	accum_reNext <= resize(mixed_re,accumBits) when accumPhase=0 else accum_re+resize(mixed_re,accumBits);
	accum_imNext <= resize(mixed_im,accumBits) when accumPhase=0 else accum_im+resize(mixed_im,accumBits);
	accum_re <= accum_reNext when rising_edge(clk);
	accum_im <= accum_imNext when rising_edge(clk);
	
	-- tx shift register
	txValue <= ("1"&accum_re(34 downto 28), "1"&accum_re(27 downto 21), "1"&accum_re(20 downto 14), 
				"1"&accum_re(13 downto 7), "1"&accum_re(6 downto 0), 
				"1"&accum_im(34 downto 28), "1"&accum_im(27 downto 21), "1"&accum_im(20 downto 14), 
				"1"&accum_im(13 downto 7), "0"&accum_im(6 downto 0));
	txSRNext <= txValue when accumPhase=0 else ("00000000") & txSR(9 downto 1);
	txSR <= txSRNext when rising_edge(clk);
	
	txdat <= std_logic_vector(txSR(0));
	txvalNext <= '1' when accumPhase<10 else '0';
	txval <= txvalNext when rising_edge(clk);
	
end architecture;
