-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_video is
	port (
		clk			: in  std_logic;	-- 25MHz
		clk_mem		: in  std_logic;

		addr			: in  std_logic_vector(15 downto 0);
		data			: inout std_logic_vector(7 downto 0);
		mem_we		: in  std_logic_vector( 3 downto 0);
		mem_cs		: in  std_logic_vector( 3 downto 0);
		rd				: in  std_logic;

		video_bank	: in  std_logic_vector(1 downto 0);
		video_mode	: in  std_logic_vector(2 downto 0);
		h480en		: in  std_logic;

		vframe_end	: out std_logic;

		VGA_R			: out std_logic_vector(7 downto 0);
		VGA_G			: out std_logic_vector(7 downto 0);
		VGA_B			: out std_logic_vector(7 downto 0);
		VGA_HS		: out std_logic;
		VGA_VS		: out std_logic;
		VGA_BLANK_N	: out std_logic;
		VGA_SYNC_N	: out std_logic
	);
end entity;

architecture rtl of orion_video is

signal R						: std_logic;
signal G						: std_logic;
signal B						: std_logic;
signal I						: std_logic;

	-- модуль преобразования данных в RGBI
	component orion_vconv
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
	end component;
	component orion_pxl_conv
		port 
		(
			pxl_green: in  std_logic;
			pxl_bg	: in  std_logic;
			pxl_back	: in  std_logic_vector(7 downto 0);
			mode		: in  std_logic_vector(2 downto 0);
			blank_n	: in  std_logic;

			R			: out std_logic;
			G			: out std_logic;
			B			: out std_logic;
			I			: out std_logic
		);
	end component;
	
	component ram_dualp
		port
		(
			address_a	: in  std_logic_vector(15 downto 0);
			address_b	: in  std_logic_vector(15 downto 0);
			clock_a		: in  std_logic;
			clock_b		: in  std_logic;
			data_a		: in  std_logic_vector(7 downto 0);
			data_b		: in  std_logic_vector(7 downto 0);
			rden_a		: in  std_logic;
			rden_b		: in  std_logic;
			wren_a		: in  std_logic;
			wren_b		: in  std_logic;
			q_a			: out std_logic_vector(7 downto 0);
			q_b			: out std_logic_vector(7 downto 0)
		);
	end component;

	component ram_base
		port
		(
			address	: in  std_logic_vector(15 downto 0);
			clock		: in  std_logic;
			data		: in  std_logic_vector(7 downto 0);
			wren		: in  std_logic;
			q			: out std_logic_vector(7 downto 0)
		);
	end component;

signal h_cnt				: std_logic_vector(9 downto 0);
signal v_cnt				: std_logic_vector(9 downto 0);
signal h_blank				: std_logic;
signal v_blank				: std_logic;
signal h_sync				: std_logic;
signal v_sync				: std_logic;

signal vram_col			: std_logic_vector( 8 downto 0);
signal vram_row			: std_logic_vector( 7 downto 0);
signal vaddr				: std_logic_vector(15 downto 0);
signal vdata				: std_logic_vector(15 downto 0);
signal vdata1				: std_logic_vector(15 downto 0);

signal wdata0				: std_logic_vector(7 downto 0);
signal wdata1				: std_logic_vector(7 downto 0);
signal wdata2				: std_logic_vector(7 downto 0);
signal wdata3				: std_logic_vector(7 downto 0);
signal mem_data0			: std_logic_vector(7 downto 0);
signal mem_data1			: std_logic_vector(7 downto 0);
signal mem_data2			: std_logic_vector(7 downto 0);
signal mem_data3			: std_logic_vector(7 downto 0);

signal vga_end_8pxls		: std_logic;
signal blank_n				: std_logic;
signal pxl_data			: std_logic_vector(31 downto 0);

begin

--------------------------------------------------------------------------------
--                       СЧЁТЧИКИ ПИКСЕЛЕЙ И СТРОК                            --
--------------------------------------------------------------------------------

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (h_cnt = 10D"799") then
				h_cnt <= (others => '0');
			else
				h_cnt <= h_cnt + '1';
			end if;
		end if;
	end process;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (((h_cnt = 10D"671") and (h480en = '0')) or ((h_cnt = 10D"719") and (h480en = '1'))) then
				if (v_cnt = 10D"448") then
					v_cnt <= (others => '0');
				else
					v_cnt <= v_cnt + 1;
				end if;
			end if;
		end if;
	end process;

