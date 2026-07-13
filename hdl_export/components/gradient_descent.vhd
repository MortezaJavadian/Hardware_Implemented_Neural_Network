-- Single-Weight Update Unit for Gradient Descent.
--
-- This component computes exactly one fixed-point weight update:
--
--   error           = prediction - target_value
--   gradient        = (error * input_value) >> FRAC_BITS
--   scaled_gradient = gradient >> LEARNING_RATE_SHIFT
--   updated_weight  = saturate(current_weight - scaled_gradient)
--
-- All datapath inputs use signed fixed-point representation.
-- This component does NOT implement full network backpropagation.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity gradient_descent is
    generic (
        DATA_WIDTH          : positive := 16;
        FRAC_BITS           : natural  := 8;
        LEARNING_RATE_SHIFT : natural  := 4
    );
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        enable         : in  std_logic;

        prediction     : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        target_value   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        input_value    : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        current_weight : in  std_logic_vector(DATA_WIDTH - 1 downto 0);

        updated_weight : out std_logic_vector(DATA_WIDTH - 1 downto 0);
        done           : out std_logic
    );
end entity gradient_descent;

architecture rtl of gradient_descent is

    -- Error is DATA_WIDTH+1 bits.
    -- Multiplication width is:
    --   (DATA_WIDTH+1) + DATA_WIDTH
    constant WIDE_WIDTH_C : positive := (2 * DATA_WIDTH) + 1;

    constant MAX_WEIGHT_C : signed(DATA_WIDTH - 1 downto 0) :=
        to_signed(2**(DATA_WIDTH - 1) - 1, DATA_WIDTH);

    constant MIN_WEIGHT_C : signed(DATA_WIDTH - 1 downto 0) :=
        to_signed(-(2**(DATA_WIDTH - 1)), DATA_WIDTH);

begin

    assert FRAC_BITS < WIDE_WIDTH_C
        report "FRAC_BITS must be smaller than the internal datapath width"
        severity failure;

    assert LEARNING_RATE_SHIFT < WIDE_WIDTH_C
        report "LEARNING_RATE_SHIFT must be smaller than the internal datapath width"
        severity failure;

    process(clk, rst)
        variable error_v            : signed(DATA_WIDTH downto 0);
        variable product_v          : signed(WIDE_WIDTH_C - 1 downto 0);
        variable gradient_v         : signed(WIDE_WIDTH_C - 1 downto 0);
        variable scaled_gradient_v  : signed(WIDE_WIDTH_C - 1 downto 0);
        variable current_weight_v   : signed(WIDE_WIDTH_C - 1 downto 0);
        variable next_weight_v      : signed(WIDE_WIDTH_C - 1 downto 0);
        variable max_weight_v       : signed(WIDE_WIDTH_C - 1 downto 0);
        variable min_weight_v       : signed(WIDE_WIDTH_C - 1 downto 0);
    begin
        if rst = '1' then
            updated_weight <= (others => '0');
            done           <= '0';

        elsif rising_edge(clk) then
            done <= '0';

            if enable = '1' then
                error_v :=
                    resize(signed(prediction), DATA_WIDTH + 1) -
                    resize(signed(target_value), DATA_WIDTH + 1);

                product_v :=
                    error_v * signed(input_value);

                gradient_v :=
                    shift_right(product_v, FRAC_BITS);

                scaled_gradient_v :=
                    shift_right(gradient_v, LEARNING_RATE_SHIFT);

                current_weight_v :=
                    resize(signed(current_weight), WIDE_WIDTH_C);

                next_weight_v :=
                    current_weight_v - scaled_gradient_v;

                max_weight_v :=
                    resize(MAX_WEIGHT_C, WIDE_WIDTH_C);

                min_weight_v :=
                    resize(MIN_WEIGHT_C, WIDE_WIDTH_C);

                if next_weight_v > max_weight_v then
                    updated_weight <= std_logic_vector(MAX_WEIGHT_C);

                elsif next_weight_v < min_weight_v then
                    updated_weight <= std_logic_vector(MIN_WEIGHT_C);

                else
                    updated_weight <= std_logic_vector(
                        resize(next_weight_v, DATA_WIDTH)
                    );
                end if;

                done <= '1';
            end if;
        end if;
    end process;

end architecture rtl;
