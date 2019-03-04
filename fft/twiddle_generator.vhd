library ieee;
library work;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.fft_types.all;

-- read delay is 6 cycles

entity twiddleGenerator is
	generic(twiddleBits: integer := 8;
				-- real depth is 2^depth_order
				depthOrder: integer := 9);
	port(clk: in std_logic;
			-- read side; synchronous to rdclk
			rdAddr: in unsigned(depthOrder-1 downto 0);
			rdData: out complex;
			
			-- external rom delay should be 2 cycles
			romAddr: out unsigned(depthOrder-4 downto 0);
			romData: in std_logic_vector(twiddleBits*2-3 downto 0)
			);
end entity;
architecture a of twiddleGenerator is
	constant width: integer := twiddleBits*2;
	
	constant romDepthOrder: integer := depthOrder-3;
	constant romDepth: integer := 2**romDepthOrder;
	constant romWidth: integer := (twiddleBits-1)*2;
	
	
	signal romAddr0,romAddrNext: unsigned(romDepthOrder-1 downto 0) := (others=>'0');
	signal phase,phase1,phase2,phase3: unsigned(depthOrder-1 downto 0) := (others=>'0');
	signal ph3,ph4: unsigned(2 downto 0) := (others=>'0');
	
	signal re,im,re0,im0, re_P, re_M, im_P, im_M: integer;
	signal outData: complex;
	
	--ram
	--type ram1t is array(romDepth-1 downto 0) of
	--	unsigned(romWidth-1 downto 0);
	--signal rom: ram1t;
begin
	romAddrNext <= rdAddr(depthOrder-4 downto 0)-1 when rdAddr(depthOrder-3)='0'
				else (not rdAddr(depthOrder-4 downto 0));
	romAddr0 <= romAddrNext when rising_edge(clk);
	phase <= rdAddr when rising_edge(clk);
	romAddr <= romAddr0;
	-- 1 cycles
	
	-- external rom latency is 2 cycles
	phase1 <= phase when rising_edge(clk);
	phase2 <= phase1 when rising_edge(clk);
	-- 3 cycles
	
	re0 <= (2**(twiddleBits-1))-1 when phase2(depthOrder-3 downto 0)=0 else
		to_integer(unsigned(romData(twiddleBits-2 downto 0)));
	im0 <= 0 when phase2(depthOrder-3 downto 0)=0 else
		to_integer(unsigned(romData(romData'left downto twiddleBits-1)));
	re <= re0 when rising_edge(clk);
	im <= im0 when rising_edge(clk);
	phase3 <= phase2 when rising_edge(clk);
	ph3 <= phase3(phase3'left downto phase3'left-2);
	-- 4 cycles
	
	re_P <= re when rising_edge(clk);
	re_M <= -re when rising_edge(clk);
	im_P <= im when rising_edge(clk);
	im_M <= -im when rising_edge(clk);
	ph4 <= ph3 when rising_edge(clk);
	-- 5 cycles
	
	outData <= to_complex(re_P,im_P)	when ph4=0 else
				to_complex(im_P,re_P)	when ph4=1 else
				to_complex(im_M,re_P)	when ph4=2 else
				to_complex(re_M,im_P)	when ph4=3 else
				to_complex(re_M,im_M)	when ph4=4 else
				to_complex(im_M,re_M)	when ph4=5 else
				to_complex(im_P,re_M)	when ph4=6 else
				to_complex(re_P,im_M); --when ph4=7;
	rdData <= outData when rising_edge(clk);
	-- 6 cycles
end a;
