LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY cont10_4digitos IS
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
END ENTITY cont10_4digitos;

ARCHITECTURE cont10_4 OF cont10_4digitos IS
    COMPONENT cont10 IS
        PORT (
            clock : IN STD_LOGIC;
            clear : IN STD_LOGIC;
            enable : IN STD_LOGIC;
            Q : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
            RCO : OUT STD_LOGIC
        );
    END COMPONENT;
    SIGNAL rco_sig0, rco_sig1, rco_sig2, rco_sig3 : STD_LOGIC;
    SIGNAL enable0, enable1, enable2, enable3 : STD_LOGIC;
BEGIN
    enable0 <= enable;
    enable1 <= rco_sig0 AND enable;
    enable2 <= rco_sig0 AND rco_sig1 AND enable;
    enable3 <= rco_sig0 AND rco_sig1 AND rco_sig2 AND enable;

    dig0 : cont10
    PORT MAP(
        clock => clock,
        clear => clear,
        enable => enable0,
        Q => Q0,
        RCO => rco_sig0
    );
    dig1 : cont10
    PORT MAP(
        clock => clock,
        clear => clear,
        enable => enable1,
        Q => Q1,
        RCO => rco_sig1
    );
    dig2 : cont10
    PORT MAP(
        clock => clock,
        clear => clear,
        enable => enable2,
        Q => Q2,
        RCO => rco_sig2
    );
    dig3 : cont10
    PORT MAP(
        clock => clock,
        clear => clear,
        enable => enable3,
        Q => Q3,
        RCO => rco_sig3
    );
    RCO <= rco_sig0 AND rco_sig1 AND rco_sig2 AND rco_sig3;
END ARCHITECTURE cont10_4;