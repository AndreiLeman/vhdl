-- megafunction wizard: %ALTCLKCTRL%
-- GENERATION: STANDARD
-- VERSION: WM1.0
-- MODULE: altclkctrl 

-- ============================================================
-- File Name: altclkctra.vhd
-- Megafunction Name(s):
-- 			altclkctrl
--
-- Simulation Library Files(s):
-- 			cycloneive
-- ============================================================
-- ************************************************************
-- THIS IS A WIZARD-GENERATED FILE. DO NOT EDIT THIS FILE!
--
-- 13.1.0 Build 162 10/23/2013 SJ Web Edition
-- ************************************************************


--Copyright (C) 1991-2013 Altera Corporation
--Your use of Altera Corporation's design tools, logic functions 
--and other software and tools, and its AMPP partner logic 
--functions, and any output files from any of the foregoing 
--(including device programming or simulation files), and any 
--associated documentation or information are expressly subject 
--to the terms and conditions of the Altera Program License 
--Subscription Agreement, Altera MegaCore Function License 
--Agreement, or other applicable license agreement, including, 
--without limitation, that your use is for the sole purpose of 
--programming logic devices manufactured by Altera and sold by 
--Altera or its authorized distributors.  Please refer to the 
--applicable agreement for further details.


--altclkctrl CBX_AUTO_BLACKBOX="ALL" CLOCK_TYPE="Global Clock" DEVICE_FAMILY="Cyclone IV E" ENA_REGISTER_MODE="falling edge" USE_GLITCH_FREE_SWITCH_OVER_IMPLEMENTATION="OFF" clkselect ena inclk outclk
--VERSION_BEGIN 13.1 cbx_altclkbuf 2013:10:17:09:48:19:SJ cbx_cycloneii 2013:10:17:09:48:19:SJ cbx_lpm_add_sub 2013:10:17:09:48:19:SJ cbx_lpm_compare 2013:10:17:09:48:19:SJ cbx_lpm_decode 2013:10:17:09:48:19:SJ cbx_lpm_mux 2013:10:17:09:48:19:SJ cbx_mgl 2013:10:17:09:48:49:SJ cbx_stratix 2013:10:17:09:48:19:SJ cbx_stratixii 2013:10:17:09:48:19:SJ cbx_stratixiii 2013:10:17:09:48:19:SJ cbx_stratixv 2013:10:17:09:48:19:SJ  VERSION_END

 LIBRARY cycloneive;
 USE cycloneive.all;

--synthesis_resources = clkctrl 1 
 LIBRARY ieee;
 USE ieee.std_logic_1164.all;

 ENTITY  altclkctra_altclkctrl_7ji IS 
	 PORT 
	 ( 
		 clkselect	:	IN  STD_LOGIC_VECTOR (1 DOWNTO 0) := (OTHERS => '0');
		 ena	:	IN  STD_LOGIC := '1';
		 inclk	:	IN  STD_LOGIC_VECTOR (3 DOWNTO 0) := (OTHERS => '0');
		 outclk	:	OUT  STD_LOGIC
	 ); 
 END altclkctra_altclkctrl_7ji;

 ARCHITECTURE RTL OF altclkctra_altclkctrl_7ji IS

	 SIGNAL  wire_clkctrl1_outclk	:	STD_LOGIC;
	 SIGNAL  clkselect_wire :	STD_LOGIC_VECTOR (1 DOWNTO 0);
	 SIGNAL  inclk_wire :	STD_LOGIC_VECTOR (3 DOWNTO 0);
	 COMPONENT  cycloneive_clkctrl
	 GENERIC 
	 (
		clock_type	:	STRING;
		ena_register_mode	:	STRING := "falling edge";
		lpm_type	:	STRING := "cycloneive_clkctrl"
	 );
	 PORT
	 ( 
		clkselect	:	IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		ena	:	IN STD_LOGIC;
		inclk	:	IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		outclk	:	OUT STD_LOGIC
	 ); 
	 END COMPONENT;
 BEGIN

	clkselect_wire <= ( clkselect);
	inclk_wire <= ( inclk);
	outclk <= wire_clkctrl1_outclk;
	clkctrl1 :  cycloneive_clkctrl
	  GENERIC MAP (
		clock_type => "Global Clock",
		ena_register_mode => "falling edge"
	  )
	  PORT MAP ( 
		clkselect => clkselect_wire,
		ena => ena,
		inclk => inclk_wire,
		outclk => wire_clkctrl1_outclk
	  );

 END RTL; --altclkctra_altclkctrl_7ji
