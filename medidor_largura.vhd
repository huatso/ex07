LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY medidor_largura IS
    PORT (
        clock : IN STD_LOGIC;
        reset : IN STD_LOGIC;
        liga : IN STD_LOGIC;
        sinal : IN STD_LOGIC;
        erro : IN STD_LOGIC;
        display0 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        display1 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        display2 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        display3 : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        db_estado : OUT STD_LOGIC_VECTOR(6 DOWNTO 0);
        pronto : OUT STD_LOGIC;
        fim : OUT STD_LOGIC;
        db_clock : OUT STD_LOGIC;
        db_sinal : OUT STD_LOGIC;
        db_zeraCont : OUT STD_LOGIC;
        db_contaCont : OUT STD_LOGIC;
        db_valorCont0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        db_valorCont1 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        db_valorCont2 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
        db_valorCont3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
    );
END ENTITY medidor_largura;

ARCHITECTURE arch OF medidor_largura IS
    COMPONENT medidor_largura_uc IS
        PORT (
            clock : IN STD_LOGIC;
            reset : IN STD_LOGIC;
            liga : IN STD_LOGIC;
            sinal : IN STD_LOGIC;
            rco : IN STD_LOGIC;
            pronto : OUT STD_LOGIC;
            zeraCont : OUT STD_LOGIC;
            contaCont : OUT STD_LOGIC;
            db_estado : OUT STD_LOGIC_VECTOR(3 DOWNTO 0) --sinais de depuraçao
        );
    END COMPONENT;

    COMPONENT cont10_4digitos IS
        PORT (
            clock : IN STD_LOGIC;
            clear : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            Q0 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            Q1 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            Q2 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            Q3 : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            RCO : OUT STD_LOGIC
        );
    END COMPONENT;
    COMPONENT hex7seg IS
        PORT (
            hex : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
            display : OUT STD_LOGIC_VECTOR(6 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL Q0, Q1, Q2, Q3, estado : STD_LOGIC_VECTOR(3 DOWNTO 0);
    SIGNAL zeraCont, contaCont, rco : STD_LOGIC;
    SIGNAL display0_interno_meio, display1_interno_meio, display2_interno_meio, display3_interno_meio : STD_LOGIC_VECTOR(6 DOWNTO 0);
    SIGNAL display0_interno, display1_interno, display2_interno, display3_interno : STD_LOGIC_VECTOR(6 DOWNTO 0);
BEGIN
    db_sinal <= sinal;
    db_clock <= clock;
    db_zeraCont <= zeraCont;
    db_contaCont <= contaCont;
    fim <= rco;
    display0 <= display0_interno;
    display1 <= display1_interno;
    display2 <= display2_interno;
    display3 <= display3_interno;

    control : medidor_largura_uc
    PORT MAP(
        clock => clock,
        reset => reset,
        liga => liga,
        sinal => sinal,
        rco => rco,
        pronto => pronto,
        zeraCont => zeraCont,
        contaCont => contaCont,
        db_estado => estado
    );

    cont10 : cont10_4digitos
    PORT MAP(
        clock => clock,
        clear => zeraCont,
        enable => contaCont,
        Q0 => Q0,
        Q1 => Q1,
        Q2 => Q2,
        Q3 => Q3,
        RCO => rco
    );
    disp0 : hex7seg
    PORT MAP(
        hex => Q0,
        display => display0_interno_meio
    );
    disp1 : hex7seg
    PORT MAP(
        hex => Q1,
        display => display1_interno_meio
    );
    disp2 : hex7seg
    PORT MAP(
        hex => Q2,
        display => display2_interno_meio
    );
    disp3 : hex7seg
    PORT MAP(
        hex => Q3,
        display => display3_interno_meio
    );
    disp5 : hex7seg
    PORT MAP(
        hex => estado,
        display => db_estado
    );

display0_interno <= "0010000" WHEN erro = '1' ELSE display0_interno_meio;
display1_interno <= "0010000" WHEN erro = '1' ELSE display1_interno_meio;
display2_interno <= "0010000" WHEN erro = '1' ELSE display2_interno_meio;
display3_interno <= "0010000" WHEN erro = '1' ELSE display3_interno_meio;

db_valorCont0 <= "1001" WHEN erro = '1' ELSE Q0;
db_valorCont1 <= "1001" WHEN erro = '1' ELSE Q1;
db_valorCont2 <= "1001" WHEN erro = '1' ELSE Q2;
db_valorCont3 <= "1001" WHEN erro = '1' ELSE Q3;

END ARCHITECTURE;