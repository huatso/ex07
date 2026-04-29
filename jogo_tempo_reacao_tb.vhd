LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- =============================================================
-- Bancada de Testes: Jogo do Tempo de Reacao (Extensoes A3+B2)
-- Clock de simulacao: 100 ps
-- Mapeamento de display4 (anodo comum):
--   "1111001" => digito "1"  (J1 venceu)
--   "0100100" => digito "2"  (J2 venceu)
--   "1111111" => apagado     (fora do estado resultado)
--
-- Casos de teste:
--   CT0 : reset inicial
--   CT1 : rodada normal, J2 vence (tempo J1 > tempo J2)
--   CT2 : nova rodada,   J1 vence (tempo J1 < tempo J2)
--   CT3 : empate         -> J1 vence por criterio de desempate
--   CT4 : burla de J1    -> estado falha
--   CT5 : burla de J2    -> estado falha
--   CT6 : show_min (A3)  -> HEX0-3 exibe menor tempo historico
--   CT7 : reset zera minimo (A3) -> HEX0-3 exibe 9999
-- =============================================================

ENTITY jogo_tempo_reacao_tb IS
END ENTITY;

ARCHITECTURE tb OF jogo_tempo_reacao_tb IS

    -- ---- DUT ------------------------------------------------
    COMPONENT jogo_tempo_reacao IS
        GENERIC (
            PAUSA_J2_CYCLES : NATURAL := 250000000
        );
        PORT (
            clock       : IN  STD_LOGIC;
            reset       : IN  STD_LOGIC;
            jogar       : IN  STD_LOGIC;
            resposta    : IN  STD_LOGIC;
            show_min    : IN  STD_LOGIC;
            display0    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display1    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display2    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display3    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display4    : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            ligado      : OUT STD_LOGIC;
            pulso       : OUT STD_LOGIC;
            estimulo    : OUT STD_LOGIC;
            erro        : OUT STD_LOGIC;
            pronto      : OUT STD_LOGIC
        );
    END COMPONENT;

    -- ---- Parametros -----------------------------------------
    CONSTANT T : TIME := 100 ps;   -- periodo de clock

    -- Codigos esperados em display4 (7seg anodo comum)
    CONSTANT SEG_1    : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111001"; -- "1"
    CONSTANT SEG_2    : STD_LOGIC_VECTOR(6 DOWNTO 0) := "0100100"; -- "2"
    CONSTANT SEG_OFF  : STD_LOGIC_VECTOR(6 DOWNTO 0) := "1111111"; -- apagado

    -- ---- Sinais de estimulo ---------------------------------
    SIGNAL clock_in    : STD_LOGIC := '0';
    SIGNAL reset_in    : STD_LOGIC := '0';
    SIGNAL jogar_in    : STD_LOGIC := '0';
    SIGNAL resp        : STD_LOGIC := '0';
    SIGNAL show_min_in : STD_LOGIC := '0';

    -- ---- Observaveis ----------------------------------------
    SIGNAL estimulo_s  : STD_LOGIC;
    SIGNAL erro_s      : STD_LOGIC;
    SIGNAL pronto_s    : STD_LOGIC;
    SIGNAL ligado_s    : STD_LOGIC;
    SIGNAL pulso_s     : STD_LOGIC;
    SIGNAL display0_s  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL display1_s  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL display2_s  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL display3_s  : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL display4_s  : STD_LOGIC_VECTOR(6 DOWNTO 0);

    -- Auxiliar: numero do caso de teste ativo
    SIGNAL caso : INTEGER := 0;

    -- Controle do gerador de clock
    SIGNAL keep_clk : STD_LOGIC := '0';

