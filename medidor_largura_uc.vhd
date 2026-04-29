LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY medidor_largura_uc IS
    PORT (
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        liga : IN STD_LOGIC;
        sinal : IN STD_LOGIC;
        rco : IN STD_LOGIC;
        pronto : OUT STD_LOGIC;
        zeraCont : OUT STD_LOGIC;
        contaCont : OUT STD_LOGIC;
        db_estado : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) --sinal de depuraçao
    );
END ENTITY medidor_largura_uc;

ARCHITECTURE arch OF medidor_largura_uc IS
    TYPE tipo_estado IS (inicial, ligado, prepara, conta, fim, espera);
    SIGNAL estado, posterior : tipo_estado;

BEGIN
    inicio : PROCESS (clock, reset)
    BEGIN
        IF reset = '1' THEN
            estado <= inicial;
        ELSIF clock'event AND clock = '1' THEN
            estado <= posterior;
        END IF;
    END PROCESS inicio;

    maquina : PROCESS (estado, sinal, rco, liga)
    BEGIN
        CASE estado IS
            WHEN inicial =>
                db_estado <= "0001";
                zeraCont <= '1';
                contaCont <= '0';
                pronto <= '0';
                IF liga = '1' THEN
                    posterior <= ligado;
                ELSE
                    posterior <= inicial;
                END IF;
            WHEN ligado =>
                db_estado <= "0010";
                IF sinal = '1' THEN
                    posterior <= prepara;
                ELSE
                    posterior <= ligado;
                END IF;
            WHEN prepara =>
                pronto <= '0';
                zeraCont <= '1';
                db_estado <= "0011";
                posterior <= conta;
            WHEN conta =>
                db_estado <= "0100";
                zeraCont <= '0';
                contaCont <= '1';
                IF sinal = '0' THEN
                    posterior <= fim;
                ELSE
                    posterior <= conta;
                END IF;
            WHEN fim =>
                contaCont <= '0';
                db_estado <= "0101";
                pronto <= '1';
                posterior <= espera;
            WHEN espera =>
                pronto <= '0';
                db_estado <= "0110";
                IF liga = '1'AND sinal = '1' THEN
                    posterior <= prepara;
                ELSIF liga = '0' THEN
                    posterior <= inicial;
                ELSE
                    posterior <= espera;
                END IF;

        END CASE;
    END PROCESS maquina;
END ARCHITECTURE arch;