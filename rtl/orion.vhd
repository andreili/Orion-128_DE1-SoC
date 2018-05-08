-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

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
		
		SMA			: out std_logic_vector(17 downto 0);
		SMD			: inout std_logic_vector(15 downto 0);
		SOE			: out std_logic;
		SUB			: out std_logic;
		SLB			: out std_logic;
		SCE			: out std_logic;
		SWE			: out std_logic;
		
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
			outclk_0 : out std_logic;        -- clk 50MHz
			outclk_1 : out std_logic;        -- clk 25MHz
			outclk_2 : out std_logic;        -- clk 20MHz
			outclk_3 : out std_logic         -- clk 300MHz
		);
	end component orion_pll;

	COMPONENT orion_video_sch
		PORT
		(
			clk			:	 IN STD_LOGIC;
			clk_mem		:	 IN STD_LOGIC;
			-- from CPU
			pFC			:	 IN STD_LOGIC;
			pFA			:	 IN STD_LOGIC;
			pF8			:	 IN STD_LOGIC;
			wrn			:	 IN STD_LOGIC;
			resetn		:	 IN STD_LOGIC;
			data			:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			-- from memory
			mem_data		:	 IN STD_LOGIC_VECTOR(15 downto 0);
			dsyn_n		:	 OUT STD_LOGIC;
			-- control singnals
			SR16			:	 IN STD_LOGIC;
			wide_en		:	 IN STD_LOGIC;
			-- video output
			R				:	 OUT std_logic_vector(7 downto 0);
			G				:	 OUT std_logic_vector(7 downto 0);
			B				:	 OUT std_logic_vector(7 downto 0);
			HS				:	 OUT STD_LOGIC;
			VS				:	 OUT STD_LOGIC;
			blank_n		:	 OUT STD_LOGIC;
			frame_end	:	 OUT STD_LOGIC;
			-- to memory
			video_addr	:	 OUT std_logic_vector(15 downto 0)
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
			MWEn			:	 OUT STD_LOGIC;
			MRDn			:	 OUT STD_LOGIC;
			zrdn			:	 OUT STD_LOGIC;
			zwrn			:	 OUT STD_LOGIC;
			mreqn			:	 OUT STD_LOGIC;
			dsyn_n		:	 OUT STD_LOGIC;
			reset			:	 OUT STD_LOGIC;
			PCSn			:	 OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
			MA				:	 OUT STD_LOGIC_VECTOR(19 DOWNTO 14);
			pFC			:	 OUT STD_LOGIC;
			SR16			:	 OUT STD_LOGIC;
			pFA			:	 OUT STD_LOGIC;
			pF8			:	 OUT STD_LOGIC;
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
			WIDTH : INTEGER := 4;
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
	
	component orion_memory
		port
		(
			clk			:	 IN STD_LOGIC;
			vaddr			:	 IN STD_LOGIC_VECTOR(15 DOWNTO 0);
			addr			:	 IN STD_LOGIC_VECTOR(13 DOWNTO 0);
			MA				:	 IN STD_LOGIC_VECTOR(19 DOWNTO 14);
			dsyn_n		:	 IN STD_LOGIC;
			MWEn			:	 IN STD_LOGIC;
			MRDn			:	 IN STD_LOGIC;

			data			:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0);
			vdata			:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);

			SA				:	 OUT STD_LOGIC_VECTOR(17 DOWNTO 0);
			SD				:	 INOUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			SOE			:	 OUT STD_LOGIC;
			SWE			:	 OUT STD_LOGIC;
			SUB			:	 OUT STD_LOGIC;
			SLB			:	 OUT STD_LOGIC;
			SCE			:	 OUT STD_LOGIC;
			m2v			:	 OUT STD_LOGIC
		);
	end component;
	
	component orion_memory_inn
		port
		(
			y			:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
			x			:	 IN STD_LOGIC_VECTOR(8 DOWNTO 3);
			vbank		:	 IN STD_LOGIC_VECTOR(1 DOWNTO 0);
			addr		:	 IN STD_LOGIC_VECTOR(13 DOWNTO 0);
			MA			:	 IN STD_LOGIC_VECTOR(19 DOWNTO 14);
			dsyn_n	:	 IN STD_LOGIC;
			MWEn		:	 IN STD_LOGIC;
			MRDn		:	 IN STD_LOGIC;
			clk_mem	:	 IN STD_LOGIC;
			vdata		:	 OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
			data		:	 INOUT STD_LOGIC_VECTOR(7 DOWNTO 0)
		);
	end component;

