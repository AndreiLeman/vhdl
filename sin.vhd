library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
entity sin_rom is
	port(addr: in unsigned(8 downto 0);
			clk: in std_logic;
			q: out unsigned(7 downto 0));
end entity;
architecture a of sin_rom is
	type rom1t is array(0 to 511) of unsigned(7 downto 0);
	signal rom1: rom1t := (X"00",X"01",X"02",X"03",X"04",X"04",X"05",X"06",X"07",
		X"07",X"08",X"09",X"0A",X"0B",X"0B",X"0C",X"0D",X"0E",X"0E",X"0F",X"10",
		X"11",X"12",X"12",X"13",X"14",X"15",X"15",X"16",X"17",X"18",X"19",X"19",
		X"1A",X"1B",X"1C",X"1C",X"1D",X"1E",X"1F",X"20",X"20",X"21",X"22",X"23",
		X"23",X"24",X"25",X"26",X"27",X"27",X"28",X"29",X"2A",X"2A",X"2B",X"2C",
		X"2D",X"2E",X"2E",X"2F",X"30",X"31",X"31",X"32",X"33",X"34",X"34",X"35",
		X"36",X"37",X"37",X"38",X"39",X"3A",X"3B",X"3B",X"3C",X"3D",X"3E",X"3E",
		X"3F",X"40",X"41",X"41",X"42",X"43",X"44",X"44",X"45",X"46",X"47",X"47",
		X"48",X"49",X"4A",X"4A",X"4B",X"4C",X"4D",X"4D",X"4E",X"4F",X"50",X"50",
		X"51",X"52",X"53",X"53",X"54",X"55",X"56",X"56",X"57",X"58",X"58",X"59",
		X"5A",X"5B",X"5B",X"5C",X"5D",X"5E",X"5E",X"5F",X"60",X"60",X"61",X"62",
		X"63",X"63",X"64",X"65",X"66",X"66",X"67",X"68",X"68",X"69",X"6A",X"6B",
		X"6B",X"6C",X"6D",X"6D",X"6E",X"6F",X"6F",X"70",X"71",X"72",X"72",X"73",
		X"74",X"74",X"75",X"76",X"76",X"77",X"78",X"79",X"79",X"7A",X"7B",X"7B",
		X"7C",X"7D",X"7D",X"7E",X"7F",X"7F",X"80",X"81",X"81",X"82",X"83",X"83",
		X"84",X"85",X"85",X"86",X"87",X"87",X"88",X"89",X"89",X"8A",X"8B",X"8B",
		X"8C",X"8D",X"8D",X"8E",X"8F",X"8F",X"90",X"91",X"91",X"92",X"93",X"93",
		X"94",X"94",X"95",X"96",X"96",X"97",X"98",X"98",X"99",X"99",X"9A",X"9B",
		X"9B",X"9C",X"9D",X"9D",X"9E",X"9E",X"9F",X"A0",X"A0",X"A1",X"A1",X"A2",
		X"A3",X"A3",X"A4",X"A4",X"A5",X"A6",X"A6",X"A7",X"A7",X"A8",X"A9",X"A9",
		X"AA",X"AA",X"AB",X"AC",X"AC",X"AD",X"AD",X"AE",X"AE",X"AF",X"B0",X"B0",
		X"B1",X"B1",X"B2",X"B2",X"B3",X"B3",X"B4",X"B5",X"B5",X"B6",X"B6",X"B7",
		X"B7",X"B8",X"B8",X"B9",X"B9",X"BA",X"BB",X"BB",X"BC",X"BC",X"BD",X"BD",
		X"BE",X"BE",X"BF",X"BF",X"C0",X"C0",X"C1",X"C1",X"C2",X"C2",X"C3",X"C3",
		X"C4",X"C4",X"C5",X"C5",X"C6",X"C6",X"C7",X"C7",X"C8",X"C8",X"C9",X"C9",
		X"CA",X"CA",X"CB",X"CB",X"CC",X"CC",X"CD",X"CD",X"CE",X"CE",X"CE",X"CF",
		X"CF",X"D0",X"D0",X"D1",X"D1",X"D2",X"D2",X"D2",X"D3",X"D3",X"D4",X"D4",
		X"D5",X"D5",X"D6",X"D6",X"D6",X"D7",X"D7",X"D8",X"D8",X"D8",X"D9",X"D9",
		X"DA",X"DA",X"DB",X"DB",X"DB",X"DC",X"DC",X"DD",X"DD",X"DD",X"DE",X"DE",
		X"DE",X"DF",X"DF",X"E0",X"E0",X"E0",X"E1",X"E1",X"E1",X"E2",X"E2",X"E3",
		X"E3",X"E3",X"E4",X"E4",X"E4",X"E5",X"E5",X"E5",X"E6",X"E6",X"E6",X"E7",
		X"E7",X"E7",X"E8",X"E8",X"E8",X"E9",X"E9",X"E9",X"EA",X"EA",X"EA",X"EB",
		X"EB",X"EB",X"EB",X"EC",X"EC",X"EC",X"ED",X"ED",X"ED",X"ED",X"EE",X"EE",
		X"EE",X"EF",X"EF",X"EF",X"EF",X"F0",X"F0",X"F0",X"F0",X"F1",X"F1",X"F1",
		X"F2",X"F2",X"F2",X"F2",X"F2",X"F3",X"F3",X"F3",X"F3",X"F4",X"F4",X"F4",
		X"F4",X"F5",X"F5",X"F5",X"F5",X"F5",X"F6",X"F6",X"F6",X"F6",X"F6",X"F7",
		X"F7",X"F7",X"F7",X"F7",X"F8",X"F8",X"F8",X"F8",X"F8",X"F9",X"F9",X"F9",
		X"F9",X"F9",X"F9",X"FA",X"FA",X"FA",X"FA",X"FA",X"FA",X"FA",X"FB",X"FB",
		X"FB",X"FB",X"FB",X"FB",X"FB",X"FC",X"FC",X"FC",X"FC",X"FC",X"FC",X"FC",
		X"FC",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",X"FD",
		X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",X"FE",
		X"FE",X"FE",X"FE",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",
		X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF",X"FF");
	signal addr1: unsigned(8 downto 0);
begin
	addr1 <= addr when rising_edge(clk);
	q <= rom1(to_integer(addr1));
end architecture;
