LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Unidade de Controle do Jogo do Tempo de Reacao
-- Extensoes A3 (menor tempo via chave) e B2 (dois jogadores, exibe vencedor)
--
-- Estados:
--   inicial   : aguarda sinal jogar
--   j1_liga   : vez do jogador 1, aguardando estimulo
--   j1_conta  : medindo reacao do jogador 1
--   j1_fim    : salva tempo J1, aguarda interface resetar
--   j2_espera : pausa configuravel entre J1 e J2
--   j2_liga   : vez do jogador 2, aguardando estimulo
--   j2_conta  : medindo reacao do jogador 2
--   j2_fim    : salva tempo J2, aguarda interface resetar
--   resultado : exibe vencedor (pronto='1')
--   falha     : erro (burla detectada), aguarda reset

ENTITY jogo_tempo_reacao_uc IS
    GENERIC (
        PAUSA_J2_CYCLES : NATURAL := 250000000
    );
    PORT (
        clock            : IN  STD_LOGIC;
        reset            : IN  STD_LOGIC;
        jogar            : IN  STD_LOGIC;
        estimulo         : IN  STD_LOGIC;
        erro_interface   : IN  STD_LOGIC;
        pronto_medidor   : IN  STD_LOGIC;
        pronto_interface : IN  STD_LOGIC;
        iniciar          : OUT STD_LOGIC;
        sel_j2           : OUT STD_LOGIC;
        salva_j1         : OUT STD_LOGIC;
        salva_j2         : OUT STD_LOGIC;
        pronto           : OUT STD_LOGIC;
        mostra_resultado : OUT STD_LOGIC;
        db_estado        : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY jogo_tempo_reacao_uc;

ARCHITECTURE arch OF jogo_tempo_reacao_uc IS
    TYPE tipo_estado IS (
        inicial,
        j1_liga, j1_conta, j1_fim,
        j2_espera, j2_liga, j2_conta, j2_fim,
        resultado, falha
    );
    SIGNAL estado, posterior : tipo_estado;
    SIGNAL contador_pausa_j2 : NATURAL RANGE 0 TO PAUSA_J2_CYCLES - 1 := 0;
BEGIN

    seq : PROCESS (clock, reset)
    BEGIN
        IF reset = '1' THEN
            estado <= inicial;
            contador_pausa_j2 <= 0;
        ELSIF rising_edge(clock) THEN
            estado <= posterior;
            IF estado = j2_espera THEN
                IF contador_pausa_j2 < PAUSA_J2_CYCLES - 1 THEN
                    contador_pausa_j2 <= contador_pausa_j2 + 1;
                ELSE
                    contador_pausa_j2 <= 0;
                END IF;
            ELSE
                contador_pausa_j2 <= 0;
            END IF;
        END IF;
    END PROCESS seq;

    comb : PROCESS (estado, jogar, estimulo, erro_interface, pronto_medidor, pronto_interface, contador_pausa_j2)
    BEGIN
        iniciar          <= '0';
        sel_j2           <= '0';
        salva_j1         <= '0';
        salva_j2         <= '0';
        pronto           <= '0';
        mostra_resultado <= '0';
        db_estado        <= "0000";
        posterior        <= estado;

        CASE estado IS
            WHEN inicial =>
                db_estado <= "0001";
                IF jogar = '1' THEN
                    posterior <= j1_liga;
                END IF;

            WHEN j1_liga =>
                db_estado <= "0010";
                iniciar   <= '1';
                sel_j2    <= '0';
                IF erro_interface = '1' THEN
                    posterior <= falha;
                ELSIF estimulo = '1' THEN
                    posterior <= j1_conta;
                END IF;

            WHEN j1_conta =>
                db_estado <= "0011";
                iniciar   <= '1';
                sel_j2    <= '0';
                IF pronto_medidor = '1' THEN
                    salva_j1  <= '1';
                    posterior <= j1_fim;
                END IF;

            WHEN j1_fim =>
                db_estado <= "0100";
                sel_j2    <= '0';
                IF pronto_interface = '0' THEN
                    posterior <= j2_espera;
                END IF;

            WHEN j2_espera =>
                db_estado <= "0101";
                sel_j2    <= '1';
                IF contador_pausa_j2 = PAUSA_J2_CYCLES - 1 THEN
                    posterior <= j2_liga;
                END IF;

            WHEN j2_liga =>
                db_estado <= "0110";
                iniciar   <= '1';
                sel_j2    <= '1';
                IF erro_interface = '1' THEN
                    posterior <= falha;
                ELSIF estimulo = '1' THEN
                    posterior <= j2_conta;
                END IF;

            WHEN j2_conta =>
                db_estado <= "0111";
                iniciar   <= '1';
                sel_j2    <= '1';
                IF pronto_medidor = '1' THEN
                    salva_j2  <= '1';
                    posterior <= j2_fim;
                END IF;

            WHEN j2_fim =>
                db_estado <= "1000";
                sel_j2    <= '1';
                IF pronto_interface = '0' THEN
                    posterior <= resultado;
                END IF;

            WHEN resultado =>
                db_estado        <= "1001";
                pronto           <= '1';
                mostra_resultado <= '1';
                IF jogar = '1' THEN
                    posterior <= j1_liga;
                END IF;

            WHEN falha =>
                db_estado <= "1010";
                posterior <= falha;
        END CASE;
    END PROCESS comb;
END ARCHITECTURE arch;
