library IEEE;
library work;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity nios_testbench is
	port(CLOCK_50: in std_logic;
			LEDR: out std_logic_vector(9 downto 0);
			DRAM_LDQM,DRAM_UDQM,DRAM_RAS_N,DRAM_CAS_N,DRAM_CKE,
				DRAM_CLK,DRAM_WE_N,DRAM_CS_N: out std_logic;
			DRAM_ADDR: out std_logic_vector(12 downto 0);
			DRAM_DQ: inout std_logic_vector(15 downto 0);
			DRAM_BA: out std_logic_vector(1 downto 0)
			);
end entity;

architecture a of nios_testbench is
	 component nios_sdram is
	  port (
			clk_clk          : in    std_logic                     := 'X';             -- clk
			sdram_wire_addr  : out   std_logic_vector(12 downto 0);                    -- addr
			sdram_wire_ba    : out   std_logic_vector(1 downto 0);                     -- ba
			sdram_wire_cas_n : out   std_logic;                                        -- cas_n
			sdram_wire_cke   : out   std_logic;                                        -- cke
			sdram_wire_cs_n  : out   std_logic;                                        -- cs_n
			sdram_wire_dq    : inout std_logic_vector(15 downto 0) := (others => 'X'); -- dq
			sdram_wire_dqm   : out   std_logic_vector(1 downto 0);                     -- dqm
			sdram_wire_ras_n : out   std_logic;                                        -- ras_n
			sdram_wire_we_n  : out   std_logic;                                        -- we_n
			pio0_export      : out   std_logic_vector(31 downto 0)
	  );
 end component nios_sdram;
 signal dqm: std_logic_vector(1 downto 0);
 signal pio0: std_logic_vector(31 downto 0);
begin
	DRAM_LDQM <= dqm(0);
	DRAM_UDQM <= dqm(1);
	u0 : component nios_sdram
        port map (
            clk_clk          => CLOCK_50,          --        clk.clk
            sdram_wire_addr  => DRAM_ADDR,  -- sdram_wire.addr
            sdram_wire_ba    => DRAM_BA,    --           .ba
            sdram_wire_cas_n => DRAM_CAS_N, --           .cas_n
            sdram_wire_cke   => DRAM_CKE,   --           .cke
            sdram_wire_cs_n  => DRAM_CS_N,  --           .cs_n
            sdram_wire_dq    => DRAM_DQ,    --           .dq
            sdram_wire_dqm   => dqm,   --           .dqm
            sdram_wire_ras_n => DRAM_RAS_N, --           .ras_n
            sdram_wire_we_n  => DRAM_WE_N,  --           .we_n
				pio0_export      => pio0
        );
		  LEDR <= pio0(9 downto 0);
end architecture;
