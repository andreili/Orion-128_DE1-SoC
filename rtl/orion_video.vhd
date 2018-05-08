-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity orion_video is
	port (
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
end entity;

architecture rtl of orion_video is

	component gal_x is
		port (
			x				:	 IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			SR16			:	 IN STD_LOGIC;
			wide_en		:	 IN STD_LOGIC;

			xres_n		:	 OUT STD_LOGIC;
			BE_n			:	 OUT STD_LOGIC;
			BH				:	 OUT STD_LOGIC;
			xle			:	 OUT STD_LOGIC;
			HS3			:	 OUT STD_LOGIC;
			HS5			:	 OUT STD_LOGIC;
			HS				:	 OUT STD_LOGIC;
			col			:	 OUT std_logic_vector(1 downto 0)
		);
	end component;

	component gal_y is
		port (
			y				:	 IN STD_LOGIC_VECTOR(9 DOWNTO 0);
			wide_en		:	 IN STD_LOGIC;
			bh				:	 IN STD_LOGIC;

			yres_n		:	 OUT STD_LOGIC;
			BL_n			:	 OUT STD_LOGIC;
			VS				:	 OUT STD_LOGIC
		);
	end component;

	component gal_vmux is
		port (
			vm				:	 IN STD_LOGIC_VECTOR(4 DOWNTO 0);	-- 1,2,3,4,5
			BL_n			:	 IN STD_LOGIC;								-- 6
			p1				:	 IN  STD_LOGIC;							-- 7
			p2				:	 IN  STD_LOGIC;							-- 8
			p3				:	 IN  STD_LOGIC;							-- 9
			p4				:	 IN  STD_LOGIC;							-- 10
			ps				:	 IN  STD_LOGIC_VECTOR(7 downto 0);	-- 11,13,14,15,16,17,18,19
			BGRI			:	 OUT STD_LOGIC_VECTOR(3 downto 0)	-- 20,21,22,23
		);
	end component;

constant XLVAL:	std_logic_vector(9 downto 0) := "0011100000";
constant YLVAL:	std_logic_vector(9 downto 0) := "0000000000";

signal x				: std_logic_vector(9 downto 0);
signal XRESN		: std_logic;
signal XLDN			: std_logic;
signal BE_n			: std_logic;
signal BH			: std_logic;
signal XLE			: std_logic;

signal y				: std_logic_vector(9 downto 0);
signal YRESN		: std_logic;
signal YLDN			: std_logic;
signal bln			: std_logic;

signal video_mode	: std_logic_vector(4 downto 0);
signal FL			: std_logic_vector(2 downto 0);
signal video_bank	: std_logic_vector(1 downto 0);
signal FNT			: std_logic_vector(3 downto 0);
signal PGD			: std_logic;
signal SR16e		: std_logic;

signal vb			: std_logic_vector(1 downto 0);
signal vid			: std_logic;
signal col			: std_logic_vector(1 downto 0);

signal vdata		: std_logic_vector(31 downto 0);

signal vr1			: std_logic_vector(7 downto 0);
signal vr2			: std_logic_vector(7 downto 0);
signal vr3			: std_logic_vector(7 downto 0);
signal vr4			: std_logic_vector(7 downto 0);
signal pxl1b		: std_logic;
signal pxl2b		: std_logic;
signal pxl3b		: std_logic;
signal pxl4b		: std_logic;
signal ps			: std_logic_vector(7 downto 0);

signal vmo			: std_logic_vector(1 downto 0);
signal stG			: std_logic;
signal stR			: std_logic;
signal sel16		: std_logic;

signal BGRIi		: std_logic_vector(3 downto 0);
signal BGRI			: std_logic_vector(3 downto 0);

begin

video_addr <= vb & x(8 downto 3) & y(7 downto 0);
blank_n <= bln;

dspr: process (x(0))
begin
	if (rising_edge(x(0))) then
		dsyn_n <= not x(1);
		vid <= x(2);
	end if;
end process;

-- X counter
XLDN <= '0' when (x=10D"1023") else '1';
x_cnt: process (clk)
begin
	if (rising_edge(clk)) then
		if (XRESN = '0') then
			x <= (others => '0');
		elsif (XLDN = '0') then
			x <= XLVAL;
		else
			x <= x + '1';
		end if;
	end if;
end process;

gx: gal_x
	port map (
		x			=> x,
		SR16		=> SR16,
		wide_en	=> wide_en,
		xres_n	=> XRESN,
		BE_n		=> BE_n,
		BH			=> BH,
		xle		=> XLE,
		HS			=> HS,
		col		=> col
	);

-- Y counter
YLDN <= '1';

y_cnt: process (clk, XLE)
begin
	if (rising_edge(clk) and (XLE='1')) then
		if (YRESN = '0') then
			y <= (others => '0');
		elsif (YLDN = '0') then
			y <= YLVAL;
		else
			y <= y + '1';
		end if;
	end if;
end process;

gy: gal_y
	port map (
		y			=> y,
		wide_en	=> wide_en,
		bh			=> BH,
		yres_n	=> YRESN,
		BL_n		=> bln,
		VS			=> VS
	);

-- video ports
pf8_pr: process(PF8, resetn)
begin
	if (resetn = '0') then
		video_mode <= (others => '0');
		FL <= (others => '0');
	elsif (rising_edge(PF8)) then
		video_mode <= data(4 downto 0);
		FL <= data(7 downto 5);
	end if;
end process;

pfa_pr: process(PFA, resetn)
begin
	if (resetn = '0') then
		video_bank <= (others => '0');
		FNT <= (others => '0');
		PGD <= '0';
		SR16e <= '0';
	elsif (rising_edge(PFA)) then
		video_bank <= data(1 downto 0);
		FNT <= data(5 downto 2);
		PGD <= data(6);
		SR16e <= data(7);
	end if;
end process;

pfc_pr: process (video_mode(3), PFC, resetn)
begin
	if (video_mode(3) = '1') then
		ps <= (others => 'Z');
	elsif (resetn = '0') then
		ps <= (others => '0');
	elsif (falling_edge(PFC)) then
		ps <= data;
	end if;
end process;

vb(0) <= (not video_bank(0)) when (video_mode(4)='0') else vid;
vb(1) <= not video_bank(1);

-- video data latch
vd0: process (col(0))
begin
	if (rising_edge(col(0))) then
		vdata(15 downto 0) <= mem_data;
	end if;
end process;

vd1: process (col(1))
begin
	if (rising_edge(col(1))) then
		vdata(31 downto 16) <= mem_data;
	end if;
end process;

-- video registers
pxl1b <= vr1(7);
vr1p: process (BE_n, clk, vdata)
begin
	if (BE_n = '0') then
		vr1 <= vdata(7 downto 0);
	elsif (rising_edge(clk)) then
		vr1(7 downto 0) <= vr1(6 downto 0) & '0';
	end if;
end process;

pxl2b <= vr2(7);
vr2p: process (video_mode(2), BE_n, clk, vdata)
begin
	if (video_mode(2) = '0') then
		vr2 <= (others => '0');
	elsif (BE_n = '0') then
		vr2 <= vdata(15 downto 8);
	elsif (rising_edge(clk)) then
		vr2(7 downto 0) <= vr2(6 downto 0) & '0';
	end if;
end process;

pxl3b <= vr3(7);
vr3p: process (BE_n, clk, vdata)
begin
	if (BE_n = '0') then
		vr3 <= vdata(23 downto 16);
	elsif (rising_edge(clk)) then
		vr3(7 downto 1) <= vr3(6 downto 0);
	end if;
end process;

pxl4b <= vr4(7);
vr4p: process (BE_n, clk, vdata)
begin
	if (BE_n = '0') then
		vr4 <= vdata(31 downto 24);
	elsif (rising_edge(clk)) then
		vr4(7 downto 1) <= vr4(6 downto 0);
	end if;
end process;

process (video_mode(3), BE_n, vdata)
begin
	if (video_mode(3) = '0') then
		ps <= (others => 'Z');
	elsif (BE_n = '0') then
		ps <= vdata(15 downto 8);
	end if;
end process;

-- video data switchers
vmux: gal_vmux
	port map (
		vm		=> video_mode,
		BL_n	=> bln,
		p1		=> pxl1b,
		p2		=> pxl2b,
		p3		=> pxl3b,
		p4		=> pxl4b,
		ps		=> ps,
		BGRI	=> BGRIi
	);

process (clk)
begin
	if (rising_edge(clk)) then
		BGRI <= BGRIi;
	end if;
end process;

-- video output
R(5 downto 0) <= (others => BGRI(1));
R(6) <= BGRI(1) and BGRI(0);
R(7) <= BGRI(1);
G(5 downto 0) <= (others => BGRI(2));
G(6) <= BGRI(2) and BGRI(0);
G(7) <= BGRI(2);
B(5 downto 0) <= (others => BGRI(3));
B(6) <= BGRI(3) and BGRI(0);
B(7) <= BGRI(3);


end rtl;
