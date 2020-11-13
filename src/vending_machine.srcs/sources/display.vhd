library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity display is
    port (
        CLK_VGA             : in std_logic;
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS      : out std_logic;
        BLK                 : in std_logic;
        QTY_INDEX           : out integer range 0 to 15;
        QTY                 : in integer range 0 to 3;
        AMOUNT_INDEX        : out integer range 0 to 3;
        AMOUNT              : in integer range 0 to 127;
        SEL                 : in integer range 0 to 15
    );
end display;

architecture behavioral of display is

    -- VGA Signal module
    component vga
        port (
            CLK_PIX             : in std_logic;
            RGB                 : in std_logic_vector(11 downto 0);
            HRT                 : out integer range 0 to 1663;
            VRT                 : out integer range 0 to 747;
            VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
            VGA_HS, VGA_VS      : out std_logic
        );
    end component;

    signal hrt : integer range 0 to 1663;
    signal vrt : integer range 0 to 747;
    signal rgb : std_logic_vector(11 downto 0);

    -- Layout regiesters
    signal grid_hrt_adv1 : integer range 0 to 199;
    signal grid_col_adv1 : integer range 0 to 3;
    signal grid_pos_adv1 : integer range -1 to 15;

    signal grid_hrt_adv2 : integer range 0 to 199;
    signal grid_col_adv2 : integer range 0 to 3;
    signal grid_pos_adv2 : integer range -1 to 15;

    signal grid_vrt : integer range 0 to 159;
    signal grid_row : integer range 0 to 3;

    -- Image storage
    component ip_bram_img_item
        port (
            clka  : in std_logic;
            addra : in std_logic_vector(16 downto 0);
            douta : out std_logic_vector(11 downto 0)
        );
    end component;

    signal img_item_addr_adv1 : std_logic_vector(16 downto 0);
    signal img_item_dout      : std_logic_vector(11 downto 0);

    signal flag_img_item_adv1 : boolean;
    signal flag_img_item      : boolean := false;

    -- Glyph storage (18x40, 18x36 original)
    component ip_bram_char40
        port (
            clka  : in std_logic;
            addra : in std_logic_vector(12 downto 0);
            douta : out std_logic_vector(11 downto 0)
        );
    end component;

    signal char40_addr_adv1 : std_logic_vector(12 downto 0);
    signal char40_dout      : std_logic_vector(11 downto 0);

    signal price_dec1         : integer range 0 to 1;
    signal price_dec0         : integer range -1 to 9;
    signal char40_offset_adv1 : integer range 0 to 10;
    signal char40_hrt_adv1    : integer range 0 to 17;
    signal char40_vrt_adv1    : integer range 0 to 39;

    signal flag_char40_adv1 : boolean;
    signal flag_char40      : boolean := false;

    -- Glyph storage (27x54)
    component ip_bram_char54
        port (
            clka  : in std_logic;
            addra : in std_logic_vector(13 downto 0);
            douta : out std_logic_vector(11 downto 0)
        );
    end component;

    signal char54_addr_adv1 : std_logic_vector(13 downto 0);
    signal char54_dout      : std_logic_vector(11 downto 0);

    type amount_t is array (2 downto 0) of integer range 0 to 10;
    signal amount_dec         : amount_t;
    signal char54_offset_adv1 : integer range 0 to 9;
    signal char54_hrt_adv1    : integer range 0 to 26;

    signal flag_char54_adv1 : boolean;
    signal flag_char54      : boolean := false;

    -- Glyph storage (54x54)
    component ip_bram_char54_cjk
        port (
            clka  : in std_logic;
            addra : in std_logic_vector(13 downto 0);
            douta : out std_logic_vector(11 downto 0)
        );
    end component;

    signal char54_cjk_addr_adv1 : std_logic_vector(13 downto 0);
    signal char54_cjk_dout      : std_logic_vector(11 downto 0);

    signal char54_cjk_offset_adv1 : integer range 0 to 4;
    signal char54_cjk_hrt_adv1    : integer range 0 to 53;

    signal flag_char54_cjk_adv1 : boolean;
    signal flag_char54_cjk      : boolean := false;

    -- Select hightlight
    signal flag_sel_adv1 : boolean;
    signal flag_sel      : boolean := false;

