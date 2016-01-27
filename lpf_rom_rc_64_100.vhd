library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

-- raised cosine filter rom
-- clock division factor: 64
-- signal frequency division factor: 100
-- depth: 8 periods
entity lpf_rom_rc_64_100 is
	port(addr1,addr2: in unsigned(5 downto 0);
			clk: in std_logic;
			--output consists of 12 8-bit signed 2's complement
			--fractions (all bits fractional);
			--data[0] is sinc(0)&sinc(1)&sinc(2)...
			--data[1] is sinc(0+1/125)&sinc(1+1/125)&...
			q1,q2: out signed(95 downto 0));
end entity;
architecture a of lpf_rom_rc_64_100 is
	type rom1t is array(0 to 63) of signed(95 downto 0);
	signal rom1: rom1t := (
X"0302fb0107f9fc0ff8e93b7f",
X"0302fb0107f9fc0ff9e93a7f",
X"0302fb0107fafb0ff9e9387f",
X"0302fb0007fafb0ffae8367f",
X"0302fb0007fafb0ffbe8357f",
X"0302fb0007fafa0ffbe7337e",
X"0202fb0007fbfa0efce7317e",
X"0202fb0007fbfa0efce7307e",
X"0202fcff07fbfa0efde62e7e",
X"0202fcff07fbf90efee62c7d",
X"0203fcff07fcf90efee62a7d",
X"0203fcff07fcf90effe6297d",
X"0203fcff07fcf90dffe6277c",
X"0203fcff07fcf80d00e5257c",
X"0203fcfe07fdf80d01e5247b",
X"0203fcfe07fdf80d01e5227b",
X"0203fcfe07fdf80c02e5217a",
X"0203fcfe07fdf80c02e51f79",
X"0203fcfe07fef70c03e51d79",
X"0103fcfe07fef70c03e51c78",
X"0103fdfe07fef70b04e51a77",
X"0103fdfd07fef70b05e51976",
X"0103fdfd07fff70b05e51776",
X"0103fdfd07fff70b06e51575",
X"0103fdfd07fff70a06e51474",
X"0103fdfd07fff60a07e61273",
X"0103fdfd0600f60a07e61172",
X"0103fdfd0600f60908e60f71",
X"0104fdfd0600f60908e60e70",
X"0104fefc0600f60908e60c6f",
X"0004fefc0601f60809e70b6e",
X"0004fefc0601f60809e70a6d",
X"0004fefc0601f6070ae7086b",
X"0004fefc0601f6070ae8076a",
X"0004fefc0602f6070ae80669",
X"0004fefc0602f6060be80468",
X"0004fefc0502f6060be90367",
X"0004fefc0502f6060ce90265",
X"0004fffc0502f6050cea0064",
X"0004fffc0503f6050ceaff63",
X"0004fffb0503f6040ceafe61",
X"0004fffb0503f6040debfd60",
X"ff04fffb0503f6040debfc5e",
X"ff04fffb0404f6030decfb5d",
X"ff04fffb0404f6030decf95c",
X"ff04fffb0404f6030eedf85a",
X"ff0400fb0404f6020eedf759",
X"ff0400fb0404f6020eeef657",
X"ff0400fb0404f7010eeef556",
X"ff0400fb0405f7010eeff454",
X"ff0300fb0305f7010ff0f352",
X"ff0300fb0305f7000ff0f351",
X"ff0300fb0305f7000ff1f24f",
X"ff0300fb0305f7000ff1f14e",
X"ff0301fb0305f7ff0ff2f04c",
X"fe0301fb0206f8ff0ff2ef4a",
X"fe0301fb0206f8fe0ff3ee49",
X"fe0301fb0206f8fe0ff4ee47",
X"fe0301fb0206f8fe0ff4ed46",
X"fe0301fb0206f8fd0ff5ec44",
X"fe0301fb0206f8fd0ff6ec42",
X"fe0301fb0106f9fd0ff6eb41",
X"fe0301fb0106f9fc0ff7eb3f",
X"fe0302fb0106f9fc0ff7ea3d"
);
	signal addr11,addr21: unsigned(5 downto 0);
begin
	addr11 <= addr1 when rising_edge(clk);
	addr21 <= addr2 when rising_edge(clk);
	q1 <= rom1(to_integer(addr11)) when rising_edge(clk);
	q2 <= rom1(to_integer(addr21)) when rising_edge(clk);
end architecture;
