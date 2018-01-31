-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;

-- Фактическое разрешение на выходе: 1920х1080@60
-- PixelClock: 148.5 MHz

-- Используемый фрагмент: 1024x1024
-- требуется видеопамяти: 128кБ (для разрешения 512x512)

entity vga is
	generic (
		H_SIZE			: integer := 1920;
		H_FRONT_PORCH	: integer := 88;--88;
		H_SYNC_PULSE	: integer := 44;--44;
		H_BACK_PORCH	: integer := 148;--148;
		H_POL				: std_logic := '1';	-- (1 = positive, 0 = negative)

		V_SIZE			: integer := 1080;
		V_FRONT_PORCH	: integer := 4;--4;
		V_SYNC_PULSE	: integer := 5;--5;
		V_BACK_PORCH	: integer := 36;--36;
		V_POL				: std_logic := '1'	-- (1 = positive, 0 = negative)
	);
	port 
	(
		clk		: in  std_logic;	-- 148,4MHz

		vaddr		: in std_logic_vector(13 downto 0);
		pxls		: in  std_logic_vector(31 downto 0);

		vga_r		: out std_logic_vector(7 downto 0);
		vga_g	   : out std_logic_vector(7 downto 0);
		vga_b		: out std_logic_vector(7 downto 0);
		hsync		: out std_logic;
		vsync		: out std_logic;
		blank_n	: out std_logic
	);
end entity;

architecture rtl of vga is

component ram_vga is
	port (
		address	: in  std_logic_vector(13 downto 0);
		clock		: in  std_logic;
		data		: in  std_logic_vector(15 downto 0);
		rden		: in  std_logic;
		wren		: in  std_logic;
		q			: out std_logic_vector(15 downto 0)
	);
end component;

CONSTANT H_PERIOD		: std_logic_vector(11 downto 0) := 12D"2200"; 	-- H_SYNC_PULSE + H_BACK_PORCH + H_SIZE + H_FRONT_PORCH;			--total number of pixel clocks in a row
CONSTANT H_PERIOD1	: std_logic_vector(11 downto 0) := 12D"2199"; 	-- H_SYNC_PULSE + H_BACK_PORCH + H_SIZE + H_FRONT_PORCH - 1;	--clock idx in a row
CONSTANT V_PERIOD		: std_logic_vector(11 downto 0) := 12D"1125";	-- V_SYNC_PULSE + V_BACK_PORCH + V_SIZE + V_FRONT_PORCH;			--total number of rows in column
CONSTANT V_PERIOD1	: std_logic_vector(11 downto 0) := 12D"1124";	-- V_SYNC_PULSE + V_BACK_PORCH + V_SIZE + V_FRONT_PORCH;			-- clock idx in column

constant H_SYNC_START: std_logic_vector(11 downto 0) := 12D"2008";	-- H_SIZE + H_FRONT_PORCH
constant H_SYNC_END	: std_logic_vector(11 downto 0) := 12D"2052";	-- H_SIZE + H_FRONT_PORCH + H_SYNC_PULSE
constant V_SYNC_START: std_logic_vector(11 downto 0) := 12D"1084";	-- V_SIZE + V_FRONT_PORCH
constant V_SYNC_END	: std_logic_vector(11 downto 0) := 12D"1089";	-- V_SIZE + V_FRONT_PORCH + V_SYNC_PULSE

constant H_EM_BLANK	: std_logic_vector(11 downto 0) := 12D"472";		-- ширина бокового поля - 8 пикселей
constant H_EM_BLANK1	: std_logic_vector(11 downto 0) := 12D"493";		-- номер такта, на котором заканчивается левое поле
constant H_EM_BLANK2	: std_logic_vector(11 downto 0) := 12D"478";		-- H_EM_BLANK - 1
constant H_EM_SIZE	: std_logic_vector(11 downto 0) := 12D"960";		-- ширина отображаемого изображения
constant H_EM_SIZE1	: std_logic_vector(11 downto 0) := 12D"1345";	-- номер такта, с которого начинается правое поле
constant H_EM_SIZE2	: std_logic_vector(11 downto 0) := 12D"1344";	-- H_EM_SIZE1 - 1
constant V_EM_BLANK	: std_logic_vector(11 downto 0) := 12D"284";		-- высота вертикального поля
constant V_EM_BLANK1	: std_logic_vector(11 downto 0) := 12D"283";		-- номер такта, на котором заканчивается верхнее поле
constant V_EM_SIZE	: std_logic_vector(11 downto 0) := 12D"768";		-- высота отображаемого изображения
constant V_EM_SIZE1	: std_logic_vector(11 downto 0) := 12D"795";		-- номер такта, с которого начинается нижнее поле

signal VGA_H			: std_logic_vector(11 downto 0) := (others => '0');		-- счётчик тактов в строке
signal VGA_V			: std_logic_vector(11 downto 0) := (others => '0');		-- счётчик строк в кадре

signal vga_pixel_buf	: std_logic_vector(31 downto 0);
signal vga_pixel_col	: std_logic_vector(9 downto 0);
signal vga_pixel_row	: std_logic_vector(9 downto 0);
signal vga_pixel_val	: std_logic_vector(3 downto 0) := (others => '0');
signal vga_pixel_num	: std_logic_vector(2 downto 0);	-- номер пикселя в слове

