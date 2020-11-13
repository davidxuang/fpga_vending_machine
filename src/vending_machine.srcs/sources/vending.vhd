library IEEE;
use IEEE.std_logic_1164.all;

entity vending is
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
end vending;

architecture behavioral of vending is

    -- Buttons and switches
    signal cpu_resetn_down : std_logic                              := '0';
    signal btn_down        : std_logic_vector(BTN_NUM - 1 downto 0) := (others => '0');
    signal sw_onoff        : std_logic_vector(SW_NUM - 1 downto 0)  := (others => '0');

    -- State transfer
    signal state       : integer range 0 to 3 := 0;
    signal txf_qty     : boolean; -- 0 => 1
    signal txf_qty_ok  : boolean; -- 1 => 0
    signal txf_qty_cxl : boolean; -- 1 => 0
    signal txf_out     : boolean; -- 0 => 2
    signal txf_out_ok  : boolean; -- 2 => 3
    signal txf_rst     : boolean; -- 0 => 3
    signal txf_chg_ok  : boolean; -- 3 => 0

    -- Item select
    type item_qty_array_t is array(15 downto 0) of integer range 0 to 3;
    signal item_qty_array   : item_qty_array_t      := (others => 0);
    constant item_qty_nul   : item_qty_array_t      := (others => 0);
    signal item_sel_nxt     : integer range 0 to 15 := 0;
    signal item_sel         : integer range 0 to 15 := 0;
    signal item_sel_qty_nxt : integer range 0 to 3;
    signal item_sel_cnt     : integer range 0 to 2 := 0;

    -- Amount calculation
    signal total  : integer range 0 to 127;
    signal cash   : integer range 0 to 127 := 0;
    signal change : integer range 0 to 127 := 0;

    -- Items out
    signal item_out : integer range -1 to 15 := - 1;

