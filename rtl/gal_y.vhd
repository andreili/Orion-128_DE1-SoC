library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity gal_y is
	port (
		y				:	 IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		wide_en		:	 IN STD_LOGIC;
		bh				:	 IN STD_LOGIC;

		yres_n		:	 OUT STD_LOGIC;
		BL_n			:	 OUT STD_LOGIC;
		VS				:	 OUT STD_LOGIC
	);
end entity;

architecture rtl of gal_y is

signal hs3s			: std_logic;
signal hs5s			: std_logic;

begin

yres_n <= not (((not wide_en) and y(9) and y(3) and y(2))
			   or (wide_en and y(8) and y(7) and y(6)));
BL_n <= bh and (not y(8)) and (not y(9));
VS <= not (((not y(9)) and y(8) and (not y(7)) and y(6) and y(4))
	and (((not wide_en) and ( y(5) and  y(3) and (not y(2)) and  y(1)))
	   or (wide_en and ((not y(5)) and (not y(3)) and  y(2) and (y(1) xor y(0))))));

end rtl;
