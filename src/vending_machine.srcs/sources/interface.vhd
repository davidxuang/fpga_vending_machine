library IEEE;
use IEEE.std_logic_1164.all;

entity interface is
    generic (
        BTN_NUM  : integer range 1 to 6  := 5;
        SW_NUM   : integer range 1 to 16 := 5;
        FLAG_SIM : boolean               := true -- set to true before simulation
    );
    port (
        CLK                 : in std_logic;
        CPU_RESETN          : in std_logic;
        BTN                 : in std_logic_vector(BTN_NUM - 1 downto 0);
        SW                  : in std_logic_vector(SW_NUM - 1 downto 0);
        LED                 : out std_logic_vector(16 - 1 downto 0);
        VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
        VGA_HS, VGA_VS      : out std_logic
    );
end interface;

architecture behavioral of interface is

    -- Overall clocking
    component ip_clk
        port (
            CLK_VEN : out std_logic;
            CLK_VGA : out std_logic;
            CLK_EXC : out std_logic;
            CLK_IN  : in std_logic
        );
    end component;

    -- Frequency divider
    component frequency_divider
        generic (
            DEPTH : positive
        );
        port (
            CLK_IN  : in std_logic;
            CLK_OUT : out std_logic
        );
    end component;

    signal clk_ven : std_logic; --       100.00 MHz aligned
    signal clk_vga : std_logic; --        75.00 MHz aligned
    signal clk_exc : std_logic; --        25.00 MHz aligned
    signal clk_dbc : std_logic := '0'; -- ~6.12 kHz
    signal clk_blk : std_logic := '0'; -- ~1.49  Hz

    -- Button and switch debouncer
    component debouncer
        generic (
            SIG_WIDTH : positive;
            DEPTH     : positive
        );
        port (
            CLK_IN  : in std_logic;
            SIG_IN  : in std_logic_vector(SIG_WIDTH - 1 downto 0);
            SIG_OUT : buffer std_logic_vector(SIG_WIDTH - 1 downto 0)
        );
    end component;

    signal dbc_in  : std_logic_vector(BTN_NUM + SW_NUM - 1 downto 0);
    signal dbc_out : std_logic_vector(BTN_NUM + SW_NUM - 1 downto 0) := (others => '0');
    signal btn_dbc : std_logic_vector(BTN_NUM - 1 downto 0)          := (others => '0');
    signal sw_dbc  : std_logic_vector(SW_NUM - 1 downto 0)           := (others => '0');

    -- Vending module
    component vending
        generic (
            BTN_NUM : integer range 1 to 6  := 5;
            SW_NUM  : integer range 1 to 16 := 5
        );
        port (
            CLK_VEN           : in std_logic;
            CLK_BLK           : in std_logic;
            CPU_RESETN        : in std_logic;
            BTN               : in std_logic_vector(BTN_NUM - 1 downto 0);
            SW                : in std_logic_vector(SW_NUM - 1 downto 0);
            LED               : out std_logic_vector(16 - 1 downto 0);
            DISP_BLK          : out std_logic;
            DISP_QTY_INDEX    : in integer range 0 to 15;
            DISP_QTY          : out integer range 0 to 3;
            DISP_AMOUNT_INDEX : in integer range 0 to 3;
            DISP_AMOUNT       : out integer range 0 to 127;
            DISP_SEL          : out integer range 0 to 15
        );
    end component;

    -- Display module
    component display
        port (
            CLK_VGA             : in std_logic;
            VGA_R, VGA_G, VGA_B : out std_logic_vector(3 downto 0);
            VGA_HS, VGA_VS      : out std_logic;
            QTY_INDEX           : out integer range 0 to 15;
            QTY                 : in integer range 0 to 3;
            AMOUNT_INDEX        : out integer range 0 to 3;
            AMOUNT              : in integer range 0 to 127;
            BLK                 : in std_logic;
            SEL                 : in integer range 0 to 15
        );
    end component;

    -- Vending-display exchange
    signal disp_blk_flag     : std_logic;
    signal disp_qty_index    : integer range 0 to 15;
    signal disp_qty          : integer range 0 to 3;
    signal disp_amount_index : integer range 0 to 3;
    signal disp_amount       : integer range 0 to 127;
    signal disp_sel          : integer range 0 to 15;

    signal disp_blk_buf          : std_logic              := '1';
    signal disp_qty_index_buf    : integer range 0 to 15  := 0;
    signal disp_qty_buf          : integer range 0 to 3   := 0;
    signal disp_amount_index_buf : integer range 0 to 3   := 0;
    signal disp_amount_buf       : integer range 0 to 127 := 0;
    signal disp_sel_buf          : integer range 0 to 15  := 0;

    -- Simulation setup
    function setup_dly_depth(flag : boolean)
        return positive is
    begin
        if flag then
            return 1;
        else
            return 6;
        end if;
    end function;
    function setup_clk_dbc_depth(flag : boolean)
        return positive is
    begin
        if flag then
            return 1;
        else
            return 12;
        end if;
    end function;
    function setup_clk_blk_depth(flag : boolean)
        return positive is
    begin
        if flag then
            return 3;
        else
            return 12;
        end if;
    end function;

