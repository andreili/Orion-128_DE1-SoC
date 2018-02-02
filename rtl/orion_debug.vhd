-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_debug is
	port (
		clk			: in  std_logic;
		reset_n		: in  std_logic;
		addr			: in  std_logic_vector(15 downto 0);
		data			: in  std_logic_vector(7 downto 0);

		/*step_en		: in  std_logic;
		step_btn		: in  std_logic;
		sync_in		: in  std_logic;
		sync_out		: out std_logic;
		ready			: out std_logic;*/

		HEX0			: out std_logic_vector(6 downto 0);
		HEX1			: out std_logic_vector(6 downto 0);
		HEX2			: out std_logic_vector(6 downto 0);
		HEX3			: out std_logic_vector(6 downto 0);
		HEX4			: out std_logic_vector(6 downto 0);
		HEX5			: out std_logic_vector(6 downto 0)
	);
end entity;

architecture rtl of orion_debug is

	component hex_led
		port (
			clk		: in	std_logic;
			reset_n	: in	std_logic;
			hex_code	: in	std_logic_vector(3 downto 0);
			hex_led	: out	std_logic_vector(6 downto 0)
		);
	end component;

begin

h0: hex_led
	port map (
		clk,
		reset_n,
		addr(3 downto 0),
		HEX0
	);

h1: hex_led
	port map (
		clk,
		reset_n,
		addr(7 downto 4),
		HEX1
	);

h2: hex_led
	port map (
		clk,
		reset_n,
		addr(11 downto 8),
		HEX2
	);

h3: hex_led
	port map (
		clk,
		reset_n,
		addr(15 downto 12),
		HEX3
	);

h4: hex_led
	port map (
		clk,
		reset_n,
		data(3 downto 0),
		HEX4
	);

h5: hex_led
	port map (
		clk,
		reset_n,
		data(7 downto 4),
		HEX5
	);

/*sync_out <= sync_in;
	process(step_en, sync_in, step_btn)
	begin
		if (step_en = '0') then
			ready <= '1';
		elsif (sync_in = '1') then
			ready <= '0';
		elsif (rising_edge(step_btn)) then
			ready <= '1';
		end if;
	end process;*/

end rtl;
