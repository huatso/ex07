LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- Jogo do Tempo de Reacao - Top Level
-- Extensoes implementadas:
--   A3: chave show_min exibe menor tempo historico nos displays HEX0-3
--   B2: dois jogadores; apos a rodada, HEX0-3 mostra tempo do vencedor
--       e HEX4 exibe "1" ou "2" indicando o jogador vencedor
--
-- Entradas adicionais em relacao ao projeto base:
--   resposta    : botao de resposta (único, usado para o jogador ativo)
--   show_min    : chave SW para exibir menor tempo (A3)
-- Saida adicional:
--   display4    : HEX4 - exibe vencedor ("1" ou "2") apos rodada

ENTITY jogo_tempo_reacao IS
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
END ENTITY jogo_tempo_reacao;

ARCHITECTURE behavioral OF jogo_tempo_reacao IS

    COMPONENT jogo_tempo_reacao_uc IS
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
    END COMPONENT;

    COMPONENT interface_leds_botoes IS
        PORT (
            clock             : IN  STD_LOGIC;
            reset             : IN  STD_LOGIC;
            iniciar           : IN  STD_LOGIC;
            resposta          : IN  STD_LOGIC;
            ligado            : OUT STD_LOGIC;
            estimulo          : OUT STD_LOGIC;
            pulso             : OUT STD_LOGIC;
            pulso_scope       : OUT STD_LOGIC;
            erro              : OUT STD_LOGIC;
            pronto            : OUT STD_LOGIC;
            burlou_assinc     : OUT STD_LOGIC;
            db_estado_display : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT medidor_largura IS
        PORT (
            clock         : IN  STD_LOGIC;
            reset         : IN  STD_LOGIC;
            liga          : IN  STD_LOGIC;
            sinal         : IN  STD_LOGIC;
            erro          : IN  STD_LOGIC;
            display0      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display1      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display2      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            display3      : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            db_estado     : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
            pronto        : OUT STD_LOGIC;
            fim           : OUT STD_LOGIC;
            db_clock      : OUT STD_LOGIC;
            db_sinal      : OUT STD_LOGIC;
            db_zeraCont   : OUT STD_LOGIC;
            db_contaCont  : OUT STD_LOGIC;
            db_valorCont0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            db_valorCont1 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            db_valorCont2 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            db_valorCont3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
        );
    END COMPONENT;

    COMPONENT hex7seg IS
        PORT (
            hex     : IN  STD_LOGIC_VECTOR(3 DOWNTO 0);
            display : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL iniciar_int       : STD_LOGIC;
    SIGNAL sel_j2            : STD_LOGIC;
    SIGNAL salva_j1          : STD_LOGIC;
    SIGNAL salva_j2          : STD_LOGIC;
    SIGNAL mostra_resultado  : STD_LOGIC;

    SIGNAL estimulo_int          : STD_LOGIC;
    SIGNAL pulso_int             : STD_LOGIC;
    SIGNAL erro_int               : STD_LOGIC;
    SIGNAL pronto_interface_int   : STD_LOGIC;
    -- agora usamos entrada única `resposta` em vez de resposta_j1/resposta_j2

    SIGNAL pronto_medidor_int : STD_LOGIC;
    SIGNAL q0_m, q1_m, q2_m, q3_m : STD_LOGIC_VECTOR(3 DOWNTO 0);

    SIGNAL tempo_j1  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tempo_j2  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tempo_min : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tempo_atual  : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL tempo_winner : STD_LOGIC_VECTOR(15 DOWNTO 0);
    SIGNAL j1_vence : STD_LOGIC;

    SIGNAL disp0_med, disp1_med, disp2_med, disp3_med : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL disp0_min, disp1_min, disp2_min, disp3_min : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL disp0_win, disp1_win, disp2_win, disp3_win : STD_LOGIC_VECTOR(6 DOWNTO 0);

BEGIN

    -- resposta é fornecida externamente e refere-se ao botão do jogador ativo
    tempo_atual <= q3_m & q2_m & q1_m & q0_m;
    j1_vence     <= '1' WHEN unsigned(tempo_j1) <= unsigned(tempo_j2) ELSE '0';
    tempo_winner <= tempo_j1 WHEN j1_vence = '1' ELSE tempo_j2;

    PROCESS (clock, reset)
    BEGIN
        IF reset = '1' THEN
            tempo_j1  <= x"9999";
            tempo_j2  <= x"9999";
            tempo_min <= x"9999";
        ELSIF rising_edge(clock) THEN
            IF salva_j1 = '1' THEN
                tempo_j1 <= tempo_atual;
                IF unsigned(tempo_atual) < unsigned(tempo_min) THEN
                    tempo_min <= tempo_atual;
                END IF;
            END IF;
            IF salva_j2 = '1' THEN
                tempo_j2 <= tempo_atual;
                IF unsigned(tempo_atual) < unsigned(tempo_min) THEN
                    tempo_min <= tempo_atual;
                END IF;
            END IF;
        END IF;
    END PROCESS;

    display0 <= disp0_min WHEN show_min = '1' ELSE
                disp0_win WHEN mostra_resultado = '1' ELSE
                disp0_med;
    display1 <= disp1_min WHEN show_min = '1' ELSE
                disp1_win WHEN mostra_resultado = '1' ELSE
                disp1_med;
    display2 <= disp2_min WHEN show_min = '1' ELSE
                disp2_win WHEN mostra_resultado = '1' ELSE
                disp2_med;
    display3 <= disp3_min WHEN show_min = '1' ELSE
                disp3_win WHEN mostra_resultado = '1' ELSE
                disp3_med;

    display4 <= "1111111" WHEN mostra_resultado = '0' ELSE
                "1111001" WHEN j1_vence = '1' ELSE
                "0100100";

    ligado   <= iniciar_int;
    pulso    <= pulso_int;
    estimulo <= estimulo_int;
    erro     <= erro_int;

    U1 : interface_leds_botoes
    PORT MAP (
        clock             => clock,
        reset             => reset,
        iniciar           => iniciar_int,
        resposta          => resposta,
        ligado            => OPEN,
        estimulo          => estimulo_int,
        pulso             => pulso_int,
        pulso_scope       => OPEN,
        erro              => erro_int,
        pronto            => pronto_interface_int,
        burlou_assinc     => OPEN,
        db_estado_display => OPEN
    );

    U2 : medidor_largura
    PORT MAP (
        clock         => clock,
        reset         => reset,
        liga          => iniciar_int,
        sinal         => pulso_int,
        erro          => erro_int,
        display0      => disp0_med,
        display1      => disp1_med,
        display2      => disp2_med,
        display3      => disp3_med,
        db_estado     => OPEN,
        pronto        => pronto_medidor_int,
        fim           => OPEN,
        db_clock      => OPEN,
        db_sinal      => OPEN,
        db_zeraCont   => OPEN,
        db_contaCont  => OPEN,
        db_valorCont0 => q0_m,
        db_valorCont1 => q1_m,
        db_valorCont2 => q2_m,
        db_valorCont3 => q3_m
    );

    U3 : jogo_tempo_reacao_uc
    GENERIC MAP (
        PAUSA_J2_CYCLES => PAUSA_J2_CYCLES
    )
    PORT MAP (
        clock            => clock,
        reset            => reset,
        jogar            => jogar,
        estimulo         => estimulo_int,
        erro_interface   => erro_int,
        pronto_medidor   => pronto_medidor_int,
        pronto_interface => pronto_interface_int,
        iniciar          => iniciar_int,
        sel_j2           => sel_j2,
        salva_j1         => salva_j1,
        salva_j2         => salva_j2,
        pronto           => pronto,
        mostra_resultado => mostra_resultado,
        db_estado        => OPEN
    );

    min_d0 : hex7seg PORT MAP (hex => tempo_min(3  DOWNTO 0),  display => disp0_min);
    min_d1 : hex7seg PORT MAP (hex => tempo_min(7  DOWNTO 4),  display => disp1_min);
    min_d2 : hex7seg PORT MAP (hex => tempo_min(11 DOWNTO 8),  display => disp2_min);
    min_d3 : hex7seg PORT MAP (hex => tempo_min(15 DOWNTO 12), display => disp3_min);

    win_d0 : hex7seg PORT MAP (hex => tempo_winner(3  DOWNTO 0),  display => disp0_win);
    win_d1 : hex7seg PORT MAP (hex => tempo_winner(7  DOWNTO 4),  display => disp1_win);
    win_d2 : hex7seg PORT MAP (hex => tempo_winner(11 DOWNTO 8),  display => disp2_win);
    win_d3 : hex7seg PORT MAP (hex => tempo_winner(15 DOWNTO 12), display => disp3_win);

END ARCHITECTURE behavioral;
