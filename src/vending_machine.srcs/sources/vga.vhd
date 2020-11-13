library IEEE;
use IEEE.std_logic_1164.all;

entity vga is
    port (
        CLK_PIX             : in std_logic;
        RGB                 : in std_logic_vector(11 downto 0);
        HRT                 : out integer range 0 to 1663;
        VRT                 : out integer range 0 to 747;
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS      : out std_logic
    );
end vga;

architecture behavioral of vga is

    -- 1280x720@60, CVR, target 74.5 MHz --
    constant h_frm  : natural   := 1280;
    constant h_fpor : natural   := 64;
    constant h_sync : natural   := 128;
    --       h_bpor : natural   := 192;
    constant h_num  : natural   := 1664;
    constant h_pol  : std_logic := '1';

    constant v_frm  : natural   := 720;
    constant v_fpor : natural   := 3;
    constant v_sync : natural   := 5;
    --       v_bpor : natural   := 20;
    constant v_num  : natural   := 748;
    constant v_pol  : std_logic := '1';

    signal in_frm : std_logic;

    signal h_cnt : integer range 0 to 2047 := 0;
    signal v_cnt : integer range 0 to 1023 := 0;

    signal h_syn : std_logic := not H_POL;
    signal v_syn : std_logic := not V_POL;

    signal vga_r_out : std_logic_vector(3 downto 0);
    signal vga_g_out : std_logic_vector(3 downto 0);
    signal vga_b_out : std_logic_vector(3 downto 0);

begin

    -- Horizental counter
    process (CLK_PIX)
    begin
        if rising_edge(CLK_PIX) then
            if (h_cnt = h_num - 1) then
                h_cnt <= 0;
            else
                h_cnt <= h_cnt + 1;
            end if;
        end if;
    end process;

    -- Vertical counter
    process (CLK_PIX)
    begin
        if (rising_edge(CLK_PIX)) then
            if (h_cnt = h_num - 1) then
                if (v_cnt = v_num - 1) then
                    v_cnt <= 0;
                else
                    v_cnt <= v_cnt + 1;
                end if;
            end if;
        end if;
    end process;

    -- Horizontal sync
    process (CLK_PIX)
    begin
        if rising_edge(CLK_PIX) then
            if (h_cnt >= h_frm + h_fpor - 1) and (h_cnt < h_frm + h_fpor + h_sync - 1) then
                h_syn <= h_pol;
            else
                h_syn <= not h_pol;
            end if;
        end if;
    end process;

    -- Vertical sync
    process (CLK_PIX)
    begin
        if rising_edge(CLK_PIX) then
            if (v_cnt >= v_frm + v_fpor - 1) and (v_cnt < v_frm + v_fpor + v_sync - 1) then
                v_syn <= v_pol;
            else
                v_syn <= not v_pol;
            end if;
        end if;
    end process;

    -- Blank area black-out
    in_frm <=
        '1' when (h_cnt < h_frm) and (v_cnt < v_frm) else
        '0';

    vga_r_out <= (in_frm & in_frm & in_frm & in_frm) and RGB(11 downto 8);
    vga_g_out <= (in_frm & in_frm & in_frm & in_frm) and RGB(7 downto 4);
    vga_b_out <= (in_frm & in_frm & in_frm & in_frm) and RGB(3 downto 0);

    -- Register outputs
    process (CLK_PIX)
    begin
        if rising_edge(CLK_PIX) then
            HRT    <= h_cnt;
            VRT    <= v_cnt;
            VGA_HS <= h_syn;
            VGA_VS <= v_syn;
            VGA_R  <= vga_r_out;
            VGA_G  <= vga_g_out;
            VGA_B  <= vga_b_out;
        end if;
    end process;

end behavioral;