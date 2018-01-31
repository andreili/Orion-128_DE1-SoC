-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity orion_periph is
	port (
		data		: inout std_logic_vector( 7 downto 0);
		addr		: inout std_logic_vector(15 downto 0);
		reset_p	: in  std_logic;
		wr			: in  std_logic;
		rd			: in  std_logic;
		cs			: in  std_logic_vector(3 downto 0);
		reset_btn: out std_logic
	);
end entity;

architecture rtl of orion_periph is

	component i8255
		port
		(
			data	:	 inout std_logic_vector(7 downto 0);
			reset	:	 in std_logic;
			ncs	:	 in std_logic;
			nrd	:	 in std_logic;
			nwr	:	 in std_logic;
			addr	:	 in std_logic_vector(1 downto 0);
			pa		:	 inout std_logic_vector(7 downto 0);
			pb		:	 inout std_logic_vector(7 downto 0);
			pch	:	 inout std_logic_vector(3 downto 0);
			pcl	:	 inout std_logic_vector(3 downto 0)
		);
	end component;

signal port_keyb		: std_logic_vector(24 downto 0);
signal tape_out		: std_logic;
signal tape_in			: std_logic;
signal rus_lat			: std_logic;

signal port_io1		: std_logic_vector(23 downto 0);
signal port_io2		: std_logic_vector(23 downto 0);

signal rd_n				: std_logic;
signal wr_n				: std_logic;

begin

rd_n <= not rd;
wr_n <= not wr;

port_keyb(24) <= '0';

rus_lat <= not port_keyb(7);
tape_out <= port_keyb(4);
reset_btn <= port_keyb(24);
port_keyb(0) <= tape_in;
/*keyb: i8255
	port map (
		data,
		reset_p,
		not cs(0),
		rd_n,
		wr_n,
		addr(1 downto 0),
		port_keyb(23 downto 16),
		port_keyb(15 downto 8),
		port_keyb(3 downto 0),
		port_keyb(7 downto 4)
	);

io1: i8255
	port map (
		data,
		reset_p,
		not cs(1),
		rd_n,
		wr_n,
		addr(1 downto 0),
		port_io1(23 downto 16),
		port_io1(15 downto 8),
		port_io1(7 downto 4),
		port_io1(3 downto 0)
	);

io2: i8255
	port map (
		data,
		reset_p,
		not cs(2),
		rd_n,
		wr_n,
		addr(1 downto 0),
		port_io2(23 downto 16),
		port_io2(15 downto 8),
		port_io2(7 downto 4),
		port_io2(3 downto 0)
	);*/

end;
