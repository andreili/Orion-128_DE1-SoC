library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity gal_x is
	port (
		x				:	 IN STD_LOGIC_VECTOR(9 DOWNTO 0);
		SR16			:	 IN STD_LOGIC;
		wide_en		:	 IN STD_LOGIC;

		xres_n		:	 OUT STD_LOGIC;
		BE				:	 OUT STD_LOGIC;
		BE_n			:	 OUT STD_LOGIC;
		BH				:	 OUT STD_LOGIC;
		xle			:	 OUT STD_LOGIC;
		HS3			:	 OUT STD_LOGIC;
		HS5			:	 OUT STD_LOGIC;
		HS				:	 OUT STD_LOGIC;
		col			:	 OUT std_logic_vector(1 downto 0)
	);
end entity;

architecture rtl of gal_x is

signal hs3s			: std_logic;
signal hs5s			: std_logic;

begin

xres_n <= not (x(9) and x(8) and x(4) and x(3) and x(2) and x(1) and x(0));
be <= x(2) and x(1) and x(0);
be_n <= not (x(2) and x(1) and x(0));
bh <= ((not sr16) and ((not x(9)) and (((not x(8)) and x(7))
					or ((not x(7)) and (x(6) or x(5) or x(4) or x(3)))
					or (x(8) and (not x(6)) and (not x(5)) and (not x(4)) and (not x(3)))
					 )
			  )
	 )
	or (sr16 and (((not x(9)) and (x(8) or x(7) or x(6) or x(5) or x(4) or x(3)))
			 or (x(9) and (not x(3)) and (not (x(8) or x(7) or x(6) or x(5) or x(4))))
			  )
	  );
xle <= (((not sr16) and (not x(6))) or (sr16 and x(6))) and (x(9) and (not x(8)) and x(7) and x(5) and (not x(4)) and (not x(3)) and x(2) and x(1) and x(0));
hs3s <= x(9) and (not x(8)) and (not x(7)) and ((x(6) and (not x(5))) or (x(5) and ((not x(3)) or (not x(4)))) or ((not x(6)) and x(4) and x(3)));
hs5s <= x(9) and (not x(8)) and (((not x(7)) and x(6) and ((x(4) and x(3)) or x(5))) or (x(7) and (not x(6)) and ((not x(5)) or (not x(4)) or (not x(3)))));
hs <= not (wide_en xor (((not sr16) and hs3s) or (sr16 and hs5s)));

col(0) <= not (x(2) and x(1));
col(1) <=  x(2) or (not x(1));


hs3 <= hs3s;
hs5 <= hs5s;

end rtl;
