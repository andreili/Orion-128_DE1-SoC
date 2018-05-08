-- altera vhdl_input_version vhdl_2008

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity orion_memory is
	port (
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
end entity;

architecture rtl of orion_memory is

signal cycle	: std_logic_vector(3 downto 0);

/*signal CA		: std_logic_vector(19 downto 0);
signal CWEn		: std_logic;
signal CRDn		: std_logic;
signal CD		: std_logic_vector(7 downto 0);
signal DO		: std_logic_vector(7 downto 0);

signal mem_c	: std_logic;*/
signal A19		: std_logic;

begin

process (clk)
begin
	if (rising_edge(clk)) then
		cycle <= cycle + '1';
	end if;
end process;

SCE <= A19;
A19 <= MA(19) when (dsyn_n='0') else '0';
SLB <= MA(16) when (dsyn_n='0') else '0';
SUB <= (not MA(16)) when (dsyn_n='0') else '0';
SOE <= MRDn when (dsyn_n='0') else '0';
SWE <= MWEn when (dsyn_n='0') else '1';

SA(17 downto 0) <= (MA(18 downto 17) & MA(15 downto 14) & addr(13 downto 0)) when (dsyn_n = '0')
	else ("00" & vaddr(15 downto 0));
SD(7 downto 0) <= data when ((MWEn='0') and (SLB='0'))
	else "ZZZZZZZZ";
SD(15 downto 8) <= data when ((MWEn='0') and (SUB='0'))
	else "ZZZZZZZZ";
data <= SD(7 downto 0) when ((MRDn='0') and (MA(16)='0'))
	else SD(15 downto 8) when ((MRDn='0') and (MA(16)='1'))
	else "ZZZZZZZZ";

vdata(15 downto 0) <= SD(15 downto 0);

/*SCEs <= clk xor cycle(0);
SCE <= SCEs;
SLB <= (not cycle(1)) and CA(16);
SUB <= (not cycle(1)) and (not CA(16));
SWE <= (CWEn or cycle(1)) and SCEs;
SOE <= (CRDn xor cycle(1)) and SCEs;

SA(17 downto 0) <= (CA(18 downto 17) & CA(15 downto 0)) when (cycle(1) = '0')
	else ("00" & vaddr(15 downto 0));
SD(7 downto 0) <= CD when ((CWEn='0') and (SLB='0'))
	else "ZZZZZZZZ";
SD(15 downto 8) <= CD when ((CWEn='0') and (SUB='0'))
	else "ZZZZZZZZ";
data <= DO when (MRDn='0') else "ZZZZZZZZ";

vdata(15 downto 0) <= SD(15 downto 0);

-- latch data from memory to CPU
process (SCEs)
begin
	if (rising_edge(SCEs)) then
		if ((CRDn='0') and (cycle(1)='1')) then
			if (CA(16) = '0') then
				DO <= SD(7 downto 0);
			else
				DO <= SD(15 downto 8);
			end if;
		end if;
	end if;
end process;

mem_c <= MWEn and MRDn;
process (mem_c)
begin
	if (falling_edge(mem_c)) then
		CA <= MA(19 downto 14) & addr;
		CD <= data;
		CWEn <= MWEn;
		CRDn <= MRDn;
	end if;
end process;

m2v <= cycle(1) and (not SCE);*/

end rtl;
