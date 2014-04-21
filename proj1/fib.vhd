library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

--64 bit adder with 2 pipeline stages
entity add64_2 is
	port(clk: in std_logic;
			a,b: in unsigned(63 downto 0);
			outp: out unsigned(63 downto 0));
end entity;
architecture a of add64_2 is
	signal l32_res: unsigned(32 downto 0);
	signal l32_out: unsigned(31 downto 0);
	signal u32_a,u32_b: unsigned(31 downto 0);
begin
	u32_a <= a(63 downto 32) when rising_edge(clk);
	u32_b <= b(63 downto 32) when rising_edge(clk);
	l32_res <= ("0"&a(31 downto 0))+("0"&b(31 downto 0)) when rising_edge(clk);
	outp <= (u32_a+u32_b+(30 downto 0=>'0') & l32_out(32)) & l32_out(31 downto 0);
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity fib is
	port(clk: in std_logic;
			outp: out unsigned(63 downto 0));
end entity;
architecture a of fib is
	signal cv1,cv2,nv: unsigned(63 downto 0) := to_unsigned(1,64);
begin
	nv <= cv1+cv2;
	cv1 <= cv2 when rising_edge(clk);
	cv2 <= nv when rising_edge(clk);
	outp <= cv1;
end architecture;

library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fib;
use work.de1_hexdisplay;
use work.counted_clock;
entity fibtest is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(0 to 9);
			KEY: in std_logic_vector(3 downto 0);
			SW: in std_logic_vector(9 downto 0);
			HEX0,HEX1,HEX2,HEX3,HEX4,HEX5: out std_logic_vector(6 downto 0));
end entity;
architecture a of fibtest is
	signal i,nexti: unsigned(63 downto 0);
	signal clk,realclk: std_logic;
	signal result,tmp: unsigned(63 downto 0);
	signal xxx: unsigned(63 downto 0);
	
	component pll1 is
		port (
			refclk   : in  std_logic := '0'; --  refclk.clk
			rst      : in  std_logic := '0'; --   reset.reset
			outclk_0 : out std_logic;        -- outclk0.clk
			locked   : out std_logic         --  locked.export
		);
	end component pll1;
begin
	pll: component pll1 port map(refclk=>CLOCK_50,outclk_0=>realclk);

	cc: counted_clock generic map(N=>1000000000) port map(inp=>realclk,outp=>clk);
	
	f: fib port map(clk=>clk, outp=>tmp);
	result <= tmp;-- when falling_edge(clk_en);
	xxx <= xxx+1 when rising_edge(clk);
	hd: de1_hexdisplay generic map(b=>16) 
		port map(HEX0=>HEX0,HEX1=>HEX1,HEX2=>HEX2,HEX3=>HEX3,HEX4=>HEX4,HEX5=>HEX5,
			data=>std_logic_vector(result),button1=>not KEY(1),button2=>not KEY(0));
end architecture;


