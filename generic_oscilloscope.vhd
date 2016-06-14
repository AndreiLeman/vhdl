library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity counter_d is
	--counts from 0 (inclusive) to max (exclusive)
	generic(N: integer);
	port(clk: in std_logic;
			max: in unsigned(N-1 downto 0);
			outp: out unsigned(N-1 downto 0));
end entity;
architecture a of counter_d is
	signal cv: unsigned(N-1 downto 0) := to_unsigned(0,N);
	signal nv: unsigned(N-1 downto 0);
begin
	cv <= nv when rising_edge(clk);
	outp <= cv;
	nv <= cv+1 when cv<max else to_unsigned(0,N);
end architecture;

library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.osc_ram;
use work.counter_d;
use work.graphics_types.all;
--delay from p to outp is 3 videoclk cycles
entity generic_oscilloscope is
	port(dataclk,videoclk: in std_logic;
			samples_per_px: in unsigned(19 downto 0); --unregistered
			datain: in signed(15 downto 0); --unregistered
			W,H: in unsigned(11 downto 0);
			p: in position; --registered
			outp: out color; --registered
			stop: in std_logic := '0');
end entity;
architecture a of generic_oscilloscope is
	signal c1: color;
	signal nextpixel,nextpixel1,nextpixel2: std_logic;
	signal cur_max,next_max,cur_min,next_min,last2_max,last2_min: unsigned(11 downto 0);
	signal do_sample_waddr,do_sample_waddr1: std_logic;
	signal q1,q2: unsigned(11 downto 0);
	signal cntval: unsigned(19 downto 0);
	signal monoin1: signed(23 downto 0);
	signal monoin2: signed(12 downto 0);
	signal rec_in,rec_in1,rec_in2: unsigned(11 downto 0);
	signal raddr_base,rd_addr,wr_addr: unsigned(12 downto 0);
	signal ram_d,ram_q: std_logic_vector(23 downto 0);
	signal p1,p2: position;
	--p2 is the position that corresponds to the current ram_q datapoint
	--because the ram has 2 clock cycles of delay
begin
	cnt: entity counter_d generic map(N=>20) port map(clk=>dataclk,outp=>cntval,max=>samples_per_px-1);
	nextpixel <= '1' when cntval=0 else '0';
	nextpixel1 <= nextpixel when rising_edge(dataclk);
	--nextpixel2 <= nextpixel1 when falling_edge(dataclk);
	
	cur_max <= next_max when rising_edge(dataclk);
	cur_min <= next_min when rising_edge(dataclk);
	next_max <= last2_max when nextpixel1='1' else
		rec_in1 when rec_in1>cur_max else cur_max;
	next_min <= last2_min when nextpixel1='1' else
		rec_in1 when rec_in1<cur_min else cur_min;
	
	monoin1 <= datain(15 downto 4)*("0"&signed(H(11 downto 1)));
	monoin2 <= monoin1(23 downto 11) when rising_edge(dataclk);
	rec_in <= to_unsigned(0,12) when monoin2>0 and unsigned(monoin2)>H/2 else
		H-1 when monoin2<0 and unsigned(-monoin2)>=H/2 else
		H/2+unsigned(-monoin2(11 downto 0));
	rec_in1 <= rec_in when rising_edge(dataclk);
	rec_in2 <= rec_in1 when rising_edge(dataclk);
	last2_min <= rec_in1 when rec_in1<rec_in2 else rec_in2;
	last2_max <= rec_in1 when rec_in1>rec_in2 else rec_in2;
	ram_d <= std_logic_vector(cur_max) & std_logic_vector(cur_min);
	wr_addr <= wr_addr+1 when stop='0' and nextpixel1='1' and (not (wr_addr=raddr_base-1))
		and rising_edge(dataclk);
	mem: entity osc_ram port map(wrclock=>dataclk,wraddress=>std_logic_vector(wr_addr),
		data=>std_logic_vector(ram_d),wren=>'1',
		rdaddress=>std_logic_vector(rd_addr),rdclock=>videoclk,q=>ram_q);
	
	do_sample_waddr1 <= '1' when p(1)=H-1 and p(0)=W-2 else '0';
	do_sample_waddr <= do_sample_waddr1 when rising_edge(videoclk);
	raddr_base <= wr_addr-W+1 when do_sample_waddr='1' and rising_edge(videoclk);
	--addr input of ram is already registered
	rd_addr <= p(0)+raddr_base;-- when rising_edge(clk);
	
	q1 <= unsigned(ram_q(11 downto 0));
	q2 <= unsigned(ram_q(23 downto 12));
	p1 <= p when rising_edge(videoclk);
	p2 <= p1 when rising_edge(videoclk);
	
	c1(1) <= X"ff" when (p2(1)>=q1 and p2(1)<=q2) else X"00";
	c1(2) <= c1(1);
	c1(0) <= X"ff" when p2(1)=H/2 else X"00";
	outp <= c1 when rising_edge(videoclk);
end architecture;

