--  Hello world program
library ieee;
library work;
use std.textio.all; -- Imports the standard textio package.
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;
use work.fft256_serial;

--  Defines a design entity, without any ports.
entity test_fft256_serial is
end test_fft256_serial;

architecture behaviour of test_fft256_serial is
	signal clk: std_logic := '0';
	signal din: complex;
	signal phase: unsigned(7 downto 0);
	signal dout: complex;
	signal debug1: integer;
	constant delay: integer := 256+110;
begin
	fft: entity fft256_serial port map(
			clk,din,phase,dout,open);
	process
		variable l : line;
		variable i1,i2,row,col: integer := 0;
		-- 2 full frames
		type arr_t is array(0 to 1023) of integer;
		variable arr: arr_t;
	begin
		--arr := (0=>256, others=>0);
		for I in 0 to 511 loop
			arr(I*2) := (I*I) rem 1024;
			arr(I*2+1) := (I*(I+13)) rem 1024;
		end loop;
		phase <= (others=>'0');
		for I in 0 to 255 loop
			din <= to_complex(0,0);
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			phase <= phase+1;
		end loop;
		
		for I in 0 to 511+delay loop
			i2 := I/256;
			i1 := I rem 256;
			row := i1 rem 16;
			col := i1/16;
			
			-- input row order is transposed
			row := (row rem 4)*4 + row/4;
			i1 := i2*256 + row*16 + col;
			
			if I >= 512 then
				din <= to_complex(0,0);
			else
				din <= to_complex(arr(i1*2),arr(i1*2+1));
			end if;
			
			
			if I >= delay then
				write(output, integer'image(I-delay) & ": ");
				write(output, complex_str(dout) & LF);
			end if;
			wait for 1 ns; clk <= '1'; wait for 1 ns; clk <= '0';
			--write(output, integer'image(debug1) & LF);
			phase <= phase+1;
		end loop;
		
		wait;
	end process;
end behaviour;
