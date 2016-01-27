library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
package fir is
	type sampleArray is array(integer range <>) of signed(15 downto 0);
	type sampleArray2 is array(integer range <>) of signed(31 downto 0);
end package;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity simple2portram is
	generic(b,w: integer);
	port(raddr,waddr: in unsigned(b-1 downto 0);
			d: in std_logic_vector(w-1 downto 0);
			q: out std_logic_vector(w-1 downto 0);
			clk: in std_logic);
end entity;
architecture a of simple2portram is
	signal raddr2,waddr2: unsigned(b-1 downto 0);
	type data_t is array(2**b-1 downto 0) of std_logic_vector(w-1 downto 0);
	signal data: data_t;
begin
	raddr2 <= raddr when rising_edge(clk);
	waddr2 <= waddr when rising_edge(clk);
	q <= data(to_integer(raddr2));
	data(to_integer(waddr2)) <= d;
end architecture;

--16384 coefficients
--4 multiply-adds per clock cycle
--4096 clock cycles per new sample
library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity fir16k is
	generic(channels: integer := 1);
	port(clk,sampleclk: in std_logic;
			d: in sampleArray(channels-1 downto 0);
			coeff_addr: out unsigned(11 downto 0);
			coeff_q: in signed(63 downto 0);
			q: out sampleArray2(channels-1 downto 0));
end entity;
architecture a of fir16k is
	signal acc,acc_next: sampleArray2(channels-1 downto 0);
	signal waddr: unsigned(11 downto 0);
begin
	acc <= acc_next when rising_edge(clk);
	
end architecture;
