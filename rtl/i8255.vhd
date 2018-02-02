-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity i8255 is
	port (
		clk	: in    std_logic;
		dbus	: inout std_logic_vector(7 downto 0);
		addr	: in    std_logic_vector(1 downto 0);
		rd_n	: in    std_logic;
		wr_n	: in    std_logic;
		cs_n	: in    std_logic;
		res	: in    std_logic;
		
		PA		: inout std_logic_vector(7 downto 0);
		PB		: inout std_logic_vector(7 downto 0);
		PC		: inout std_logic_vector(7 downto 0)
	);
end entity;

architecture rtl of i8255 is

signal control_reg	: std_logic_vector(6 downto 0);
--signal CR_mode_A		: std_logic_vector(1 downto 0);
signal CR_A_IO			: std_logic;
signal CR_Cup_IO		: std_logic;
--signal CR_mode_B		: std_logic;
signal CR_B_IO			: std_logic;
signal CR_Clo_IO		: std_logic;

signal PA_IN			: std_logic_vector(7 downto 0);
signal PB_IN			: std_logic_vector(7 downto 0);
signal PC_INlo			: std_logic_vector(3 downto 0);
signal PC_INhi			: std_logic_vector(3 downto 0);
signal PA_OUT			: std_logic_vector(7 downto 0);
signal PB_OUT			: std_logic_vector(7 downto 0);
signal PC_OUT			: std_logic_vector(7 downto 0);

begin

	process (res, wr_n)
	begin
		if (res) then
			control_reg <= "0011011";
		elsif (falling_edge(wr_n)) then
			if ((cs_n='0') and (addr="11") and (dbus(7)='1')) then
				control_reg <= dbus(6 downto 0);
			end if;
		end if;
	end process;

--CR_mode_A <= control_reg(6 downto 5);
CR_A_IO	 <= control_reg(4);	-- all IO's: 0 - output, 1 - input
CR_Cup_IO <= control_reg(3);
--CR_mode_B <= control_reg(2);
CR_B_IO	 <= control_reg(1);
CR_Clo_IO <= control_reg(0);

	process (clk, cs_n)
	begin
		if (rising_edge(clk) and (cs_n = '0')) then
			if (wr_n = '0') then
				case (addr) is
					when "00" =>	PA <= dbus;
					when "01" =>	PB <= dbus;
					when "10" =>	PC <= dbus;
					when "11" =>	NULL;
				end case;
			end if;
		end if;
	end process;

	process (clk, cs_n)
	begin
		if (rising_edge(clk) and (cs_n = '0')) then
			if (rd_n = '0') then
				case (addr) is
					when "00" =>	dbus <= PA;
					when "01" =>	dbus <= PB;
					when "10" =>	dbus <= PC;
					when "11" =>	NULL;
				end case;
			end if;
		end if;
	end process;

	-- PA
/*	process (clk)
	begin
		if (rising_edge(clk)) then
			if (CR_A_IO = '1') then
				PA <= (others => 'Z');
				PA_IN <= PA;
			else
				PA_IN <= (others => 'Z');
				PA <= PA_OUT;
			end if;
		end if;
	end process;

	-- PB
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (CR_B_IO = '1') then
				PB <= (others => 'Z');
				PB_IN <= PB;
			else
				--PB_IN <= (others => 'Z');
				--PB <= PB_OUT;
			end if;
		end if;
	end process;

	-- PClo
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (CR_Clo_IO = '1') then
				PC(3 downto 0) <= (others => 'Z');
				PC_INlo <= PC(3 downto 0);
			else
				--PC_INlo <= (others => 'Z');
				--PC(3 downto 0) <= PC_OUT(3 downto 0);
			end if;
		end if;
	end process;

	-- PCup
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (CR_Cup_IO = '1') then
				PC(7 downto 4) <= (others => 'Z');
				PC_INhi <= PC(7 downto 4);
			else
				PC_INhi <= (others => 'Z');
				PC(7 downto 4) <= PC_OUT(7 downto 4);
			end if;
		end if;
	end process;

	-- PX -> DBUS
	process (rd_n)
	begin
		if (falling_edge(rd_n)) then
			case addr is
				when "00" =>	dbus <= PA_IN;
				when "01" =>	dbus <= PB_IN;
				when "10" =>	dbus <= PC_INhi & PC_INlo;
				when "11" =>	dbus <= (others => 'Z');
			end case;
		end if;
	end process;

	-- DBUS -> PX
	process (wr_n)
	begin
		if (falling_edge(wr_n)) then
			case addr is
				when "00" =>	PA_OUT <= dbus;
				when "01" =>	PB_OUT <= dbus;
				when "10" =>	PC_OUT <= dbus;
				when "11" =>	NULL;
			end case;
		end if;
	end process;*/

end rtl;
