-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity gal_vmux is
	port (
		vm0			:	 IN STD_LOGIC;								-- 1
		vm1			:	 IN STD_LOGIC;								-- 2
		vm4			:	 IN STD_LOGIC;								-- 3
		BL_n			:	 IN STD_LOGIC;								-- 4
		p1				:	 IN  STD_LOGIC;							-- 5
		p2				:	 IN  STD_LOGIC;							-- 6
		p3				:	 IN  STD_LOGIC;							-- 7
		p4				:	 IN  STD_LOGIC;							-- 8
		ps				:	 IN  STD_LOGIC_VECTOR(7 downto 0);	-- 9,10,11,13,14,15,16,17
		BGR			:	 OUT STD_LOGIC_VECTOR(5 downto 0)	-- 18,19,20,21,22,23
	);
end entity;

architecture rtl of gal_vmux is

begin

BGR(0) <= BL_n and ((((not vm4) and (not vm1)) and ((p2 and p1) or ((not p2) and (p1 and vm0))))	-- standart mode, R
	or (((not vm4) and vm1) and ((p1 and ps(2)) or ((not p1) and ps(6))))	-- pseudocolors mode, R
	or (vm4 and p3));	
BGR(1) <= BL_n and ((((not vm4) and (not vm1)) and ((p2 and '0') or ((not p2) and (p1 and (not vm0)))))	-- standart mode, G
	or (((not vm4) and vm1) and ((p1 and ps(1)) or ((not p1) and ps(5))))	-- pseudocolors mode, G
	or (vm4 and p1));	-- G
BGR(2) <= BL_n and ((((not vm4) and (not vm1)) and ((p2 and (not p1)) or ((not p2) and (p1 and vm0))))	-- standart mode, B
	or (((not vm4) and vm1) and ((p1 and ps(0)) or ((not p1) and ps(4))))	-- pseudocolors mode, B
	or (vm4 and p4));	-- B

BGR(3) <= BL_n and ((((not vm4) and (not vm1)) and ((p2 and p1) or ((not p2) and (p1 and vm0))))	-- standart mode, R
	or (((not vm4) and vm1) and ((p1 and ps(2) and ps(3)) or ((not p1) and ps(6) and ps(7))))	-- pseudocolors mode, R
	or (vm4 and p2 and p3));	
BGR(4) <= BL_n and ((((not vm4) and (not vm1)) and ((p2 and '0') or ((not p2) and (p1 and (not vm0)))))	-- standart mode, G
	or (((not vm4) and vm1) and ((p1 and ps(1) and ps(3)) or ((not p1) and ps(5) and ps(7))))	-- pseudocolors mode, G
	or (vm4 and p2 and p1));	-- G
BGR(5) <= BL_n and ((((not vm4) and (not vm1)) and ((p2 and (not p1)) or ((not p2) and (p1 and vm0))))	-- standart mode, B
	or (((not vm4) and vm1) and ((p1 and ps(0) and ps(3)) or ((not p1) and ps(4) and ps(7))))	-- pseudocolors mode, B
	or (vm4 and p2 and p4));	-- B

end rtl;