begin

    -- VGA Signal module
    inst_vga : vga
    port map(
        CLK_PIX => CLK_VGA,
        RGB     => rgb,
        VRT     => vrt,
        HRT     => hrt,
        VGA_R   => VGA_R,
        VGA_G   => VGA_G,
        VGA_B   => VGA_B,
        VGA_HS  => VGA_HS,
        VGA_VS  => VGA_VS
    );

    -- Layout registers
    process (CLK_VGA)
    begin
        if rising_edge(CLK_VGA) then
            grid_hrt_adv1 <= (hrt + 120 + 2) rem 200;
            grid_col_adv1 <= (hrt - 40 + 2) / 200 rem 4;
            grid_hrt_adv2 <= (hrt + 120 + 3) rem 200;
            grid_col_adv2 <= (hrt - 40 + 3) / 200 rem 4;
            grid_vrt      <= (vrt + 80) rem 160;
            grid_row      <= (vrt - 40) / 160 rem 4;
        end if;
    end process;

    grid_pos_adv1 <=
        grid_row * 4 + grid_col_adv1 when hrt + 1 >= 40 and hrt + 1 < 840 and vrt >= 40 and vrt < 680 else
        - 1;
    grid_pos_adv2 <=
        grid_row * 4 + grid_col_adv2 when hrt + 2 >= 40 and hrt + 2 < 840 and vrt >= 40 and vrt < 680 else
        - 1;

    -- Image storage
    inst_bram_img_item : ip_bram_img_item
    port map(
        clka  => CLK_VGA,
        addra => img_item_addr_adv1,
        douta => img_item_dout
    );

    flag_img_item_adv1 <= grid_hrt_adv1 < 80 and grid_vrt < 80 and hrt + 1 < 800;
    img_item_addr_adv1 <= std_logic_vector(to_unsigned((((grid_row * 4 + grid_col_adv1) * 80 + grid_vrt) * 80 + grid_hrt_adv1), 17));

    -- Glyph storage (18x40, 18x36 original)
    inst_bram_char40 : ip_bram_char40
    port map(
        clka  => CLK_VGA,
        addra => char40_addr_adv1,
        douta => char40_dout
    );

    price_dec1 <=
        1 when grid_pos_adv2 = 4 or grid_pos_adv2 = 10 else
        0;
    price_dec0 <=
        0 when grid_pos_adv2 = 4 else
        3 when grid_pos_adv2 = 0 or grid_pos_adv2 = 3 else
        4 when grid_pos_adv2 = 1 or grid_pos_adv2 = 8 or grid_pos_adv2 = 13 else
        5 when grid_pos_adv2 = 10 or grid_pos_adv2 = 14 or grid_pos_adv2 = 15 else
        6 when grid_pos_adv2 = 2 or grid_pos_adv2 = 9 else
        7 when grid_pos_adv2 = 7 else
        8 when grid_pos_adv2 = 5 or grid_pos_adv2 = 11 else
        9;

    process (CLK_VGA)
    begin
        if rising_edge(CLK_VGA) then
            if grid_vrt < 40 then
                if (grid_hrt_adv2 < 102) then
                    char40_offset_adv1 <= price_dec1;
                else
                    char40_offset_adv1 <= price_dec0;
                end if;
            elsif grid_hrt_adv2 < 102 then
                char40_offset_adv1 <= 10;
            else
                char40_offset_adv1 <= QTY;
            end if;
            char40_hrt_adv1 <= (grid_hrt_adv2 + 6) rem 18;
            char40_vrt_adv1 <= vrt rem 40;
        end if;
    end process;

    flag_char40_adv1 <= grid_hrt_adv1 >= 84 and grid_hrt_adv1 < 120 and grid_vrt < 80 and hrt + 2 < 800 and BLK = '1' and not(grid_vrt >= 40 and QTY = 0);
    char40_addr_adv1 <= std_logic_vector(to_unsigned((char40_offset_adv1 * 40 + char40_vrt_adv1) * 18 + char40_hrt_adv1, 13));

    -- Glyph storage (27x54)
    inst_bram_char54 : ip_bram_char54
    port map(
        clka  => CLK_VGA,
        addra => char54_addr_adv1,
        douta => char54_dout
    );

    amount_dec(2) <= AMOUNT / 100;
    amount_dec(1) <= AMOUNT / 10 rem 10;
    amount_dec(0) <= AMOUNT rem 10;

    process (CLK_VGA)
    begin
        if rising_edge(CLK_VGA) then
            if hrt + 2 < 1146 then
                char54_offset_adv1 <= amount_dec(2);
            elsif hrt + 2 < 1173 then
                char54_offset_adv1 <= amount_dec(1);
            else
                char54_offset_adv1 <= amount_dec(0);
            end if;
            char54_hrt_adv1 <= (hrt + 2 + 15) rem 27;
        end if;
    end process;

    flag_char54_adv1 <= hrt + 1 >= 1119 and hrt + 1 < 1200 and grid_vrt < 54 and AMOUNT /= 0;
    char54_addr_adv1 <= std_logic_vector(to_unsigned((char54_offset_adv1 * 54 + grid_vrt) * 27 + char54_hrt_adv1, 14));

    -- Glyph storage (54x54)
    inst_bram_char54_cjk : ip_bram_char54_cjk
    port map(
        clka  => CLK_VGA,
        addra => char54_cjk_addr_adv1,
        douta => char54_cjk_dout
    );

    process (CLK_VGA)
    begin
        if rising_edge(CLK_VGA) then
            if hrt + 2 < 1014 then
                case grid_row is
                    when 0 =>
                        char54_cjk_offset_adv1 <= 2;
                    when 1 =>
                        char54_cjk_offset_adv1 <= 1;
                    when others =>
                        char54_cjk_offset_adv1 <= 3;
                end case;
            else
                if grid_row = 2 then
                    char54_cjk_offset_adv1 <= 4;
                else
                    char54_cjk_offset_adv1 <= 0;
                end if;
            end if;
        end if;
        char54_cjk_hrt_adv1 <= (hrt + 2 + 12) rem 54;
    end process;

    flag_char54_cjk_adv1 <= hrt + 1 >= 960 and hrt + 1 < 1068 and grid_vrt < 54 and AMOUNT /= 0;
    char54_cjk_addr_adv1 <= std_logic_vector(to_unsigned((char54_cjk_offset_adv1 * 54 + grid_vrt) * 54 + char54_cjk_hrt_adv1, 14));

    -- Select hightlight
    flag_sel_adv1 <= (grid_hrt_adv1 < 84 or grid_hrt_adv1 >= 196) and (grid_vrt < 84 or grid_vrt >= 156) and grid_pos_adv1 = SEL;

    process (CLK_VGA)
    begin
        if rising_edge(CLK_VGA) then
            flag_img_item   <= flag_img_item_adv1;
            flag_char40     <= flag_char40_adv1;
            flag_char54     <= flag_char54_adv1;
            flag_char54_cjk <= flag_char54_cjk_adv1;
            flag_sel        <= flag_sel_adv1;
        end if;
    end process;

    -- Render top-down
    RGB <=
        img_item_dout when flag_img_item else
        char40_dout when flag_char40 else
        char54_dout when flag_char54 else
        char54_cjk_dout when flag_char54_cjk else
        x"14A" when flag_sel and BLK = '1' else
        x"BDF" when hrt < 880 else
        x"FFB";

    -- Assign outputs
    QTY_INDEX    <= grid_row * 4 + grid_col_adv2;
    AMOUNT_INDEX <= grid_row;

end behavioral;