library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
-- purely combinational circuit that translates keycodes to frequencies
entity ps2Piano is
	port(key: in unsigned(7 downto 0); --unregistered
			note_shift: in unsigned(7 downto 0);
			freq: out unsigned(23 downto 0));
end entity;
architecture a of ps2Piano is
	type key_lut_t is array(0 to 255) of unsigned(7 downto 0);
	signal key_lut: key_lut_t :=
--    0     1     2     3     4     5     6     7     8     9     a     b     c     d     e     f
	(X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"0c",X"0b",X"00",--0
	X"00",X"00",X"00",X"00",X"00",X"0d",X"00",X"00",X"00",X"00",X"01",X"02",X"00",X"0f",X"0e",X"00", --1
	X"00",X"05",X"03",X"04",X"11",X"00",X"10",X"00",X"00",X"00",X"06",X"00",X"14",X"12",X"13",X"00", --2
	X"00",X"0a",X"08",X"09",X"07",X"16",X"15",X"00",X"00",X"00",X"0c",X"0b",X"18",X"17",X"00",X"00", --3
	X"00",X"0d",X"00",X"19",X"1b",X"1c",X"1a",X"00",X"00",X"0f",X"11",X"0e",X"10",X"1d",X"00",X"00", --4
	X"00",X"00",X"00",X"00",X"1e",X"1f",X"00",X"00",X"00",X"12",X"13",X"20",X"00",X"22",X"00",X"00", --5
	X"00",X"00",X"00",X"00",X"00",X"00",X"21",X"00",X"00",X"00",X"00",X"00",X"23",X"00",X"00",X"00", --6
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"24",X"00",X"00", --7
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --8
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --9
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --a
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --b
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --c
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --d
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00", --e
	X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00",X"00");--f
	signal note,tmp_note: unsigned(7 downto 0);
	constant tworoot12: real := 1.0594630943592953; -- 2**(1/12)
	-- 12 bit integer, 12 bit fraction
	type tworoot12_exp_array_t is array(0 to 6) of unsigned(23 downto 0);
	signal tworoot12_exp_array: tworoot12_exp_array_t;
	signal freq_components: tworoot12_exp_array_t;
	signal tmp1,tmp2,tmp3,tmp4,tmp5,tmp6,tmp7: unsigned(47 downto 0);
	signal base_freq: unsigned(23 downto 0); -- all fractional
begin
	tmp_note <= key_lut(to_integer(key));
	note <= tmp_note+note_shift-1;
gen:
	for I in 0 to 6 generate
		--tworoot12_exp_array(I) <= to_unsigned((tworoot12**real(integer(2)**I))*(integer(2)**12),24);
		freq_components(I) <= tworoot12_exp_array(I) when note(I)='1' else to_unsigned(2**12,24);
	end generate;
	tworoot12_exp_array(0) <= to_unsigned(4340,24);
	tworoot12_exp_array(1) <= to_unsigned(4598,24);
	tworoot12_exp_array(2) <= to_unsigned(5161,24);
	tworoot12_exp_array(3) <= to_unsigned(6502,24);
	tworoot12_exp_array(4) <= to_unsigned(10321,24);
	tworoot12_exp_array(5) <= to_unsigned(26008,24);
	tworoot12_exp_array(6) <= to_unsigned(165140,24);
	tmp1 <= freq_components(0)*freq_components(1);
	tmp2 <= freq_components(2)*freq_components(3);
	tmp3 <= freq_components(4)*freq_components(5);
	tmp4 <= tmp1(35 downto 12)*tmp2(35 downto 12);
	tmp5 <= tmp3(35 downto 12)*freq_components(6);
	tmp6 <= tmp4(35 downto 12)*tmp5(35 downto 12);
	base_freq <= to_unsigned(integer(real((98.0/48828.1)*real(integer(2)**24))),24);
	tmp7 <= tmp6(35 downto 12)*base_freq;
	freq <= to_unsigned(0,24) when tmp_note=0 else tmp7(35 downto 12);
end architecture;
