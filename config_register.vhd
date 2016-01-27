library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
USE ieee.math_real.log2;
USE ieee.math_real.ceil;
entity config_register is
	generic(addrlen: integer := 1;
				words: integer := 2;		--how many output words to create
				inpWords: integer := 0;	--how many input words to create
				dummy: integer := 1);	--dummy bits in conduit_in (to work around qsys error when inpWords=0)
	port(addr: in std_logic_vector(addrlen-1 downto 0);
			read,write: in std_logic;
			readdata: out std_logic_vector(31 downto 0);
			writedata: in std_logic_vector(31 downto 0);
			conduit: out std_logic_vector(words*32-1 downto 0);
			conduit_in: in std_logic_vector(inpWords*32-1+dummy downto 0);
			rst,clk: in std_logic);
end entity;
architecture a of config_register is
	constant totalWords: integer := words+inpWords;
	type arr is array(totalWords-1 downto 0) of std_logic_vector(31 downto 0);
	signal mem: arr := (others=>X"00000000");
	signal mem1: std_logic_vector(words*32-1 downto 0);
	signal addr1: unsigned(addrlen-1 downto 0);
	signal read1,write1: std_logic;
	signal writedata1: std_logic_vector(31 downto 0);
	
	--signal ff1,ff2: std_logic_vector(words*32-1 downto 0);
	--signal rdreq,rdreq1,rdreq2,rdreq3,ready,ready1,ready2,ready3: std_logic;
	--signal clk_ff1,clk_ff2: std_logic;
begin
	addr1 <= unsigned(addr) when rising_edge(clk);
	read1 <= read when rising_edge(clk);
	write1 <= write when rising_edge(clk);
	writedata1 <= writedata when rising_edge(clk);
	--mem(to_integer(addr1)) <= writedata when write1='1';
gen_mem:
	for I in 0 to words-1 generate
		mem(I) <= X"00000000" when rst='1' and rising_edge(clk) else
			writedata1 when write1='1' and addr1=I and rising_edge(clk);
	end generate;
gen_inp:
	for I in 0 to inpWords-1 generate
		mem(words+I) <= conduit_in((I+1)*32-1 downto I*32);
	end generate;
	readdata <= mem(to_integer(addr1)) when rising_edge(clk);
	
gen:
	for I in 0 to words-1 generate
		mem1(((I+1)*32)-1 downto I*32) <= mem(I);
	end generate;
	conduit <= mem1;
	
--	rdreq1 <= rdreq when rising_edge(clk);
--	rdreq2 <= rdreq1 when rising_edge(clk);
--	rdreq3 <= rdreq2 when rising_edge(clk);
--	ready <= rdreq1 and rdreq2 and rdreq3 when rising_edge(clk);
--	ready1 <= ready when rising_edge(cclk);
--	ready2 <= ready1 when rising_edge(cclk);
--	ready3 <= ready2 when rising_edge(cclk);
--	clk_ff2 <= ready1 and ready2 and ready3 when rising_edge(cclk);
--	clk_ff1 <= rdreq1;
--	rdreq <= not clk_ff2;
--	
--	ff1 <= mem1 when rising_edge(clk_ff1);
--	ff2 <= ff1 when rising_edge(clk_ff2);
--	conduit <= ff2;
end architecture;
