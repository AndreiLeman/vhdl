library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity agc is
	generic(inbits,outbits: integer;
			extraGainBits: integer := 3);
	port(clk: in std_logic;
		din: in signed(inbits-1 downto 0);		--unregistered
		dout: out signed(outbits-1 downto 0);	--registered
		clken: in std_logic := '1'
		);
end entity;
architecture a of agc is
	signal gain,gainNext: unsigned(inbits+extraGainBits-1 downto 0);
	signal gainSigned: signed(inbits downto 0);
	signal tmp: signed(inbits*2 downto 0);
	signal tmpOut: signed(outbits-1 downto 0);
	signal adjust: std_logic;
begin
	--multiply din with gain
	gainSigned <= "0"&signed(gain(inbits+extraGainBits-1 downto extraGainBits));
	tmp <= din*gainSigned when clken='1' and rising_edge(clk);
	
	--clip the output of the multiplier
	tmpOut <= to_signed(2**(outbits-2),outbits) when tmp(inbits*2-1 downto inbits)>=2**(outbits-2)
		else to_signed(-2**(outbits-2),outbits) when tmp(inbits*2-1 downto inbits)<=-2**(outbits-2)
		else tmp(inbits+outbits-1 downto inbits);
	
	--compare absolute value of output to threshold and set adjust
	adjust <= '1' when abs(tmp(inbits*2-1 downto inbits))<2**(outbits-4)
		else '0'; --adjust down
	
	--adjust gain
	gainNext <= gain when gain=2**(inbits+extraGainBits)-1 and adjust='1' else
				gain when gain=0 and adjust='0' else
				gain+1 when adjust='1' else
				gain-1;
	gain <= gainNext when clken='1' and rising_edge(clk);
	
	--output
	dout <= tmpOut when rising_edge(clk);
end a;
