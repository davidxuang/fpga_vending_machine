library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity frequency_divider is
    generic (
        DEPTH : positive
    );
    port (
        CLK_IN  : in std_logic;
        CLK_OUT : out std_logic
    );
end frequency_divider;

architecture behavioral of frequency_divider is

    signal cnt : unsigned(DEPTH - 1 downto 0);

begin

    process (CLK_IN)
    begin
        if rising_edge(CLK_IN) then
            cnt <= cnt + 1;
        end if;
    end process;

    CLK_OUT <= cnt(DEPTH - 1);

end behavioral;