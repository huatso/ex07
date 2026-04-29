LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY pulso_assincrono IS
    PORT (
        resposta_reset : IN STD_LOGIC;
        estimulo : IN STD_LOGIC;
        pulso : OUT STD_LOGIC
    );
END ENTITY pulso_assincrono;

ARCHITECTURE arch OF pulso_assincrono IS
    SIGNAL pulso_int : STD_LOGIC := '0';
BEGIN
    resposta : PROCESS (resposta_reset, estimulo)
    BEGIN
        IF resposta_reset = '0' AND estimulo = '1' THEN
            pulso_int <= '1';
        ELSE
            pulso_int <= '0';
        END IF;
    END PROCESS;

    pulso <= pulso_int;

END ARCHITECTURE arch;