begin

    -- Buttons and switches
    process (CLK_VEN)
        variable btn_dly        : std_logic_vector(BTN_NUM - 1 downto 0) := (others => '0');
        variable sw_dly         : std_logic_vector(SW_NUM - 1 downto 0)  := (others => '0');
        variable cpu_resetn_dly : std_logic                              := '1';
    begin
        if rising_edge(CLK_VEN) then
            cpu_resetn_down <= cpu_resetn_dly and not CPU_RESETN;
            btn_down        <= BTN and not btn_dly;
            sw_onoff        <= SW xor sw_dly;

            cpu_resetn_dly := CPU_RESETN;
            btn_dly        := BTN;
            sw_dly         := SW;
        end if;
    end process;

    -- State transfer
    txf_qty     <= state = 0 and btn_down(0) = '1' and item_sel_cnt /= 2;
    txf_qty_ok  <= state = 1 and btn_down(0) = '1';
    txf_qty_cxl <= state = 1 and (btn_down(1) = '1' or btn_down(2) = '1');
    txf_out     <= state = 0 and total > 0 and cash >= total;
    txf_out_ok  <= state = 2 and item_qty_array = item_qty_nul;
    txf_rst     <= (state = 0 or state = 1) and cpu_resetn_down = '1';
    txf_chg_ok  <= state = 3 and change = 0;
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if txf_qty_ok or txf_qty_cxl or txf_chg_ok then
                state <= 0;
            elsif txf_qty then
                state <= 1;
            elsif txf_out then
                state <= 2;
            elsif txf_rst or txf_out_ok then
                state <= 3;
            end if;
        end if;
    end process;

    -- Select item (state 0)
    item_sel_nxt <=
        (item_sel + 15) mod 16 when btn_down(1) = '1' else
        (item_sel + 1) mod 16 when btn_down(2) = '1' else
        (item_sel + 12) mod 16 when btn_down(3) = '1' else
        (item_sel + 4) mod 16 when btn_down(4) = '1' else
        item_sel;
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if state = 0 then
                item_sel <= item_sel_nxt;
            end if;
        end if;
    end process;

    -- Select limit (state 0)
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if cpu_resetn_down = '1' or txf_chg_ok then
                item_sel_cnt <= 0;
            elsif txf_qty and item_qty_array(item_sel) > 0 then
                item_sel_cnt <= item_sel_cnt - 1;
            elsif txf_qty_ok then
                item_sel_cnt <= item_sel_cnt + 1;
            end if;
        end if;
    end process;

    -- Select quantity (state 1)
    item_sel_qty_nxt <=
        item_qty_array(item_sel) + 1 when item_qty_array(item_sel) < 3 and btn_down(3) = '1' else
        item_qty_array(item_sel) - 1 when item_qty_array(item_sel) > 1 and btn_down(4) = '1' else
        item_qty_array(item_sel);
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if txf_rst or txf_chg_ok then
                item_qty_array <= (others => 0);
            elsif txf_qty_cxl then
                item_qty_array(item_sel) <= 0; -- Set to 0 on cancel
            elsif state = 1 then
                if item_qty_array(item_sel) = 0 then
                    item_qty_array(item_sel) <= 1; -- Set to 1 on entry
                else
                    item_qty_array(item_sel) <= item_sel_qty_nxt;
                end if;
            elsif item_out >= 0 then
                item_qty_array(item_out) <= item_qty_array(item_out) - 1;
            end if;
        end if;
    end process;

    -- Cash in (state 0)
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if state = 0 and total > 0 then
                if sw_onoff(0) = '1' then
                    cash <= cash + 1;
                elsif sw_onoff(1) = '1' then
                    cash <= cash + 5;
                elsif sw_onoff(2) = '1' then
                    cash <= cash + 10;
                elsif sw_onoff(3) = '1' then
                    cash <= cash + 20;
                elsif sw_onoff(4) = '1' then
                    cash <= cash + 50;
                end if;
            end if;
            if txf_chg_ok then
                cash <= 0;
            end if;
        end if;
    end process;

    -- Total
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if state = 0 then
                total <=
                    3 * (item_qty_array(0) + item_qty_array(3)) +
                    4 * (item_qty_array(1) + item_qty_array(8) + item_qty_array(13)) +
                    5 * (item_qty_array(14) + item_qty_array(15)) +
                    6 * (item_qty_array(2) + item_qty_array(9)) +
                    7 * item_qty_array(7) +
                    8 * (item_qty_array(5) + item_qty_array(11)) +
                    9 * (item_qty_array(6) + item_qty_array(12)) +
                    10 * item_qty_array(4) +
                    15 * item_qty_array(10);
            elsif txf_rst then
                total <= 0;
            end if;
        end if;
    end process;

    -- Items out (state 2) and LED outputs
    process (CLK_VEN)
        variable clk_blk_dly : std_logic              := '0';
        variable blk_rise    : std_logic              := '0';
        variable led_out     : integer range -1 to 15 := - 1;
    begin
        if rising_edge(CLK_VEN) then
            blk_rise    := CLK_BLK and not clk_blk_dly;
            clk_blk_dly := CLK_BLK;

            if state = 2 and blk_rise = '1' then
                for index in 0 to 15 loop
                    if item_qty_array(index) > 0 then
                        item_out <= index;
                        led_out := index;
                        exit;
                    end if;
                end loop;
            else
                item_out <= - 1;
            end if;

            if clk_blk = '1' then
                LED(item_out) <= '1';
            else
                LED <= (others => '0');
                led_out := - 1;
            end if;
        end if;
    end process;

    -- Change out (state 3)
    process (CLK_VEN)
    begin
        if rising_edge(CLK_VEN) then
            if state = 3 and btn_down(0) = '1' then
                change <= change - 1;
            elsif txf_out_ok then
                change <= cash - total;
            elsif txf_rst then
                change <= cash;
            end if;
        end if;
    end process;

    -- Output data for display
    DISP_QTY    <= item_qty_array(DISP_QTY_INDEX);
    DISP_AMOUNT <=
        total when DISP_AMOUNT_INDEX = 0 else
        cash when DISP_AMOUNT_INDEX = 1 else
        change when DISP_AMOUNT_INDEX = 2 else
        0;
    DISP_BLK <=
        '0' when state = 1 and item_sel = DISP_QTY_INDEX else
        '1';
    DISP_SEL <= item_sel;

end behavioral;