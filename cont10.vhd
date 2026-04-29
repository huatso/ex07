-------------------------------------------------------------------------------
-- Arquivo   : cont10.vhd
-------------------------------------------------------------------------------
-- Descricao : Contador decimal com clear assincrono      
-------------------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor                               Descricao
--     20/02/2026  1.0     Edson Midorikawa e Felipe Valencia  versao inicial
-------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cont10 IS
    PORT (
        clock : IN STD_LOGIC;
        clear : IN STD_LOGIC;
        enable : IN STD_LOGIC;
        Q : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        RCO : OUT STD_LOGIC
    );
END cont10;

ARCHITECTURE arch OF cont10 IS
    SIGNAL IQ : INTEGER RANGE 0 TO 9;
BEGIN

    PROCESS (clock, clear, enable)
    BEGIN
        IF clear = '1' THEN -- clear assincrono
            IQ <= 0;

        ELSIF clock'event AND clock = '1' THEN
            IF enable = '1' THEN
                IF IQ = 9 THEN
                    IQ <= 0;
                ELSE
                    IQ <= IQ + 1;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    RCO <= '1' WHEN IQ = 9 ELSE
        '0'; -- fim de contagem
    Q <= STD_LOGIC_VECTOR(to_unsigned(IQ, Q'length)); -- saida Q
END ARCHITECTURE;