--VALID FILE


LIBRARY ieee;
USE ieee.std_logic_1164.all;

ENTITY altclkctra IS
	PORT
	(
		ena		: IN STD_LOGIC  := '1';
		inclk		: IN STD_LOGIC ;
		outclk		: OUT STD_LOGIC 
	);
END altclkctra;


ARCHITECTURE RTL OF altclkctra IS

	SIGNAL sub_wire0	: STD_LOGIC ;
	SIGNAL sub_wire1_bv	: BIT_VECTOR (1 DOWNTO 0);
	SIGNAL sub_wire1	: STD_LOGIC_VECTOR (1 DOWNTO 0);
	SIGNAL sub_wire2	: STD_LOGIC ;
	SIGNAL sub_wire3	: STD_LOGIC_VECTOR (3 DOWNTO 0);
	SIGNAL sub_wire4_bv	: BIT_VECTOR (2 DOWNTO 0);
	SIGNAL sub_wire4	: STD_LOGIC_VECTOR (2 DOWNTO 0);



	COMPONENT altclkctra_altclkctrl_7ji
	PORT (
			clkselect	: IN STD_LOGIC_VECTOR (1 DOWNTO 0);
			ena	: IN STD_LOGIC ;
			inclk	: IN STD_LOGIC_VECTOR (3 DOWNTO 0);
			outclk	: OUT STD_LOGIC 
	);
	END COMPONENT;

BEGIN
	sub_wire1_bv(1 DOWNTO 0) <= "00";
	sub_wire1    <= To_stdlogicvector(sub_wire1_bv);
	sub_wire4_bv(2 DOWNTO 0) <= "000";
	sub_wire4    <= To_stdlogicvector(sub_wire4_bv);
	outclk    <= sub_wire0;
	sub_wire2    <= inclk;
	sub_wire3    <= sub_wire4(2 DOWNTO 0) & sub_wire2;

	altclkctra_altclkctrl_7ji_component : altclkctra_altclkctrl_7ji
	PORT MAP (
		clkselect => sub_wire1,
		ena => ena,
		inclk => sub_wire3,
		outclk => sub_wire0
	);



END RTL;

-- ============================================================
-- CNX file retrieval info
-- ============================================================
-- Retrieval info: PRIVATE: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
-- Retrieval info: PRIVATE: SYNTH_WRAPPER_GEN_POSTFIX STRING "1"
-- Retrieval info: PRIVATE: clock_inputs NUMERIC "1"
-- Retrieval info: CONSTANT: ENA_REGISTER_MODE STRING "falling edge"
-- Retrieval info: CONSTANT: INTENDED_DEVICE_FAMILY STRING "Cyclone IV E"
-- Retrieval info: CONSTANT: USE_GLITCH_FREE_SWITCH_OVER_IMPLEMENTATION STRING "OFF"
-- Retrieval info: CONSTANT: clock_type STRING "Global Clock"
-- Retrieval info: USED_PORT: ena 0 0 0 0 INPUT VCC "ena"
-- Retrieval info: USED_PORT: inclk 0 0 0 0 INPUT NODEFVAL "inclk"
-- Retrieval info: USED_PORT: outclk 0 0 0 0 OUTPUT NODEFVAL "outclk"
-- Retrieval info: CONNECT: @clkselect 0 0 2 0 GND 0 0 2 0
-- Retrieval info: CONNECT: @ena 0 0 0 0 ena 0 0 0 0
-- Retrieval info: CONNECT: @inclk 0 0 3 1 GND 0 0 3 0
-- Retrieval info: CONNECT: @inclk 0 0 1 0 inclk 0 0 0 0
-- Retrieval info: CONNECT: outclk 0 0 0 0 @outclk 0 0 0 0
-- Retrieval info: GEN_FILE: TYPE_NORMAL altclkctrl.vhd TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL altclkctrl.inc FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL altclkctrl.cmp TRUE
-- Retrieval info: GEN_FILE: TYPE_NORMAL altclkctrl.bsf FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL altclkctrl_inst.vhd FALSE
-- Retrieval info: GEN_FILE: TYPE_NORMAL altclkctrl_syn.v TRUE
-- Retrieval info: LIB_FILE: cycloneive
