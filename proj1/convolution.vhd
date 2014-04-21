library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity convolution is
	port (clk: in std_logic;
			input: in signed(15 downto 0);
			output: out signed(15 downto 0);
			coef_write: in unsigned(5 downto 0);
			coef_write_en: in std_logic;
			coef_value: in signed(15 downto 0);
			scale_factor: in unsigned(15 downto 0));
end entity;
architecture a of convolution is
	type coef_storage is array(63 downto 0) of signed(15 downto 0);
	type temp_storage is array(63 downto 0) of signed(31 downto 0);
	subtype temp_type is signed(31 downto 0);
	type a32 is array(31 downto 0) of temp_type;
	type a16 is array(15 downto 0) of temp_type;
	type a8 is array(7 downto 0) of temp_type;
	type a4 is array(3 downto 0) of temp_type;
	type a2 is array(1 downto 0) of temp_type;
	signal coefficients: coef_storage;
	signal past_values: coef_storage;
	signal temp: temp_storage;
	signal add1: a32;
	signal add2: a16;
	signal add3: a8;
	signal add4: a4;
	signal add5: a2;
	signal final: signed(31 downto 0);
begin
gen_demux:
	for I in 0 to 63 generate
		coefficients(I) <= coef_value when coef_write=I and coef_write_en='1';
	end generate;
gen_shifts:
	for I in 0 to 62 generate
		past_values(I) <= past_values(I+1) when rising_edge(clk);
	end generate;
	past_values(63) <= input when rising_edge(clk);
gen_multiply:
	for I in 0 to 63 generate
		temp(I) <= signed(past_values(I)) * signed(coefficients(I));
	end generate;
gen_add1:
	for I in 0 to 31 generate
		add1(I) <= temp(I*2) + temp(I*2+1);
	end generate;
gen_add2:
	for I in 0 to 15 generate
		add2(I) <= add1(I*2) + add1(I*2+1);
	end generate;
gen_add3:
	for I in 0 to 7 generate
		add3(I) <= add2(I*2) + add2(I*2+1);
	end generate;
gen_add4:
	for I in 0 to 3 generate
		add4(I) <= add3(I*2) + add3(I*2+1);
	end generate;
	add5(0) <= add4(0) + add4(1);
	add5(1) <= add4(2) + add4(3);
	final <= add5(0) + add5(1);
	output <= final(31 downto 16);
end architecture;