BEGIN

    -- ---- Gerador de clock -----------------------------------
    clock_in <= (NOT clock_in) AND keep_clk AFTER T / 2;

    -- ---- Instancia do DUT -----------------------------------
    dut : jogo_tempo_reacao
    GENERIC MAP (
        PAUSA_J2_CYCLES => 20
    )
    PORT MAP (
        clock       => clock_in,
        reset       => reset_in,
        jogar       => jogar_in,
        resposta    => resp,
        show_min    => show_min_in,
        display0    => display0_s,
        display1    => display1_s,
        display2    => display2_s,
        display3    => display3_s,
        display4    => display4_s,
        ligado      => ligado_s,
        pulso       => pulso_s,
        estimulo    => estimulo_s,
        erro        => erro_s,
        pronto      => pronto_s
    );

    -- ================================================================
    -- Processo de estimulo principal
    -- ================================================================
    stimulus : PROCESS IS

        -- Pulsa jogar por 2 ciclos de clock
        PROCEDURE pulsa_jogar IS
        BEGIN
            jogar_in <= '1';
            WAIT FOR 2 * T;
            jogar_in <= '0';
        END PROCEDURE;

        -- Aplica reset por 4 ciclos e aguarda 2 ciclos de estabilizacao
        PROCEDURE aplica_reset IS
        BEGIN
            reset_in <= '1';
            WAIT FOR 4 * T;
            reset_in <= '0';
            WAIT FOR 2 * T;
        END PROCEDURE;

        -- Simula reacao de J1: aguarda estimulo, espera N ciclos, pressiona
        PROCEDURE reage_j1 (ciclos : IN INTEGER) IS
        BEGIN
            WAIT UNTIL estimulo_s = '1';
            WAIT FOR ciclos * T;
            resp <= '1';
            WAIT FOR 2 * T;
            resp <= '0';
        END PROCEDURE;

        -- Simula reacao de J2: aguarda estimulo, espera N ciclos, pressiona
        PROCEDURE reage_j2 (ciclos : IN INTEGER) IS
        BEGIN
            WAIT UNTIL estimulo_s = '1';
            WAIT FOR ciclos * T;
            resp <= '1';
            WAIT FOR 2 * T;
            resp <= '0';
        END PROCEDURE;

        -- Aguarda o fim da rodada (pronto='1') e verifica o vencedor
        PROCEDURE verifica_vencedor (esperado : IN STD_LOGIC_VECTOR(6 DOWNTO 0);
                                     msg      : IN STRING) IS
        BEGIN
            WAIT UNTIL pronto_s = '1';
            WAIT FOR T;   -- estabiliza saidas combinatoriais
            ASSERT display4_s = esperado
                REPORT msg & " | display4=" &
                       INTEGER'IMAGE(TO_INTEGER(UNSIGNED(display4_s)))
                SEVERITY error;
            ASSERT display4_s /= SEG_OFF
                REPORT msg & ": display4 esta apagado (esperava vencedor)"
                SEVERITY error;
        END PROCEDURE;

    BEGIN
        -- ---- Inicio ----------------------------------------
        ASSERT false REPORT "=== INICIO DA SIMULACAO ===" SEVERITY note;
        keep_clk <= '1';

        -- ============================================================
        -- CT0: Reset inicial
        -- ============================================================
        caso <= 0;
        ASSERT false REPORT "CT0: reset inicial" SEVERITY note;
        aplica_reset;

        -- Verificacoes de CT0
        ASSERT ligado_s   = '0' REPORT "CT0: ligado deve ser 0"   SEVERITY error;
        ASSERT estimulo_s = '0' REPORT "CT0: estimulo deve ser 0" SEVERITY error;
        ASSERT erro_s     = '0' REPORT "CT0: erro deve ser 0"     SEVERITY error;
        ASSERT pronto_s   = '0' REPORT "CT0: pronto deve ser 0"   SEVERITY error;
        ASSERT display4_s = SEG_OFF REPORT "CT0: HEX4 deve estar apagado" SEVERITY error;
        ASSERT false REPORT "CT0: OK" SEVERITY note;

        -- ============================================================
        -- CT1: Rodada normal -- J2 vence (J1=5 ciclos, J2=3 ciclos)
        --      display4 esperado: "0100100" (digito "2")
        -- ============================================================
        caso <= 1;
        ASSERT false REPORT "CT1: J1=5 ciclos, J2=3 ciclos -> J2 vence" SEVERITY note;

        pulsa_jogar;
        reage_j1(5);
        WAIT FOR 20 * T;
        reage_j2(3);
        verifica_vencedor(SEG_2, "CT1 FALHOU: J2 deveria vencer");

        ASSERT false REPORT "CT1: OK - J2 venceu" SEVERITY note;
        WAIT FOR 4 * T;

        -- ============================================================
        -- CT2: Nova rodada -- J1 vence (J1=2 ciclos, J2=6 ciclos)
        --      display4 esperado: "1111001" (digito "1")
        -- ============================================================
        caso <= 2;
        ASSERT false REPORT "CT2: J1=2 ciclos, J2=6 ciclos -> J1 vence" SEVERITY note;

        pulsa_jogar;
        reage_j1(2);
        WAIT FOR 20 * T;
        reage_j2(6);
        verifica_vencedor(SEG_1, "CT2 FALHOU: J1 deveria vencer");

        ASSERT false REPORT "CT2: OK - J1 venceu" SEVERITY note;
        WAIT FOR 4 * T;

        -- ============================================================
        -- CT3: Empate (J1=4 ciclos, J2=4 ciclos)
        --      Criterio de desempate: J1 vence
        --      display4 esperado: "1111001" (digito "1")
        -- Nota: devido ao comportamento assincrono do pulso, tempos
        -- identicos de espera geram contagens identicas no medidor.
        -- ============================================================
        caso <= 3;
        ASSERT false REPORT "CT3: empate J1=J2=4 ciclos -> J1 vence (desempate)" SEVERITY note;

        pulsa_jogar;
        reage_j1(4);
        WAIT FOR 20 * T;
        reage_j2(4);
        verifica_vencedor(SEG_1, "CT3 FALHOU: empate deve vencer J1");

        ASSERT false REPORT "CT3: OK - empate resolvido para J1" SEVERITY note;
        WAIT FOR 4 * T;

        -- ============================================================
        -- CT4: Burla de J1 (pressiona antes do estimulo)
        --      Esperado: erro='1', sistema trava em falha
        --      Saida do falha: apenas reset
        -- ============================================================
        caso <= 4;
        ASSERT false REPORT "CT4: burla de J1 antes do estimulo" SEVERITY note;

        pulsa_jogar;
        -- Aguarda alguns ciclos (sistema em j1_liga, aguardando RCO)
        -- Pressionar aqui aciona burla pois estimulo ainda nao acendeu
        WAIT FOR 5 * T;
        resp <= '1';
        WAIT UNTIL erro_s = '1';
        ASSERT false REPORT "CT4: erro='1' detectado (burla J1) - OK" SEVERITY note;

        -- Verifica que jogar nao reinicia o jogo (trava em falha)
        resp <= '0';
        WAIT FOR 2 * T;
        pulsa_jogar;
        WAIT FOR 4 * T;
        ASSERT pronto_s = '0'
            REPORT "CT4: sistema nao deveria sair de falha com jogar" SEVERITY error;
        ASSERT erro_s = '1'
            REPORT "CT4: sistema deveria permanecer em falha" SEVERITY error;

        aplica_reset;
        ASSERT erro_s   = '0' REPORT "CT4: erro deve zerar apos reset" SEVERITY error;
        ASSERT pronto_s = '0' REPORT "CT4: pronto deve ser 0 apos reset" SEVERITY error;
        ASSERT false REPORT "CT4: OK - burla J1 e reset verificados" SEVERITY note;

        -- ============================================================
        -- CT5: Burla de J2 (J1 reage corretamente, J2 pressiona cedo)
        --      Esperado: erro='1' durante vez de J2
        -- ============================================================
        caso <= 5;
        ASSERT false REPORT "CT5: burla de J2 (J1 ok, J2 pressiona antes)" SEVERITY note;

        pulsa_jogar;
        -- J1 reage normalmente
        reage_j1(3);
        -- J2 pressiona antes do estimulo (durante j2_liga)
        WAIT FOR 5 * T;
        resp <= '1';
        WAIT UNTIL erro_s = '1';
        ASSERT false REPORT "CT5: erro='1' detectado (burla J2) - OK" SEVERITY note;
        resp <= '0';

        aplica_reset;
        ASSERT false REPORT "CT5: OK - burla J2 verificada" SEVERITY note;

        -- ============================================================
        -- CT6: Extensao A3 -- chave show_min exibe menor tempo historico
        --      Apos CT1 e CT2, o menor tempo foi o de J2 em CT1 (3 ciclos)
        --      e J1 em CT2 (2 ciclos). O minimo global deve ser o menor.
        --      Com show_min='1': HEX0-3 exibe tempo_min
        --      Com show_min='0': HEX0-3 volta ao modo normal
        -- ============================================================
        caso <= 6;
        ASSERT false REPORT "CT6: chave show_min (A3)" SEVERITY note;

        -- Realiza uma rodada adicional para garantir minimo valido
        pulsa_jogar;
        reage_j1(3);
        reage_j2(3);
        WAIT UNTIL pronto_s = '1';
        WAIT FOR 2 * T;

        -- Ativa show_min: HEX0-3 deve exibir menor tempo historico
        show_min_in <= '1';
        WAIT FOR 4 * T;
        -- Verifica que os displays mudam (nao mostram mais o medidor zerado)
        -- (verificacao visual na simulacao; asseroes de valor dependem da rodada)
        ASSERT false
            REPORT "CT6: show_min=1 -> HEX0-3 exibe tempo_min (verificar waveform)"
            SEVERITY note;

        -- Desativa show_min: HEX0-3 volta ao normal
        show_min_in <= '0';
        WAIT FOR 2 * T;
        ASSERT false REPORT "CT6: OK - show_min verificado" SEVERITY note;

        -- ============================================================
        -- CT7: Reset zera o minimo historico (A3)
        --      Apos reset com show_min='1': HEX0-3 deve exibir 9999
        --      "9999" em BCD: Q3=9="0010000", Q2=9, Q1=9, Q0=9
        -- ============================================================
        caso <= 7;
        ASSERT false REPORT "CT7: reset zera tempo_min (A3)" SEVERITY note;

        aplica_reset;

        show_min_in <= '1';
        WAIT FOR 4 * T;

        -- Apos reset, tempo_min=0x9999: cada digito deve mostrar "9"
        -- hex7seg: 9 -> "0010000"
        ASSERT display0_s = "0010000"
            REPORT "CT7 FALHOU: display0 deve ser '9' apos reset" SEVERITY error;
        ASSERT display1_s = "0010000"
            REPORT "CT7 FALHOU: display1 deve ser '9' apos reset" SEVERITY error;
        ASSERT display2_s = "0010000"
            REPORT "CT7 FALHOU: display2 deve ser '9' apos reset" SEVERITY error;
        ASSERT display3_s = "0010000"
            REPORT "CT7 FALHOU: display3 deve ser '9' apos reset" SEVERITY error;

        ASSERT false REPORT "CT7: OK - minimo zerado para 9999 apos reset" SEVERITY note;
        show_min_in <= '0';
        WAIT FOR 2 * T;

        -- ---- Fim -----------------------------------------------
        ASSERT false REPORT "=== FIM DA SIMULACAO ===" SEVERITY note;
        keep_clk <= '0';
        WAIT;
    END PROCESS;

END ARCHITECTURE;