begin

    -- Overall clocking
    inst_clk : ip_clk
    port map(
        CLK_VEN => clk_ven,
        CLK_VGA => clk_vga,
        CLK_EXC => clk_exc,
        CLK_IN  => CLK
    );

    -- Frequency divider for debouncer
    inst_clk_dbc : frequency_divider
    generic map(DEPTH => setup_clk_dbc_depth(FLAG_SIM))
    port map(
        CLK_IN  => clk_exc,
        CLK_OUT => clk_dbc
    );

    -- Frequency divider for blink
    inst_clk_blk : frequency_divider
    generic map(DEPTH => setup_clk_blk_depth(FLAG_SIM))
    port map(
        CLK_IN  => clk_dbc,
        CLK_OUT => clk_blk
    );

    -- Button and switch debouncer (~10.5 ms delay)
    inst_dbc : debouncer
    generic map(
        SIG_WIDTH => BTN_NUM + SW_NUM,
        DEPTH     => setup_dly_depth(FLAG_SIM)
    )
    port map(
        CLK_IN  => clk_dbc,
        SIG_IN  => dbc_in,
        SIG_OUT => dbc_out
    );

    dbc_in  <= BTN & SW;
    btn_dbc <= dbc_out(SW_NUM + BTN_NUM - 1 downto SW_NUM);
    sw_dbc  <= dbc_out(SW_NUM - 1 downto 0);

    -- Vending module
    inst_vending : vending
    generic map(
        BTN_NUM => BTN_NUM,
        SW_NUM  => SW_NUM
    )
    port map(
        CLK_VEN           => clk_ven,
        CLK_BLK           => clk_blk,
        CPU_RESETN        => CPU_RESETN,
        BTN               => btn_dbc,
        SW                => sw_dbc,
        LED               => LED,
        DISP_BLK          => disp_blk_flag,
        DISP_QTY_INDEX    => disp_qty_index_buf,
        DISP_QTY          => disp_qty,
        DISP_AMOUNT_INDEX => disp_amount_index_buf,
        DISP_AMOUNT       => disp_amount,
        DISP_SEL          => disp_sel
    );

    -- Display module
    inst_display : display
    port map(
        CLK_VGA      => clk_vga,
        VGA_R        => VGA_R,
        VGA_G        => VGA_G,
        VGA_B        => VGA_B,
        VGA_HS       => VGA_HS,
        VGA_VS       => VGA_VS,
        BLK          => disp_blk_buf,
        QTY_INDEX    => disp_qty_index,
        QTY          => disp_qty_buf,
        AMOUNT_INDEX => disp_amount_index,
        AMOUNT       => disp_amount_buf,
        SEL          => disp_sel_buf
    );

    -- Vending-display exchange
    process (clk_exc)
    begin
        if rising_edge(clk_exc) then
            disp_blk_buf          <= disp_blk_flag or clk_blk;
            disp_qty_index_buf    <= disp_qty_index;
            disp_qty_buf          <= disp_qty;
            disp_amount_index_buf <= disp_amount_index;
            disp_amount_buf       <= disp_amount;
            disp_sel_buf          <= disp_sel;
        end if;
    end process;

end behavioral;