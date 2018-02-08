-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_video is
	port (
		clk			: in  std_logic;	-- 25MHz
		clk_mem		: in  std_logic;
		clk_div		: in  std_logic_vector(1 downto 0);	-- 0-2.5 1-5 2-10 3-10

		clk_F1		: out std_logic;
		clk_F2		: out std_logic;
		cas			: out std_logic;

		addr			: in  std_logic_vector(15 downto 0);
		data			: inout std_logic_vector(7 downto 0);
		mem_we		: in  std_logic_vector( 3 downto 0);
		mem_cs		: in  std_logic_vector( 3 downto 0);
		rd				: in  std_logic;
		wr				: in  std_logic;
		dsyn			: in  std_logic;

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
end entity;

architecture rtl of orion_video is

constant H_SYNC_POL_WS	: std_logic := '0';
constant H_SYNC_POL		: std_logic := '1';
constant V_SYNC_POL		: std_logic := '0';

signal	h_sync_pol_sig	: std_logic;

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

signal vram_col			: std_logic_vector( 5 downto 0);
signal vram_row			: std_logic_vector( 7 downto 0);
signal vaddr				: std_logic_vector(15 downto 0);
signal vdata				: std_logic_vector(15 downto 0);
signal vdata_buf			: std_logic_vector(15 downto 0);

signal wdata0				: std_logic_vector(7 downto 0);
signal wdata1				: std_logic_vector(7 downto 0);
signal wdata2				: std_logic_vector(7 downto 0);
signal wdata3				: std_logic_vector(7 downto 0);
signal mem_data0			: std_logic_vector(7 downto 0);
signal mem_data1			: std_logic_vector(7 downto 0);
signal mem_data2			: std_logic_vector(7 downto 0);
signal mem_data3			: std_logic_vector(7 downto 0);

signal vdata_to_buf		: std_logic;
signal blank_n				: std_logic;

signal h_cnt_reset		: std_logic;

signal h_sync_3_start	: std_logic;
signal h_sync_4_start	: std_logic;
signal h_sync_start		: std_logic;
signal h_sync_end_mid	: std_logic;
signal h_sync_3_end		: std_logic;
signal h_sync_4_end		: std_logic;
signal h_sync_end			: std_logic;

signal cnt_clk				: std_logic_vector(3 downto 0);
signal cnt_res_2			: std_logic;
signal cnt_res_5			: std_logic;
signal cnt_res				: std_logic;
signal clk_F				: std_logic;
signal F1_2					: std_logic;
signal F1_10				: std_logic;
signal F1					: std_logic;
signal F2_2					: std_logic;
signal F2_10				: std_logic;
signal F2					: std_logic;
signal cas_2				: std_logic;
signal cas_5				: std_logic;
signal cas_10				: std_logic;

signal mem_addr			: std_logic_vector(15 downto 0);
signal mem_acc_video		: std_logic;
signal mem_to_vbuf		: std_logic;
signal dsyn_delayed		: std_logic;

begin

--------------------------------------------------------------------------------
--                    ФОРМИРОВАНИЕ ТАКТОВЫХ СИГНАЛОВ                          --
--------------------------------------------------------------------------------

-- селектор тактовой частоты
cnt_res_2	<= cnt_clk(3) and (not cnt_clk(2)) and cnt_clk(1) and (not cnt_clk(0));
cnt_res_5	<= cnt_clk(2) and (not cnt_clk(1)) and cnt_clk(0);
with clk_div select cnt_res <=
	cnt_res_2 when "00",
	cnt_res_5 when "01",
	cnt_res_5 when "10",
	cnt_res_5 when "11";

cas_2		<= cnt_clk(3) and (not cnt_clk(1));
cas_5		<= cnt_clk(1) and cnt_clk(0);
cas_10	<= cnt_clk(1);
with clk_div select cas <=
	cas_2  when "00",
	cas_5  when "01",
	cas_10 when "10",
	cas_10 when "11";

clk_F	<= not (cnt_clk(3) or cnt_clk(2));
-- 2.5MHz, 5MHz
F1_2	<= clk_F and (not (cnt_clk(1) or cnt_clk(0)));
F2_2	<= clk_F and (not cnt_clk(1)) and cnt_clk(0);
-- 10MHz
F1_10	<= clk_F and (not cnt_clk(0)) and clk;
F2_10	<= clk_F and (not (cnt_clk(0) or clk));

with clk_div select F1 <=
	F1_2  when "00",
	F1_2  when "01",
	F1_10 when "10",
	F1_10 when "11";

with clk_div select F2 <=
	F2_2  when "00",
	F2_2  when "01",
	F2_10 when "10",
	F2_10 when "11";

	process(cnt_res, clk)
	begin
		if (cnt_res = '1') then
			cnt_clk <= (others => '0');
		elsif (rising_edge(clk)) then
			cnt_clk <= cnt_clk + '1';
		end if;
	end process;
clk_F1 <= F1;
clk_F2 <= F2;

--------------------------------------------------------------------------------
--                        АРБИТРАЖ ДОСТУПА К ПАМЯТИ                           --
--------------------------------------------------------------------------------

	process (F2)
	begin
		if (rising_edge(F2)) then
			dsyn_delayed <= dsyn;
		end if;
	end process;

	process (dsyn, clk)
	begin
		if (dsyn = '1') then
			mem_to_vbuf <= '0';
		elsif (rising_edge(clk)) then
			mem_to_vbuf <= h_cnt(0);
		end if;
	end process;

	process (mem_to_vbuf)
	begin
		if (falling_edge(mem_to_vbuf)) then
			vdata <= mem_data1 & mem_data0;
		end if;
	end process;

--------------------------------------------------------------------------------
--                       СЧЁТЧИКИ ПИКСЕЛЕЙ И СТРОК                            --
--------------------------------------------------------------------------------

h_cnt_reset <= h_cnt(9) and h_cnt(8) and h_cnt(5);
	process (h_cnt_reset, clk)
	begin
		if (h_cnt_reset = '1') then
			h_cnt <= (others => '0');
		elsif (rising_edge(clk)) then
			h_cnt <= h_cnt + '1';
		end if;
	end process;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if (((h_cnt = 10D"671") and (h480en = '0')) or ((h_cnt = 10D"719") and (h480en = '1'))) then
				if ((v_cnt = 10D"448") and (wide_scr_en='1')) or ((v_cnt = 10D"524") and (wide_scr_en='0')) then
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

h_sync_pol_sig <= H_SYNC_POL_WS when (wide_scr_en='1')
				 else H_SYNC_POL;
-- начало горизонтального синхроимпульса
h_sync_4_start		<= h_cnt(9) and h_cnt(6) and (not h_cnt(7)) and h480en;
h_sync_3_start		<= h_cnt(9) and h_cnt(4) and (h_cnt(7) nor h_cnt(8)) and (not h480en);
h_sync_start		<= h_sync_3_start or h_sync_4_start;

-- конец горизонтального синхроимпульса
h_sync_end_mid		<= h_cnt(9) and h_cnt(5);
h_sync_4_end		<= h_sync_end_mid and h_cnt(7) and h480en;
h_sync_3_end		<= h_sync_end_mid and h_cnt(6) and h_cnt(4) and (not h480en);
h_sync_end			<= h_sync_3_end or h_sync_4_end;

	process (h_sync_3_start, h_sync_3_end)
	begin
		if (h_sync_end = '1') then
			h_sync <= not h_sync_pol_sig;
		elsif (h_sync_start = '1') then
			h_sync <= h_sync_pol_sig;
		end if;
	end process;

	process (clk)
	begin
		if (rising_edge(clk)) then
			if ((v_cnt = 10D"339") and (wide_scr_en='1')) or ((v_cnt = 10D"377") and (wide_scr_en='0')) then
				v_sync <= V_SYNC_POL;
			elsif ((h_cnt = 10D"341") and (wide_scr_en='1')) or ((v_cnt = 10D"379") and (wide_scr_en='0')) then
				v_sync <= not V_SYNC_POL;
			end if;
		end if;
	end process;

VGA_HS <= h_sync;
VGA_VS <= v_sync;
VGA_SYNC_N <= '0';

	process (h_cnt, h480en)
	begin
		if (h_cnt = 10D"8") then
			h_blank <= '0';
		elsif (((h_cnt = 10D"392") and (h480en = '0')) or ((h_cnt = 10D"488") and (h480en = '1'))) then
			h_blank <= '1';
		end if;
	end process;

	process (v_cnt)
	begin
		if (v_cnt = 10D"0") then
			v_blank <= '0';
		elsif (v_cnt = 10D"256") then
			v_blank <= '1';
		end if;
	end process;

blank_n <= not (h_blank or v_blank);
VGA_BLANK_N <= blank_n;

--------------------------------------------------------------------------------
--                         ФОРМИРОВАНИЕ АДРЕСА ПИКСЕЛЯ                        --
--------------------------------------------------------------------------------

vram_col <= h_cnt(8 downto 3);
vram_row <= v_cnt(7 downto 0);
vaddr <= video_bank & vram_col & vram_row;

--------------------------------------------------------------------------------
--                       ПРЕОБРАЗОВАНИЕ ТЕКУЩЕГО ПИКСЕЛЯ                      --
--------------------------------------------------------------------------------

vdata_to_buf <= (h_cnt(2)) and (h_cnt(1)) and (h_cnt(0));

pxl: orion_pxl_conv
	port map (
		vdata_buf(7),
		vdata_buf(15),
		vdata_buf(15 downto 8),
		video_mode,
		blank_n,
		R,
		G,
		B,
		I
	);

	--load RAM data, when pixel counter is going from 7 to 0
	-- low byte
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (vdata_to_buf = '1') then
				vdata_buf(7 downto 0) <= vdata(7 downto 0);
			else
				-- shift to right
				vdata_buf(7 downto 0) <= vdata_buf(6 downto 0) & '0';
			end if;
		end if;
	end process;

	-- hight byte
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (video_mode(2) = '0') then
				-- monochrome - reset
				vdata_buf(15 downto 8) <= 8D"0";
			else
				if (vdata_to_buf = '1') then
					-- colors modes
					vdata_buf(15 downto 8) <= vdata(15 downto 8);
				else
					if (video_mode(1) = '0') then
						-- 4 color mode - shift to right
						vdata_buf(15 downto 8) <= vdata_buf(14 downto 8) & '0';
					else 
						-- 16 colors mode - not changed
					end if;
				end if;
			end if;
		end if;
	end process;

--------------------------------------------------------------------------------
--                        ВЫВОД ДАННЫХ НА VGA-ВЫХОД                           --
--------------------------------------------------------------------------------
VGA_R(0) <= R;
VGA_R(1) <= R;
VGA_R(2) <= R;
VGA_R(3) <= R;
VGA_R(4) <= R;
VGA_R(5) <= R;
VGA_R(6) <= R and I;
VGA_R(7)	<= R;

VGA_G(0) <= G;
VGA_G(1) <= G;
VGA_G(2) <= G;
VGA_G(3) <= G;
VGA_G(4) <= G;
VGA_G(5) <= G;
VGA_G(6) <= G and I;
VGA_G(7)	<= G;

VGA_B(0) <= B;
VGA_B(1) <= B;
VGA_B(2) <= B;
VGA_B(3) <= B;
VGA_B(4) <= B;
VGA_B(5) <= B;
VGA_B(6) <= B and I;
VGA_B(7)	<= B;

ram0: ram_base
	port map
	(
		mem_addr,
		clk_mem,
		wdata2,
		mem_we(0),
		mem_data0
	);

ram1: ram_base
	port map
	(
		mem_addr,
		clk_mem,
		wdata2,
		mem_we(1),
		mem_data1
	);

ram2: ram_base
	port map
	(
		mem_addr,
		clk_mem,
		wdata2,
		mem_we(2),
		mem_data2
	);

ram3: ram_base
	port map
	(
		mem_addr,
		clk_mem,
		wdata3,
		mem_we(3),
		mem_data3
	);

mem_addr <= vaddr when (dsyn = '0')
				else addr;

wdata0 <= data;
wdata1 <= data;
wdata2 <= data;
wdata3 <= data;

	process (dsyn)
	begin
		if ((dsyn = '1') and (rd = '1')) then
			case mem_cs is
				when "0001" => 	data <= mem_data0;
				when "0010" => 	data <= mem_data1;
				when "0100" =>		data <= mem_data2;
				when "1000" =>		data <= mem_data3;
				when others =>		data <= (others => 'Z');
			end case;
		else
			data <= (others => 'Z');
		end if;
	end process;

end rtl;