--------------------------------------------------------------------------------
--                        ФОРМИРОВАНИЕ СИНХРО-СИГНАЛОВ                        --
--------------------------------------------------------------------------------

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (h480en = '0') then
				if (h_cnt = 10D"527") then
					h_sync <= '1';
				elsif (h_cnt = 10D"623") then
					h_sync <= '0';
				end if;
			else
				if (h_cnt = 10D"575") then
					h_sync <= '1';
				elsif (h_cnt = 10D"671") then
					h_sync <= '0';
				end if;
			end if;

			if (v_cnt = 10D"339") then
				v_sync <= '0';
			elsif (h_cnt = 10D"341") then
				v_sync <= '1';
			end if;
		end if;
	end process;

VGA_HS <= h_sync;
VGA_VS <= v_sync;
VGA_SYNC_N <= '0';

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (h_cnt = 10D"0") then
				h_blank <= '0';
			elsif (((h_cnt = 10D"384") and (h480en = '0')) or ((h_cnt = 10D"480") and (h480en = '1'))) then
				h_blank <= '1';
			end if;

			if (v_cnt = 10D"0") then
				v_blank <= '0';
			elsif (v_cnt = 10D"255") then
				v_blank <= '1';
			end if;
		end if;
	end process;

blank_n <= not (h_blank or v_blank);
VGA_BLANK_N <= blank_n;
--VGA_BLANK_N <= '1';

--------------------------------------------------------------------------------
--                         ФОРМИРОВАНИЕ АДРЕСА ПИКСЕЛЯ                        --
--------------------------------------------------------------------------------

	process (clk)
	begin
		if (rising_edge(clk)) then
			--if (h_blank = '0') then
				vram_col <= h_cnt(8 downto 0);
			--else
			--	vram_col <= (others => '0');
			--end if;
		end if;
	end process;

	process (clk)
	begin
		if (rising_edge(clk)) then
			--if (v_blank = '0') then
				vram_row <= v_cnt(7 downto 0);
			--else
			--	vram_row <= (others => '0');
			--end if;
		end if;
	end process;

vaddr <= video_bank & vram_col(8 downto 3) & vram_row;

--------------------------------------------------------------------------------
--                       ПРЕОБРАЗОВАНИЕ ТЕКУЩЕГО ПИКСЕЛЯ                      --
--------------------------------------------------------------------------------

vga_end_8pxls <= (not vram_col(2)) and (not vram_col(1)) and (not vram_col(0));
/*
pxl: orion_vconv
	port map (
		clk,
		vdata,
		video_mode,
		vga_end_8pxls,
		R,
		G,
		B,
		I
	);*/

	/*process (clk, vga_end_8pxls)
	begin
		if (rising_edge(clk) and (vga_end_8pxls = '1')) then
			if (h_blank = '1') then
				vdata1 <= (others => '0');
			else
				vdata1(7 downto 0) <= vdata(7 downto 0);
				if (video_mode(1) = '1') then
					vdata1(15 downto 8) <= vdata(15 downto 8);
				else
					vdata1(15 downto 8) <= 8D"0";
				end if;
			end if;
		end if;
	end process;*/

--------------------------------------------------------------------------------
--                        ВЫВОД ДАННЫХ НА VGA-ВЫХОД                           --
--------------------------------------------------------------------------------
VGA_R(0) <= R;
VGA_R(1) <= R;
VGA_R(2) <= R;
VGA_R(3) <= R;
VGA_R(4) <= R;
VGA_R(5) <= R;
VGA_R(6) <= R;
VGA_R(7)	<= I;

VGA_G(0) <= G;
VGA_G(1) <= G;
VGA_G(2) <= G;
VGA_G(3) <= G;
VGA_G(4) <= G;
VGA_G(5) <= G;
VGA_G(6) <= G;
VGA_G(7)	<= I;

VGA_B(0) <= B;
VGA_B(1) <= B;
VGA_B(2) <= B;
VGA_B(3) <= B;
VGA_B(4) <= B;
VGA_B(5) <= B;
VGA_B(6) <= B;
VGA_B(7)	<= I;

with (vram_col(2 downto 0)) select R <=
	pxl_data(28) when "000",
	pxl_data(24) when "001",
	pxl_data(20) when "010",
	pxl_data(16) when "011",
	pxl_data(12) when "100",
	pxl_data( 8) when "101",
	pxl_data( 4) when "110",
	pxl_data( 0) when "111";

