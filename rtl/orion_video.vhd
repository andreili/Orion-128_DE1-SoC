-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_video is
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
					h_sync <= h_sync_pol_sig;
				elsif (h_cnt = 10D"671") then
					h_sync <= not h_sync_pol_sig;
				end if;
			end if;

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
--VGA_BLANK_N <= blank_n;
VGA_BLANK_N <= '1';

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

-- port A - CPU
-- port B - GPU
ram0: ram_dualp
	port map
	(
		addr,
		vaddr,
		clk,
		clk,
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
		clk,
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

	process (rd, mem_cs)
	begin
		if (rd = '1') then
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
