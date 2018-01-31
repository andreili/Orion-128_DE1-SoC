-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity orion_pxl_conv is
	port 
	(
		pxl_green: in  std_logic;
		pxl_bg	: in  std_logic;
		pxl_back	: in  std_logic_vector(7 downto 0);
		mode		: in  std_logic_vector(2 downto 0);
		blank_n	: in  std_logic;

		R			: out std_logic;
		G			: out std_logic;
		B			: out std_logic;
		I			: out std_logic
	);
end entity;

architecture rtl of orion_pxl_conv is

signal pxl_sel				: std_logic_vector( 1 downto 0);
signal pxl_bg_ex			: std_logic;

signal Ri, Gi, Bi, Ii	: std_logic;

begin

pxl_sel <= (not mode(1)) & pxl_green;
pxl_bg_ex <= pxl_bg when (mode(2) = '1')
	else '0';

R <= Ri when (blank_n='1') else '0';
G <= Gi when (blank_n='1') else '0';
B <= Bi when (blank_n='1') else '0';
I <= Ii when (blank_n='1') else '0';

-- DD56.1
with pxl_sel select Bi <=
	pxl_back(4) when "00",
	pxl_back(0) when "01",
	mode(0) 		when "10",
	pxl_bg_ex	when "11";

-- DD56.2
with pxl_sel select Gi <=
	pxl_back(5) when "00",
	pxl_back(1) when "01",
	mode(0) 		when "10",
	(not pxl_bg_ex)when "11";

-- DD57.1
with pxl_sel select Ri <=
	pxl_back(6) when "00",
	pxl_back(2) when "01",
	pxl_bg_ex	when "10",
	mode( 0) 	when "11";

-- DD57.2
with pxl_sel select Ii <=
	pxl_back(7) when "00",
	pxl_back(3) when "01",
	'0'			when "10",
	'0'			when "11";

end rtl;