with (vram_col(2 downto 0)) select G <=
	pxl_data(29) when "000",
	pxl_data(25) when "001",
	pxl_data(21) when "010",
	pxl_data(17) when "011",
	pxl_data(13) when "100",
	pxl_data( 9) when "101",
	pxl_data( 5) when "110",
	pxl_data( 1) when "111";

with (vram_col(2 downto 0)) select B <=
	pxl_data(30) when "000",
	pxl_data(26) when "001",
	pxl_data(22) when "010",
	pxl_data(18) when "011",
	pxl_data(14) when "100",
	pxl_data(10) when "101",
	pxl_data( 6) when "110",
	pxl_data( 2) when "111";

with (vram_col(2 downto 0)) select I <=
	pxl_data(31) when "000",
	pxl_data(27) when "001",
	pxl_data(23) when "010",
	pxl_data(19) when "011",
	pxl_data(15) when "100",
	pxl_data(11) when "101",
	pxl_data( 7) when "110",
	pxl_data( 3) when "111";

pxl_7: orion_pxl_conv
	port map (
		vdata(0),
		vdata(8),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data( 0),
		pxl_data( 1),
		pxl_data( 2),
		pxl_data( 3)
	);

pxl_6: orion_pxl_conv
	port map (
		vdata(1),
		vdata(9),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data( 4),
		pxl_data( 5),
		pxl_data( 6),
		pxl_data( 7)
	);

pxl_5: orion_pxl_conv
	port map (
		vdata(2),
		vdata(10),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data( 8),
		pxl_data( 9),
		pxl_data(10),
		pxl_data(11)
	);

pxl_4: orion_pxl_conv
	port map (
		vdata(3),
		vdata(11),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data(12),
		pxl_data(13),
		pxl_data(14),
		pxl_data(15)
	);

pxl_3: orion_pxl_conv
	port map (
		vdata(4),
		vdata(12),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data(16),
		pxl_data(17),
		pxl_data(18),
		pxl_data(19)
	);

pxl_2: orion_pxl_conv
	port map (
		vdata(5),
		vdata(13),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data(20),
		pxl_data(21),
		pxl_data(22),
		pxl_data(23)
	);

pxl_1: orion_pxl_conv
	port map (
		vdata(6),
		vdata(14),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data(24),
		pxl_data(25),
		pxl_data(26),
		pxl_data(27)
	);

pxl_0: orion_pxl_conv
	port map (
		vdata(7),
		vdata(15),
		vdata(15 downto 8),
		video_mode,
		blank_n,
		pxl_data(28),
		pxl_data(29),
		pxl_data(30),
		pxl_data(31)
	);

-- port A - CPU
-- port B - GPU
ram0: ram_dualp
	port map
	(
		addr,
		vaddr,
		clk,
		clk_mem,
		wdata0,
		8D"0",	-- video - RO
		'1',		-- RE
		'1',		-- RE
		mem_we(0),
		'0',		-- video - RO
		mem_data0,
		vdata(7 downto 0)
	);

-- port A - CPU
-- port B - GPU
ram1: ram_dualp
	port map
	(
		addr,
		vaddr,
		clk,
		clk_mem,
		wdata1,
		8D"0",	-- video - RO
		'1',		-- RE
		'1',		-- RE
		mem_we(1),
		'0',		-- video - RO
		mem_data1,
		vdata(15 downto 8)
	);

ram2: ram_base
	port map
	(
		addr,
		clk,
		wdata2,
		mem_we(2),
		mem_data2
	);

ram3: ram_base
	port map
	(
		addr,
		clk,
		wdata3,
		mem_we(3),
		mem_data3
	);

wdata0 <= data;
wdata1 <= data;
wdata2 <= data;
wdata3 <= data;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (rd = '1') then
				if (mem_cs(0) = '1') then
					data <= mem_data0;
				elsif (mem_cs(1) = '1') then
					data <= mem_data1;
				elsif (mem_cs(2) = '1') then
					data <= mem_data2;
				elsif (mem_cs(3) = '1') then
					data <= mem_data3;
				else
					data <= (others => 'Z');
				end if;
			else
				data <= (others => 'Z');
			end if;
		end if;
	end process;

end rtl;
