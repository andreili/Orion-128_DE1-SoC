-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_mem is
	port (
		clk			: in  std_logic;
		addr			: in  std_logic_vector(15 downto 0);
		data			: inout std_logic_vector(7 downto 0);
		CSROM			: in  std_logic;
		cpu_rd		: in  std_logic;

		mem_cs_bank	: in  std_logic_vector(3 downto 0);
		mem_we_bank	: in  std_logic_vector(3 downto 0);

		dsyn_p		: in  std_logic;
		vram_addr	: in  std_logic_vector(15 downto 0);
		vram_data	: out std_logic_vector(15 downto 0)
	);
end entity;

architecture rtl of orion_mem is

signal rom_re				: std_logic;
signal rom_data			: std_logic_vector(7 downto 0);

	component rom_base
		port
		(
			address	: in  std_logic_vector(10 downto 0);
			clock		: in  std_logic;
			rden		: in  std_logic;
			q			: out std_logic_vector(7 downto 0)
		);
	end component;

begin

rom0: rom_base
	port map (
		addr(10 downto 0),
		clk,
		rom_re,
		rom_data
	);
rom_re <= CSROM and cpu_rd;
data <= rom_data when (rom_re = '1')
	else (others => 'Z');

end rtl;
