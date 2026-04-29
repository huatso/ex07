LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

-- =============================================================
-- Testbench: interface_leds_botoes
-- Exercita reset, rodada normal, resposta antecipada e recuperacao.
-- =============================================================

ENTITY interface_leds_botoes_tb IS
END ENTITY;

ARCHITECTURE tb OF interface_leds_botoes_tb IS

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

    CONSTANT T : TIME := 10 ns;

    SIGNAL clock_in         : STD_LOGIC := '0';
    SIGNAL reset_in         : STD_LOGIC := '0';
    SIGNAL iniciar_in       : STD_LOGIC := '0';
    SIGNAL resposta_in      : STD_LOGIC := '0';

    SIGNAL ligado_s         : STD_LOGIC;
    SIGNAL estimulo_s       : STD_LOGIC;
    SIGNAL pulso_s          : STD_LOGIC;
    SIGNAL pulso_scope_s    : STD_LOGIC;
    SIGNAL erro_s           : STD_LOGIC;
    SIGNAL pronto_s         : STD_LOGIC;
    SIGNAL burlou_assinc_s  : STD_LOGIC;
    SIGNAL db_estado_s      : STD_LOGIC_VECTOR(6 DOWNTO 0);

BEGIN

    clock_in <= NOT clock_in AFTER T / 2;

    dut : interface_leds_botoes
    PORT MAP (
        clock             => clock_in,
        reset             => reset_in,
        iniciar           => iniciar_in,
        resposta          => resposta_in,
        ligado            => ligado_s,
        estimulo          => estimulo_s,
        pulso             => pulso_s,
        pulso_scope       => pulso_scope_s,
        erro              => erro_s,
        pronto            => pronto_s,
        burlou_assinc     => burlou_assinc_s,
        db_estado_display => db_estado_s
    );

    stimulus : PROCESS

        PROCEDURE aplica_reset IS
        BEGIN
            reset_in <= '1';
            iniciar_in <= '0';
            resposta_in <= '0';
            WAIT FOR 3 * T;
            reset_in <= '0';
            WAIT FOR 2 * T;
        END PROCEDURE;

        PROCEDURE inicia_rodada IS
        BEGIN
            iniciar_in <= '1';
            WAIT FOR T;
            iniciar_in <= '0';
        END PROCEDURE;

        PROCEDURE pulsa_resposta IS
        BEGIN
            resposta_in <= '1';
            WAIT FOR T;
            resposta_in <= '0';
        END PROCEDURE;

    BEGIN
        ASSERT false REPORT "TB interface_leds_botoes: inicio" SEVERITY note;

        -- Caso 0: reset inicial
        aplica_reset;
        ASSERT ligado_s = '0' REPORT "reset: ligado deveria ser 0" SEVERITY error;
        ASSERT estimulo_s = '0' REPORT "reset: estimulo deveria ser 0" SEVERITY error;
        ASSERT pulso_s = '0' REPORT "reset: pulso deveria ser 0" SEVERITY error;
        ASSERT pulso_scope_s = '0' REPORT "reset: pulso_scope deveria ser 0" SEVERITY error;
        ASSERT erro_s = '0' REPORT "reset: erro deveria ser 0" SEVERITY error;
        ASSERT pronto_s = '0' REPORT "reset: pronto deveria ser 0" SEVERITY error;
        ASSERT burlou_assinc_s = '0' REPORT "reset: burlou_assinc deveria ser 0" SEVERITY error;

        -- Caso 1: rodada normal
        ASSERT false REPORT "Caso 1: rodada normal" SEVERITY note;
        inicia_rodada;
        WAIT UNTIL ligado_s = '1';
        WAIT UNTIL estimulo_s = '1';
        WAIT FOR T / 4;

        ASSERT pulso_s = '1' REPORT "rodada normal: pulso deveria seguir estimulo" SEVERITY error;
        ASSERT pulso_scope_s = '1' REPORT "rodada normal: pulso_scope deveria seguir estimulo" SEVERITY error;
        ASSERT erro_s = '0' REPORT "rodada normal: erro deveria permanecer 0" SEVERITY error;

        pulsa_resposta;
        WAIT UNTIL pronto_s = '1';
        WAIT FOR T;

        ASSERT pronto_s = '1' REPORT "rodada normal: pronto deveria ficar 1" SEVERITY error;
        ASSERT erro_s = '0' REPORT "rodada normal: erro deveria continuar 0" SEVERITY error;

        -- Caso 2: resposta antecipada gera burla
        ASSERT false REPORT "Caso 2: resposta antecipada" SEVERITY note;
        aplica_reset;
        inicia_rodada;
        WAIT UNTIL ligado_s = '1';
        WAIT FOR T;

        ASSERT estimulo_s = '0' REPORT "antes do estimulo: estimulo deveria ser 0" SEVERITY error;
        pulsa_resposta;
        WAIT FOR 2 * T;

        ASSERT erro_s = '1' REPORT "burla: erro deveria ser 1" SEVERITY error;
        ASSERT burlou_assinc_s = '1' REPORT "burla: burlou_assinc deveria ser 1" SEVERITY error;
        ASSERT pronto_s = '0' REPORT "burla: pronto deveria permanecer 0" SEVERITY error;
        ASSERT ligado_s = '0' REPORT "burla: ligado deveria cair para 0" SEVERITY error;

        -- Caso 3: reset recupera o sistema apos burla
        ASSERT false REPORT "Caso 3: reset apos burla" SEVERITY note;
        aplica_reset;
        ASSERT erro_s = '0' REPORT "reset apos burla: erro deveria voltar a 0" SEVERITY error;
        ASSERT burlou_assinc_s = '0' REPORT "reset apos burla: burlou_assinc deveria voltar a 0" SEVERITY error;
        ASSERT pronto_s = '0' REPORT "reset apos burla: pronto deveria voltar a 0" SEVERITY error;
        ASSERT ligado_s = '0' REPORT "reset apos burla: ligado deveria voltar a 0" SEVERITY error;

        ASSERT false REPORT "TB interface_leds_botoes: fim sem erros" SEVERITY note;
        WAIT;
    END PROCESS;

END ARCHITECTURE tb;