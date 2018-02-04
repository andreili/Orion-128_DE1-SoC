-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion is
	port (
		CLOCK_50		: in  std_logic;
		
		SW				: in std_logic_vector(9 downto 0);
		KEY			: in std_logic_vector(3 downto 0);
		
		LEDR			: out std_logic_vector(9 downto 0);
		
		--DRAM_ADDR	: out std_logic_vector(12 downto 0);
		--DRAM_BA		: out std_logic_vector(1 downto 0);
		--DRAM_CAS_N	: out std_logic;
		--DRAM_CKE		: out std_logic;
		--DRAM_CLK		: out std_logic;
		--DRAM_CS_N	: out std_logic;
		--DRAM_DQ		: inout std_logic_vector(15 downto 0);
		--DRAM_LDQM	: out std_logic;
		--DRAM_RAS_N	: out std_logic;
		--DRAM_UDQM	: out std_logic;
		--DRAM_WE_N	: out std_logic;
		
		--GPIO_0		: inout std_logic_vector(35 downto 0);
		--GPIO_1		: inout std_logic_vector(35 downto 0);
		
		PS2_CLK		: in  std_logic;
		PS2_DAT		: in  std_logic;
		
		HEX0			: out std_logic_vector(6 downto 0);
		HEX1			: out std_logic_vector(6 downto 0);
		HEX2			: out std_logic_vector(6 downto 0);
		HEX3			: out std_logic_vector(6 downto 0);
		HEX4			: out std_logic_vector(6 downto 0);
		HEX5			: out std_logic_vector(6 downto 0);
		
		VGA_R			: out std_logic_vector(7 downto 0);
		VGA_G			: out std_logic_vector(7 downto 0);
		VGA_B			: out std_logic_vector(7 downto 0);
		VGA_BLANK_N	: out std_logic;
		VGA_CLK		: out std_logic;
		VGA_HS		: out std_logic;
		VGA_SYNC_N	: out std_logic;
		VGA_VS		: out std_logic
	);
end entity;

architecture rtl of orion is

	component orion_pll is
		port (
			refclk   : in  std_logic := 'X'; -- clk
			rst      : in  std_logic := 'X'; -- reset
			outclk_0 : out std_logic;        -- clk 10MHz
			outclk_1 : out std_logic         -- clk 100MHz
		);
	end component orion_pll;

	component orion_video
		port (
			clk			: in  std_logic;	-- 25MHz

			addr			: in  std_logic_vector(15 downto 0);
			data			: inout std_logic_vector(7 downto 0);
			mem_we		: in  std_logic_vector( 3 downto 0);
			mem_cs		: in  std_logic_vector( 3 downto 0);
			rd				: in  std_logic;

			video_bank	: in  std_logic_vector(1 downto 0);
			video_mode	: in  std_logic_vector(2 downto 0);
			h480en		: in  std_logic;
			wide_scr_en	: in  std_logic;

			vframe_end	: out std_logic;

			VGA_R			: out std_logic_vector(7 downto 0);
			VGA_G			: out std_logic_vector(7 downto 0);
			VGA_B			: out std_logic_vector(7 downto 0);
			VGA_HS		: out std_logic;
			VGA_VS		: out std_logic;
			VGA_BLANK_N	: out std_logic;
			VGA_SYNC_N	: out std_logic
		);
	end component;

	component orion_cpu
		port (
			clk			: in  std_logic;	-- 25MHz

			addr			: out std_logic_vector(15 downto 0);
			data			: inout std_logic_vector(7 downto 0);
			mem_we		: out std_logic_vector(3 downto 0);
			mem_cs		: out std_logic_vector(3 downto 0);
			rd				: out std_logic;
			wr				: out std_logic;
			dsyn			: out std_logic;
			reset			: out std_logic;

			video_bank	: out std_logic_vector(1 downto 0);
			video_mode	: out std_logic_vector(2 downto 0);
			ports_cs		: out std_logic_vector(3 downto 0);

			reset_btn	: in  std_logic;
			ready			: in  std_logic;
			vframe_end	: in  std_logic
		);
	end component;

	component orion_pio
		port (
			clk			: in  std_logic;
			reset			: in  std_logic;
			addr			: in  std_logic_vector(15 downto 0);
			data			: inout std_logic_vector(7 downto 0);
			rd				: in  std_logic;
			wr				: in  std_logic;
			ports_cs		: in  std_logic_vector(3 downto 0);
			ps2_clk		: in  std_logic;
			ps2_data		: in  std_logic;
			reset_btn	: out std_logic
		);
	end component;

	component debounce
		generic (
			WIDTH : INTEGER := 14;
			POLARITY : STRING := "HIGH";
			TIMEOUT : INTEGER := 50000;
			TIMEOUT_WIDTH : INTEGER := 20
		);
		port
		(
			clk		:	in std_logic;
			reset_n	:	in std_logic;
			data_in	:	in std_logic_vector(WIDTH-1 downto 0);
			data_out	:	out std_logic_vector(WIDTH-1 downto 0)
		);
	end component;