-- промежуточные значения цветов для вывода
signal vga_r_mid		: std_logic_vector(7 downto 0);
signal vga_g_mid		: std_logic_vector(7 downto 0);
signal vga_b_mid		: std_logic_vector(7 downto 0);

signal vram_addr		: std_logic_vector(13 downto 0);

begin

--------------------------------------------------------------------------------
--                          ФОРМИРОВАНИЕ СИГНАЛОВ VGA                         --
--------------------------------------------------------------------------------

-- вычисление столбца пикселя в буфере (с учётом бордюра, но без удвоения изображения)
vga_pixel_col <= std_logic_vector(unsigned(VGA_H)-unsigned(H_EM_BLANK))(9 downto 0)
						when (VGA_H>H_EM_BLANK2 and VGA_H<H_EM_SIZE1)
						else (others => '0');
vga_pixel_num <= vga_pixel_col(3 downto 1);
-- вычисление строки пикселя в буфере (с учётом бордюра, но без удвоения изображения)
vga_pixel_row <= std_logic_vector(unsigned(VGA_V)-unsigned(V_EM_BLANK))(9 downto 0)
						when (VGA_V>V_EM_BLANK1 and VGA_V<V_EM_SIZE1)
						else (others => '0');

-- формирование сигнала наличия изображения (для включения ЦАПа)
blank_n <= '1' when (VGA_H < "011110000000" and VGA_V < "010000111000")
	else '0';

-- чтение данных пикселя из буффера
with vga_pixel_num select vga_pixel_val <=
	vga_pixel_buf(15 downto 12) when "000",
	vga_pixel_buf(11 downto  8) when "001",
	vga_pixel_buf( 7 downto  4) when "010",
	vga_pixel_buf( 3 downto  0) when "011",
	vga_pixel_buf(31 downto 28) when "100",
	vga_pixel_buf(27 downto 24) when "101",
	vga_pixel_buf(23 downto 20) when "110",
	vga_pixel_buf(19 downto 16) when "111";

-- формирование байтов цветов из битового состояния
vga_r_mid(6 downto 0) <= (others => '1') when (vga_pixel_val(0) = '1')
					 else (others => '0');
vga_r_mid(7) <= vga_pixel_val(3) when (vga_pixel_val(0) = '1')
					 else '0';
vga_g_mid(6 downto 0) <= (others => '1') when (vga_pixel_val(1) = '1')
					 else (others => '0');
vga_g_mid(7) <= vga_pixel_val(3) when (vga_pixel_val(1) = '1')
					 else '0';
vga_b_mid(6 downto 0) <= (others => '1') when (vga_pixel_val(2) = '1')
					 else (others => '0');
vga_b_mid(7) <= vga_pixel_val(3) when (vga_pixel_val(2) = '1')
					 else '0';

	-- формирование синхроимпульсов
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (VGA_H < H_SYNC_START) or (VGA_H > H_SYNC_END) then
				hsync <= not H_POL;
			else
				hsync <= H_POL;
			end if;
	
			if (VGA_V < V_SYNC_START) or (VGA_V > V_SYNC_END) then
				vsync <= not V_POL;
			else
				vsync <= V_POL;
			end if;
		end if;
	end process;
	
	-- вывод цвета на преобразователь
	process (clk)
	begin
		if (rising_edge(clk)) then
			if ((VGA_H>H_EM_BLANK1) and (VGA_H<H_EM_SIZE2)) and
			   ((VGA_V>V_EM_BLANK1) and (VGA_V<V_EM_SIZE1)) then
				vga_r <= vga_r_mid;
				vga_g <= vga_g_mid;
				vga_b <= vga_b_mid;
			else
				vga_r <= (others => '0');
				vga_g <= (others => '0');
				vga_b <= (others => '0');
			end if;
		end if;
	end process;
	
	-- обработка счётчиков пикселей и строк
	process (clk)
	begin
		if (rising_edge(clk)) then
			if (VGA_H = H_PERIOD1) then
				VGA_H <= (others => '0');
				
				if (VGA_V = V_PERIOD) then
					VGA_V <= (others => '0');
				else
					VGA_V <= VGA_V + 1;
				end if;
			else
				VGA_H <= VGA_H + 1;
			end if;
		end if;
	end process;

--------------------------------------------------------------------------------
--                               РАБОТА С ОЗУ                                 --
--------------------------------------------------------------------------------

vram_addr <= vga_pixel_col(9 downto 4) & vga_pixel_row(8 downto 1);

vram: ram_vga
	port map (
		vram_addr,
		clk,
		pxls,
		'1',
		'1',
		vga_pixel_buf
	);

	/*process (clk)
	begin
		if (rising_edge(clk)) then
			if (VGA_H(3 downto 0) = "1111") then
				vga_pixel_buf <= pxls;
				vaddr <= vga_pixel_col(9 downto 4) & vga_pixel_row(8 downto 1);
			end if;
		end if;
	end process;*/

end rtl;
