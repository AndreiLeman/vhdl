library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity zxcv is
	port (datain: in std_logic_vector(3 downto 0);
			addr: in unsigned(2 downto 0);
			write_en: in std_logic;
			dataout: out std_logic_vector(3 downto 0));
end entity;

architecture a of zxcv is
	subtype cell is std_logic_vector(3 downto 0);
	type mem is array(3 downto 0) of cell;
	signal data: mem;
begin
gen_writes:
	for I in 0 to 3 generate
		data(I) <= datain when addr=I and write_en='1';
	end generate;
	--data(to_integer(addr)) <= datain when write_en='1';
	dataout <= data(to_integer(addr));
end architecture;

