library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity debouncer is
    generic (
        SIG_WIDTH : positive;
        DEPTH     : positive := 10
    );
    port (
        CLK_IN  : in std_logic;
        SIG_IN  : in std_logic_vector(SIG_WIDTH - 1 downto 0);
        SIG_OUT : buffer std_logic_vector(SIG_WIDTH - 1 downto 0)
    );
end debouncer;

architecture behavioral of debouncer is

    type cnt_array_t is array (SIG_WIDTH - 1 downto 0) of unsigned(DEPTH - 1 downto 0);
    signal cnt_array : cnt_array_t                  := (others => (others => '0'));
    constant cnt_max : unsigned(DEPTH - 1 downto 0) := (others => '1');

begin

    process (CLK_IN)
    begin
        if (rising_edge(CLK_IN)) then
            for index in 0 to SIG_WIDTH - 1 loop
                if ((SIG_OUT(index) = '1') xor (SIG_IN(index) = '1')) then
                    cnt_array(index) <= cnt_array(index) + 1;
                else
                    cnt_array(index) <= (others => '0');
                end if;
                if cnt_array(index) = cnt_max then
                    SIG_OUT(index) <= not SIG_OUT(index);
                end if;
            end loop;
        end if;
    end process;

end behavioral;