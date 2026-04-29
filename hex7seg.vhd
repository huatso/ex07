-------------------------------------------------------------------------------
-- Arquivo   : hex7seg.vhd
-------------------------------------------------------------------------------
-- Descricao : Conversor de hexadecimal para 7 segmentos        
-------------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor                               Descricao
--     20/02/2026  1.0     Edson Midorikawa e Felipe Valencia  versao inicial
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY hex7seg IS
	PORT (
		hex : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
		display : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
	);
END hex7seg;

ARCHITECTURE arch OF hex7seg IS
BEGIN
	--
	--       0  
	--      ---  
	--     |   |
	--    5|   |1
	--     | 6 |
	--      ---  
	--     |   |
	--    4|   |2
	--     |   |
	--      ---  
	--       3  
	--
	display <= "1000000" WHEN hex = "0000" ELSE -- 0
		"1111001" WHEN hex = "0001" ELSE -- 1
		"0100100" WHEN hex = "0010" ELSE -- 2
		"0110000" WHEN hex = "0011" ELSE -- 3
		"0011001" WHEN hex = "0100" ELSE -- 4
		"0010010" WHEN hex = "0101" ELSE -- 5
		"0000010" WHEN hex = "0110" ELSE -- 6
		"1111000" WHEN hex = "0111" ELSE -- 7
		"0000000" WHEN hex = "1000" ELSE -- 8
		"0010000" WHEN hex = "1001" ELSE -- 9
		"0001000" WHEN hex = "1010" ELSE -- A
		"0000011" WHEN hex = "1011" ELSE -- B
		"1000110" WHEN hex = "1100" ELSE -- C
		"0100001" WHEN hex = "1101" ELSE -- D
		"0000110" WHEN hex = "1110" ELSE -- E
		"0001110" WHEN hex = "1111" ELSE -- F
		"1111111";
END ARCHITECTURE;