--------------------------------------------------------------------------------
--                          ГЛОБАЛЬНЫЕ СИГНАЛЫ                                --
--------------------------------------------------------------------------------
signal clk_50MHz			: std_logic;	-- сигнал с генератора, только для PLL!!!
signal clk_100MHz			: std_logic;
signal clk_25MHz			: std_logic;
signal clk_20MHz			: std_logic;
signal clk_300MHz			: std_logic;

signal debounced			: std_logic_vector(3 downto 0);
signal KEY_debounced		: std_logic_vector(3 downto 0);

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
signal mem_cs				: std_logic;
signal mem_we				: std_logic;
signal rdn					: std_logic;
signal wrn					: std_logic;
signal mreqn				: std_logic;
signal dsyn_n				: std_logic;
signal dsynv_n				: std_logic;
signal reset				: std_logic;
signal vframe_end			: std_logic;
signal ports_cs			: std_logic_vector( 3 downto 0);
signal MA					: std_logic_vector( 5 downto 0);
signal pFC					: std_logic;
signal pFA					: std_logic;
signal pF8					: std_logic;
signal SR16					: std_logic;
signal debd					: std_logic_vector(15 downto 0);

signal vaddr				: std_logic_vector(15 downto 0);
signal vdata				: std_logic_vector(15 downto 0);
signal m2v					: std_logic;

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
		clk_20MHz,
		clk_300MHz
	);

-- фильтр дребезга контактов
deb: debounce
	port map (
		clk_100MHz,
		'1',
		KEY,
		debounced
	);
KEY_debounced <= debounced(3 downto 0);

video: orion_video_sch
	port map (
		clk		=> clk_25MHz,
		clk_mem	=>	clk_300MHz,
		pFC		=> pFC,
		pFA		=> pFA,
		pF8		=> pF8,
		wrn		=> wrn,
		resetn	=> not reset,
		data		=> data,
		mem_data	=> vdata,
		SR16		=> SW(8),
		wide_en	=> SW(9),
		R			=> VGA_R,
		G			=> VGA_G,
		B			=> VGA_B,
		HS			=> VGA_HS,
		VS			=> VGA_VS,
		--blank_n	=> VGA_BLANK_N,
		frame_end=> vframe_end,
		video_addr=>vaddr,
		dsyn_n	=> dsynv_n
	);
VGA_CLK <= clk_100MHz;
VGA_SYNC_N <= '0';
VGA_BLANK_N <= '1';

mem: orion_memory
	port map (
		vaddr		=> vaddr,
		addr		=> addr(13 downto 0),
		MA			=> MA,
		dsyn_n	=> dsynv_n,
		MWEn		=> mem_we,
		MRDn		=> mem_cs,
		clk		=> clk_100MHz,
		data		=> data,
		vdata		=> vdata,
		m2v		=> m2v,
		SA			=> SMA,
		SD			=> SMD,
		SOE		=> SOE,
		SWE		=> SWE,
		SUB		=> SUB,
		SLB		=> SLB,
		SCE		=> SCE
	);

cpu: orion_pro_cpu_sch
	port map (
		--SW_debounced(1 downto 0),
		"11", -- forse 10MHz
		clk_25MHz,
		clk_300MHz,
		or_reset_btn or KEY_debounced(0),
		vframe_end,
		--"11111000",
		SW(7 downto 0),
		--"11" & SW_debounced(7 downto 2),
		addr,
		mem_we,
		mem_cs,
		rdn,
		wrn,
		mreqn,
		dsyn_n,
		reset,
		ports_cs,
		MA,
		pFC,
		SR16,
		pFA,
		pF8,
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
