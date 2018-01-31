-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_ports is
	port (
		clk			: in  std_logic;
		clk_F2		: in  std_logic;

		reset_btn	: in  std_logic;
		ready			: in  std_logic;
		cpu_sync		: in  std_logic;
		cpu_rd		: in  std_logic;
		cpu_wr		: in  std_logic;
		vframe_end	: in  std_logic;

		addr			: in  std_logic_vector(15 downto 0);
		data			: in  std_logic_vector(7 downto 0);

		reset			: out std_logic;
		dsyn			: out std_logic;
		CSROM			: out std_logic;
		cpu_ready	: out std_logic;

		mem_cs		: out std_logic_vector(3 downto 0);
		mem_we		: out std_logic_vector(3 downto 0);

		video_bank	: out std_logic_vector(1 downto 0);
		video_mode	: out std_logic_vector(2 downto 0);

		ports_cs		: out std_logic_vector(3 downto 0)
	);
end entity;

architecture rtl of orion_ports is

signal color_mode			: std_logic_vector(3 downto 0);	-- управление цветом

signal dsyn_tmp			: std_logic;

signal sel_port_F4XX		: std_logic;
signal sel_port_F8XX		: std_logic;
signal sel_port_F800		: std_logic;
signal sel_port_F900		: std_logic;
signal sel_port_FA00		: std_logic;
signal sel_port_FB00		: std_logic;

signal addr_FXXX			: std_logic;
signal addr_F4XX			: std_logic;
signal addr_F8XX			: std_logic;

signal addr_hi				: std_logic_vector(1 downto 0) := (others => '0');

signal mem_addr_hi		: std_logic_vector(1 downto 0);
signal we_bank				: std_logic;
signal cs_bank				: std_logic;

signal vram_bank_idx_tmp: std_logic_vector( 1 downto 0) := "11"; -- номер банка памяти

begin

video_mode <= color_mode(2 downto 0);

--------------------------------------------------------------------------------
--                            ОБРАБОТКА ПОРТОВ                                --
--------------------------------------------------------------------------------

addr_FXXX <= addr(12) and addr(13) and addr(14) and addr(15);
addr_F4XX <= addr_FXXX and addr(10);
addr_F8XX <= addr_FXXX and addr(11);
CSROM <= addr_F8XX or (not color_mode(3));

	-- DD18.1 - переключение страниц памяти
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (sel_port_F900 = '1') then
				addr_hi(0) <= data(0);
				addr_hi(1) <= data(1);
			end if;
		end if;
	end process;

	-- DD18.2
	process (clk)
	begin
		if (falling_edge(clk)) then
			if (clk_F2 = '1') then
				reset <= not reset_btn;
				cpu_ready <= ready;
			end if;
		end if;
	end process;

	-- DD13.2
dsyn <= cpu_rd or cpu_wr;
	process (clk)
	begin
		if (falling_edge(clk)) then
			--dsyn_p <= cpu_rd or cpu_wr;
			---dsyn_tmp <= cpu_sync;
			---dsyn_p <= dsyn_tmp;
			--dsyn_p <= cpu_sync;
		end if;
	end process;

	-- DD29 - управление банками памяти
mem_addr_hi(0) <= (not addr_hi(0)) or addr_FXXX;
mem_addr_hi(1) <= (not addr_hi(1)) or addr_FXXX;
cs_bank <= (cpu_wr or cpu_rd) and (not CSROM) and (not addr_F4XX);
	mem_cs(3) <= '1' when ((mem_addr_hi = "00") and (cs_bank = '1'))
					else '0';
	mem_cs(2) <= '1' when ((mem_addr_hi = "01") and (cs_bank = '1'))
					else '0';
	mem_cs(1) <= '1' when ((mem_addr_hi = "10") and (cs_bank = '1'))
					else '0';
	mem_cs(0) <= '1' when ((mem_addr_hi = "11") and (cs_bank = '1'))
					else '0';
we_bank <= dsyn and cpu_wr;
	mem_we(3) <= '1' when ((mem_addr_hi = "00") and (we_bank = '1'))
					else '0';
	mem_we(2) <= '1' when ((mem_addr_hi = "01") and (we_bank = '1'))
					else '0';
	mem_we(1) <= '1' when ((mem_addr_hi = "10") and (we_bank = '1'))
					else '0';
	mem_we(0) <= '1' when ((mem_addr_hi = "11") and (we_bank = '1'))
					else '0';

-- DD27 - дешифратор портов
sel_port_F4XX <= addr_F4XX and (not CSROM);
	ports_cs(0) <= '1' when ((sel_port_F4XX = '1') and (addr(9 downto 8) = "00"))
				 else '0';
	ports_cs(1) <= '1' when ((sel_port_F4XX = '1') and (addr(9 downto 8) = "01"))
				 else '0';
	ports_cs(2) <= '1' when ((sel_port_F4XX = '1') and (addr(9 downto 8) = "10"))
				 else '0';
	ports_cs(3) <= '1' when ((sel_port_F4XX = '1') and (addr(9 downto 8) = "11"))
				 else '0';
sel_port_F8XX <= mem_we(0) and CSROM;
	sel_port_F800 <= '1' when ((sel_port_F8XX = '1') and (addr(9 downto 8) = "00"))
					else '0';
	sel_port_F900 <= '1' when ((sel_port_F8XX = '1') and (addr(9 downto 8) = "01"))
					else '0';
	sel_port_FA00 <= '1' when ((sel_port_F8XX = '1') and (addr(9 downto 8) = "10"))
					else '0';
	sel_port_FB00 <= '1' when ((sel_port_F8XX = '1') and (addr(9 downto 8) = "11"))
					else '0';

	-- DD28 - переключение экранных областей
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (sel_port_FA00 = '1') then
				vram_bank_idx_tmp(1) <= not data(1);
				vram_bank_idx_tmp(0) <= not data(0);
			end if;
			
			--if (vframe_end = '1') then
				video_bank <= vram_bank_idx_tmp;
			--end if;
		end if;
	end process;

	-- DD30 - управление цветом
	process (reset, sel_port_F800)
	begin
		if (reset = '1') then
			color_mode <= "0000";
		elsif (rising_edge(sel_port_F800)) then
			color_mode <= '1' & data(2 downto 0);
		end if;
	end process;

end rtl;
