-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_cpu is
	port (
		clk			: in  std_logic;	-- 25MHz
		clk_F1		: in  std_logic;
		clk_F2		: in  std_logic;
		dsyn			: in  std_logic;

		addr			: out std_logic_vector(15 downto 0);
		data			: inout std_logic_vector(7 downto 0);
		mem_we		: out std_logic_vector(3 downto 0);
		mem_cs		: out std_logic_vector(3 downto 0);
		rd				: out std_logic;
		wr				: out std_logic;
		reset			: out std_logic;

		video_bank	: out std_logic_vector(1 downto 0);
		video_mode	: out std_logic_vector(2 downto 0);
		ports_cs		: out std_logic_vector(3 downto 0);

		reset_btn	: in  std_logic;
		ready			: in  std_logic;
		vframe_end	: in  std_logic
	);
end entity;

architecture rtl of orion_cpu is

	component vm80a
		port
		(
			pin_clk		: in  std_logic;
			pin_f1		: in  std_logic;
			pin_f2		: in  std_logic;
			pin_reset	: in  std_logic;
			pin_a			: out std_logic_vector(15 downto 0);
			pin_d			: inout std_logic_vector(7 downto 0);
			pin_hold		: in  std_logic;
			pin_hlda		: out std_logic;
			pin_ready	: in  std_logic;
			pin_wait		: out std_logic;
			pin_int		: in  std_logic;
			pin_inte		: out std_logic;
			pin_sync		: out std_logic;
			pin_dbin		: out std_logic;
			pin_wr_n		: out std_logic
		);
	end component;

	component orion_ports
		port (
			clk			: in  std_logic;
			clk_F1		: in  std_logic;
			clk_F2		: in  std_logic;
			dsyn			: in  std_logic;

			reset_btn	: in  std_logic;
			ready			: in  std_logic;
			cpu_sync		: in  std_logic;
			cpu_rd		: in  std_logic;
			cpu_wr		: in  std_logic;
			vframe_end	: in  std_logic;

			addr			: in  std_logic_vector(15 downto 0);
			data			: in  std_logic_vector(7 downto 0);

			reset			: out std_logic;
			CSROM			: out std_logic;
			cpu_ready	: out std_logic;

			mem_cs		: out std_logic_vector(3 downto 0);
			mem_we		: out std_logic_vector(3 downto 0);

			video_bank	: out std_logic_vector(1 downto 0);
			video_mode	: out std_logic_vector(2 downto 0);

			ports_cs		: out std_logic_vector(3 downto 0)
		);
	end component;

	component rom_base
		port
		(
			address	: in  std_logic_vector(10 downto 0);
			clock		: in  std_logic;
			rden		: in  std_logic;
			q			: out std_logic_vector(7 downto 0)
		);
	end component;

signal reset_inner		: std_logic;
signal cpu_addr			: std_logic_vector(15 downto 0);
signal cpu_ready			: std_logic;
signal cpu_int				: std_logic;
signal cpu_int_n			: std_logic;
signal cpu_inte			: std_logic;
signal cpu_inte_n			: std_logic;
signal cpu_sync			: std_logic;
signal cpu_sync_ex		: std_logic;
signal cpu_hlda			: std_logic := '0';
signal cpu_rd				: std_logic;
signal cpu_wr				: std_logic;
signal cpu_wr_n			: std_logic;

signal CSROM				: std_logic;

signal rom_re				: std_logic;
signal rom_data			: std_logic_vector(7 downto 0);

begin

wr <= cpu_wr;
rd <= cpu_rd;
addr<= cpu_addr;
reset <= reset_inner;

cpu_int <= not cpu_int_n;
cpu_inte_n <= not cpu_inte;
cpu_wr <= not cpu_wr_n;

cpu: vm80a
	port map (
		pin_clk		=> clk,
		pin_f1		=> clk_F1,
		pin_f2		=> clk_F2,
		pin_reset	=> reset_inner,
		pin_a			=> cpu_addr,
		pin_d			=> data,
		pin_hold		=> '0',
		pin_hlda		=> cpu_hlda,
		pin_ready	=> cpu_ready,
		pin_int		=> cpu_int,
		pin_inte		=> cpu_inte,
		pin_sync		=> cpu_sync,
		pin_dbin		=> cpu_rd,
		pin_wr_n		=> cpu_wr_n
	);

ports: orion_ports
	port map (
		clk,
		clk_F1,
		clk_F2,
		dsyn,
		reset_btn,
		ready,
		cpu_sync_ex,
		cpu_rd,
		cpu_wr,
		vframe_end,
		cpu_addr,
		data,
		reset_inner,
		CSROM,
		cpu_ready,
		mem_cs,
		mem_we,
		video_bank,
		video_mode,
		ports_cs
	);

rom0: rom_base
	port map (
		cpu_addr(10 downto 0),
		clk,
		rom_re,
		rom_data
	);
rom_re <= CSROM and cpu_rd;
data <= rom_data when (rom_re = '1')
	else (others => 'Z');

end rtl;