--------------------------------------------------------------------------------
--                          ГЛОБАЛЬНЫЕ СИГНАЛЫ                                --
--------------------------------------------------------------------------------
signal clk_50MHz			: std_logic;	-- сигнал с генератора, только для PLL!!!
signal clk_10MHz			: std_logic;
signal clk_25MHz			: std_logic;

signal debounced			: std_logic_vector(13 downto 0);
signal KEY_debounced		: std_logic_vector(3 downto 0);
signal SW_debounced		: std_logic_vector(9 downto 0);

--------------------------------------------------------------------------------
--                         ВНЕШНИЕ СИГНАЛЫ ОРИОНА                             --
--------------------------------------------------------------------------------
signal or_reset_btn		: std_logic;
signal or_ready			: std_logic := '1';

--------------------------------------------------------------------------------
--                       ВНУТРЕННИЕ СИГНАЛЫ ОРИОНА                            --
--------------------------------------------------------------------------------

signal addr					: std_logic_vector(15 downto 0);
signal data					: std_logic_vector( 7 downto 0);
signal mem_cs				: std_logic_vector( 3 downto 0);
signal mem_we				: std_logic_vector( 3 downto 0);
signal rd					: std_logic;
signal wr					: std_logic;
signal dsyn					: std_logic;
signal reset				: std_logic;
signal video_bank			: std_logic_vector( 1 downto 0);
signal video_mode			: std_logic_vector( 2 downto 0);
signal vframe_end			: std_logic;
signal ports_cs			: std_logic_vector( 3 downto 0);

begin
--------------------------------------------------------------------------------
--                       СВЯЗЬ СИГНАЛОВ С ПИНАМИ МС                           --
--------------------------------------------------------------------------------
clk_50MHz <= CLOCK_50;
LEDR(0) <= '0';
LEDR(1) <= '0';
LEDR(2) <= '0';
LEDR(3) <= '0';
LEDR(4) <= '0';
LEDR(5) <= '0';
LEDR(6) <= '0';
LEDR(7) <= '0';
LEDR(8) <= '0';
LEDR(9) <= '0';
HEX0 <= (others => '1');
HEX1 <= (others => '1');
HEX2 <= (others => '1');
HEX3 <= (others => '1');
HEX4 <= (others => '1');
HEX5 <= (others => '1');

--------------------------------------------------------------------------------
--                      ПОДКЛЮЧЕНИЕ ВНЕШНИХ МОДУЛЕЙ                           --
--------------------------------------------------------------------------------
-- основной PLL
pll_orion: orion_pll
	port map (
		clk_50MHz,
		'0',
		clk_10MHz,
		clk_25MHz
	);

-- фильтр дребезга контактов
deb: debounce
	port map (
		clk_10MHz,
		'1',
		KEY & SW,
		debounced
	);
KEY_debounced <= debounced(13 downto 10);
SW_debounced  <= debounced(9 downto 0);

video: orion_video
	port map (
		clk_25MHz,
		addr,
		data,
		mem_we,
		mem_cs,
		rd,
		video_bank,
		video_mode,
		SW_debounced(9),
		SW_debounced(8),
		vframe_end,
		VGA_R,
		VGA_G,
		VGA_B,
		VGA_HS,
		VGA_VS,
		VGA_BLANK_N,
		VGA_SYNC_N
	);
VGA_CLK <= clk_50MHz;

cpu: orion_cpu
	port map (
		clk_25MHz,
		addr,
		data,
		mem_we,
		mem_cs,
		rd,
		wr,
		dsyn,
		reset,
		video_bank,
		video_mode,
		ports_cs,
		or_reset_btn or KEY_debounced(0),
		or_ready,
		vframe_end
	);

pio: orion_pio
	port map (
		clk_25MHz,
		not KEY_debounced(1),
		addr,
		data,
		rd,
		wr,
		ports_cs,
		PS2_CLK,
		PS2_DAT,
		or_reset_btn
	);

end rtl;
