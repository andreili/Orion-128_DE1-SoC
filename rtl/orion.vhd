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
		
		GPIO_0		: inout std_logic_vector(35 downto 0);
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
			outclk_0 : out std_logic;        -- clk 100MHz
			outclk_1 : out std_logic;        -- clk 25MHz
			outclk_2 : out std_logic         -- clk 20MHz
		);
	end component orion_pll;

	COMPONENT orion_video_sch
		PORT
		(
			clk			:	 IN STD_LOGIC;
			clk_mem		:	 IN STD_LOGIC;
			addr			:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			MWEn			:	 IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			MRDn			:	 IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			rdn			:	 IN STD_LOGIC;
			wrn			:	 IN STD_LOGIC;
			mreqn			:	 IN STD_LOGIC;
			vbank			:	 IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			video_mode	:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			SR16			:	 IN STD_LOGIC;
			wide_en		:	 IN STD_LOGIC;
			dsyn_n		:	 IN STD_LOGIC;
			mem_to_video:	 IN STD_LOGIC;
			MA				:	 IN STD_LOGIC_VECTOR(19 DOWNTO 14);
			pFC			:	 IN STD_LOGIC;
			R				:	 OUT std_logic_vector(7 downto 0);
			G				:	 OUT std_logic_vector(7 downto 0);
			B				:	 OUT std_logic_vector(7 downto 0);
			HS				:	 OUT STD_LOGIC;
			VS				:	 OUT STD_LOGIC;
			blank_n		:	 OUT STD_LOGIC;
			frame_end	:	 OUT STD_LOGIC;
			data			:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT orion_cpu_sch
		PORT
		(
			clk_div		:	 IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			clk			:	 IN STD_LOGIC;
			clk_core		:	 IN STD_LOGIC;
			reset_btn	:	 IN STD_LOGIC;
			frame_end	:	 IN STD_LOGIC;
			addr			:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			MWEn			:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			MRDn			:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			zrdn			:	 OUT STD_LOGIC;
			zwrn			:	 OUT STD_LOGIC;
			mreqn			:	 OUT STD_LOGIC;
			vbank			:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			v_mode		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			dsyn			:	 OUT STD_LOGIC;
			reset			:	 OUT STD_LOGIC;
			PCSn			:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			mem_to_video:	 OUT STD_LOGIC;
			data			:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;

	COMPONENT orion_pro_cpu_sch
		PORT
		(
			clk_div		:	 IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			clk			:	 IN STD_LOGIC;
			clk_core		:	 IN STD_LOGIC;
			reset_btn	:	 IN STD_LOGIC;
			frame_end	:	 IN STD_LOGIC;
			config		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			addr			:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			MWEn			:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			MRDn			:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			zrdn			:	 OUT STD_LOGIC;
			zwrn			:	 OUT STD_LOGIC;
			mreqn			:	 OUT STD_LOGIC;
			vbank			:	 OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
			v_mode		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			dsyn_n		:	 OUT STD_LOGIC;
			reset			:	 OUT STD_LOGIC;
			PCSn			:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			mem_to_video:	 OUT STD_LOGIC;
			MA				:	 OUT STD_LOGIC_VECTOR(19 DOWNTO 14);
			pFC			:	 OUT STD_LOGIC;
			SR16			:	 OUT STD_LOGIC;
			data			:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	END COMPONENT;

	component orion_pio
		port (
			clk			: in  std_logic;
			reset			: in  std_logic;
			addr			: in  std_logic_vector(15 downto 0);
			data			: inout std_logic_vector(7 downto 0);
			rdn			: in  std_logic;
			wrn			: in  std_logic;
			ports_cs		: in  std_logic_vector(3 downto 0);
			ps2_clk		: in  std_logic;
			ps2_data		: in  std_logic;
			reset_btn	: out std_logic;
			deb			: out std_logic_vector(15 downto 0)
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
	
	component orion_debug
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
	end component;

--------------------------------------------------------------------------------
--                          ГЛОБАЛЬНЫЕ СИГНАЛЫ                                --
--------------------------------------------------------------------------------
signal clk_50MHz			: std_logic;	-- сигнал с генератора, только для PLL!!!
signal clk_100MHz			: std_logic;
signal clk_25MHz			: std_logic;
signal clk_20MHz			: std_logic;

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

signal cas					: std_logic;
signal addr					: std_logic_vector(15 downto 0);
signal data					: std_logic_vector( 7 downto 0);
signal mem_cs				: std_logic_vector( 1 downto 0);
signal mem_we				: std_logic_vector( 1 downto 0);
signal rdn					: std_logic;
signal wrn					: std_logic;
signal mreqn				: std_logic;
signal dsyn_n				: std_logic;
signal reset				: std_logic;
signal video_bank			: std_logic_vector( 1 downto 0);
signal video_mode			: std_logic_vector( 7 downto 0);
signal vframe_end			: std_logic;
signal mem_to_video		: std_logic;
signal ports_cs			: std_logic_vector( 3 downto 0);
signal MA					: std_logic_vector( 5 downto 0);
signal pFC					: std_logic;
signal SR16					: std_logic;
signal debd					: std_logic_vector(15 downto 0);

begin
--------------------------------------------------------------------------------
--                       СВЯЗЬ СИГНАЛОВ С ПИНАМИ МС                           --
--------------------------------------------------------------------------------
clk_50MHz <= CLOCK_50;
LEDR(0) <= data(0);
LEDR(1) <= data(1);
LEDR(2) <= data(2);
LEDR(3) <= data(3);
LEDR(4) <= data(4);
LEDR(5) <= data(5);
LEDR(6) <= data(6);
LEDR(7) <= data(7);
LEDR(8) <= '0';
LEDR(9) <= '0';
/*HEX0 <= (others => '1');
HEX1 <= (others => '1');
HEX2 <= (others => '1');
HEX3 <= (others => '1');
HEX4 <= (others => '1');
HEX5 <= (others => '1');*/

--------------------------------------------------------------------------------
--                      ПОДКЛЮЧЕНИЕ ВНЕШНИХ МОДУЛЕЙ                           --
--------------------------------------------------------------------------------
-- основной PLL
pll_orion: orion_pll
	port map (
		clk_50MHz,
		'0',
		clk_100MHz,
		clk_25MHz,
		clk_20MHz
	);

-- фильтр дребезга контактов
deb: debounce
	port map (
		clk_100MHz,
		'1',
		KEY & SW,
		debounced
	);
KEY_debounced <= debounced(13 downto 10);
SW_debounced  <= debounced(9 downto 0);

video: orion_video_sch
	port map (
		clk		=> clk_25MHz,
		clk_mem	=>	clk_100MHz,
		addr		=> addr,
		MWEn		=> mem_we,
		MRDn		=> mem_cs,
		rdn		=> rdn,
		wrn		=> wrn,
		mreqn		=> mreqn,
		vbank		=> video_bank,
		video_mode=> video_mode,
		SR16		=> SW_debounced(8),
		wide_en	=> SW_debounced(9),
		dsyn_n	=> dsyn_n,
		mem_to_video=> mem_to_video,
		data		=> data,
		R			=> VGA_R,
		G			=> VGA_G,
		B			=> VGA_B,
		HS			=> VGA_HS,
		VS			=> VGA_VS,
		--blank_n	=> VGA_BLANK_N,
		frame_end=> vframe_end,
		MA			=> MA,
		pFC		=> pFC
	);
VGA_CLK <= clk_100MHz;
VGA_SYNC_N <= '0';
VGA_BLANK_N <= '1';

cpu: orion_pro_cpu_sch
	port map (
		--SW_debounced(1 downto 0),
		"11", -- forse 10MHz
		clk_20MHz,
		clk_100MHz,
		or_reset_btn or KEY_debounced(0),
		vframe_end,
		--"11111000",
		SW_debounced(7 downto 0),
		--"11" & SW_debounced(7 downto 2),
		addr,
		mem_we,
		mem_cs,
		rdn,
		wrn,
		mreqn,
		video_bank,
		video_mode,
		dsyn_n,
		reset,
		ports_cs,
		mem_to_video,
		MA,
		pFC,
		SR16,
		data
	);

pio: orion_pio
	port map (
		clk_100MHz,
		reset,
		addr,
		data,
		rdn,
		wrn,
		ports_cs,
		PS2_CLK,
		PS2_DAT,
		or_reset_btn,
		debd
	);

debug: orion_debug
	port map (
		clk_20MHz,
		KEY_debounced(2),
		debd,
		8D"0",
		HEX0,
		HEX1,
		HEX2,
		HEX3,
		HEX4,
		HEX5
	);

end rtl;
