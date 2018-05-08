library IEEE;
use IEEE.std_logic_1164.all;

entity hex_led is
	port (
		clk		: in	std_logic;
		reset_n	: in	std_logic;
		hex_code	: in	std_logic_vector(3 downto 0);
		hex_led	: out	std_logic_vector(6 downto 0)
	);
end hex_led;

architecture hex_led_arch of hex_led is
begin
	process (clk) begin
		if clk'event and clk = '1' then
			if (reset_n = '0') then
				hex_led <= "0111111";
			else
				case hex_code is
				when "0000" =>	hex_led <= "1000000"; -- 0
				when "0001" =>	hex_led <= "1111001"; -- 1
				when "0010" =>	hex_led <= "0100100"; -- 2
				when "0011" =>	hex_led <= "0110000"; -- 3
				when "0100" =>	hex_led <= "0011001"; -- 4
				when "0101" =>	hex_led <= "0010010"; -- 5
				when "0110" =>	hex_led <= "0000010"; -- 6
				when "0111" =>	hex_led <= "1111000"; -- 7
				when "1000" =>	hex_led <= "0000000"; -- 8
				when "1001" =>	hex_led <= "0010000"; -- 9
				when "1010" =>	hex_led <= "0001000"; -- a
				when "1011" =>	hex_led <= "0000011"; -- b
				when "1100" =>	hex_led <= "1000110"; -- c
				when "1101" =>	hex_led <= "0100001"; -- d
				when "1110" =>	hex_led <= "0000110"; -- e
				when "1111" =>	hex_led <= "0001110"; -- f
				when others =>	hex_led <= "0111111"; -- -
				end case;
			end if;
		end if;
	end process;
end hex_led_arch;