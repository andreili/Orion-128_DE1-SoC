-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

entity orion_vconv is
	port 
	(
		clk		: in  std_logic;

		vin		: in  std_logic_vector(15 downto 0);
		mode		: in  std_logic_vector( 2 downto 0);
		sync		: in  std_logic;

		R			: out std_logic;
		G			: out std_logic;
		B			: out std_logic;
		I			: out std_logic
	);
end entity;

architecture rtl of orion_vconv is

signal pxl_G				: std_logic;
signal pxl_sel				: std_logic_vector( 1 downto 0);

signal buf1					: std_logic_vector(15 downto 0);

begin

pxl_G   <= buf1(7);
pxl_sel <= (not mode(1)) & pxl_G;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (sync = '1') then
				-- DD51
				buf1(7 downto 0) <= vin(7 downto 0);
				-- DD52
				if (mode(2) = '0') then
					buf1(15 downto 0) <= (others => '0');
				else
					buf1(15 downto 0) <= vin(15 downto 0);
				end if;
			else
				-- DD51
				buf1(7 downto 1) <= buf1(6 downto 0);
				-- DD52
				if (mode(1) = '0') then
					buf1(15 downto 9) <= buf1(14 downto 8);
				end if;
			end if;
		end if;
	end process;

-- DD56.1
with pxl_sel select B <=
	buf1(12) when "00",
	buf1( 8) when "01",
	mode( 0) when "10",
	buf1(15) when "11";

-- DD56.2
with pxl_sel select G <=
	buf1(13) when "00",
	buf1( 9) when "01",
	mode( 0) when "10",
	(not buf1(15)) when "11";

-- DD57.1
with pxl_sel select R <=
	buf1(14) when "00",
	buf1(10) when "01",
	buf1(15) when "10",
	mode( 0) when "11";

-- DD57.2
with pxl_sel select I <=
	buf1(15) when "00",
	buf1(11) when "01",
	'0'		when "10",
	'0'		when "11";

end rtl;
