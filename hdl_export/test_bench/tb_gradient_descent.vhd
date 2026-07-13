library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_gradient_descent is
end entity tb_gradient_descent;

architecture Behavioral of tb_gradient_descent is

    constant DATA_WIDTH_C          : positive := 16;
    constant FRAC_BITS_C           : natural  := 8;
    constant LEARNING_RATE_SHIFT_C : natural  := 4;
    constant CLK_PERIOD_C          : time     := 10 ns;

    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal enable         : std_logic := '0';

    signal prediction     : std_logic_vector(
        DATA_WIDTH_C - 1 downto 0
    ) := (others => '0');

    signal target_value   : std_logic_vector(
        DATA_WIDTH_C - 1 downto 0
    ) := (others => '0');

    signal input_value    : std_logic_vector(
        DATA_WIDTH_C - 1 downto 0
    ) := (others => '0');

    signal current_weight : std_logic_vector(
        DATA_WIDTH_C - 1 downto 0
    ) := (others => '0');

    signal updated_weight : std_logic_vector(
        DATA_WIDTH_C - 1 downto 0
    );

    signal done : std_logic;

begin

    clk <= not clk after CLK_PERIOD_C / 2;

    UUT : entity work.gradient_descent
        generic map (
            DATA_WIDTH          => DATA_WIDTH_C,
            FRAC_BITS           => FRAC_BITS_C,
            LEARNING_RATE_SHIFT => LEARNING_RATE_SHIFT_C
        )
        port map (
            clk            => clk,
            rst            => rst,
            enable         => enable,
            prediction     => prediction,
            target_value   => target_value,
            input_value    => input_value,
            current_weight => current_weight,
            updated_weight => updated_weight,
            done           => done
        );

    process

        procedure apply_update_and_check(
            constant prediction_i     : in integer;
            constant target_i         : in integer;
            constant input_i          : in integer;
            constant current_weight_i : in integer;
            constant expected_weight  : in integer;
            constant test_name        : in string
        ) is
        begin
            prediction <= std_logic_vector(
                to_signed(prediction_i, DATA_WIDTH_C)
            );

            target_value <= std_logic_vector(
                to_signed(target_i, DATA_WIDTH_C)
            );

            input_value <= std_logic_vector(
                to_signed(input_i, DATA_WIDTH_C)
            );

            current_weight <= std_logic_vector(
                to_signed(current_weight_i, DATA_WIDTH_C)
            );

            enable <= '1';

            wait until rising_edge(clk);
            wait for 1 ns;

            assert done = '1'
                report "FAIL [" & test_name &
                       "]: done was not asserted"
                severity failure;

            assert to_integer(signed(updated_weight)) = expected_weight
                report "FAIL [" & test_name &
                       "]: updated_weight=" &
                       integer'image(
                           to_integer(signed(updated_weight))
                       ) &
                       ", expected=" &
                       integer'image(expected_weight)
                severity failure;

            enable <= '0';

            wait until rising_edge(clk);
            wait for 1 ns;

            assert done = '0'
                report "FAIL [" & test_name &
                       "]: done must be a one-cycle pulse"
                severity failure;
        end procedure;

    begin

        rst <= '1';

        wait until rising_edge(clk);
        wait until rising_edge(clk);
        wait for 1 ns;

        assert done = '0'
            report "FAIL: done must be zero during reset"
            severity failure;

        assert signed(updated_weight) = to_signed(0, DATA_WIDTH_C)
            report "FAIL: updated_weight must be zero during reset"
            severity failure;

        rst <= '0';

        wait until rising_edge(clk);
        wait for 1 ns;

        -- Test 1:
        -- error = 192 - 256 = -64
        -- product = -64 * 128 = -8192
        -- gradient = -8192 >> 8 = -32
        -- scaled = -32 >> 4 = -2
        -- result = 128 - (-2) = 130
        apply_update_and_check(
            192,
            256,
            128,
            128,
            130,
            "main Q8.8 update"
        );

        -- Test 2: ordinary positive gradient, no saturation.
        apply_update_and_check(
            127,
            -128,
            256,
            32000,
            31985,
            "ordinary positive gradient"
        );

        -- Test 3: ordinary negative gradient, no saturation.
        apply_update_and_check(
            -128,
            127,
            256,
            -32000,
            -31984,
            "ordinary negative gradient"
        );

        -- Test 4: one-step positive saturation.
        apply_update_and_check(
            0,
            16,
            256,
            32767,
            32767,
            "near positive saturation"
        );

        -- Test 5: one-step negative saturation.
        apply_update_and_check(
            0,
            -16,
            256,
            -32768,
            -32768,
            "near negative saturation"
        );

        -- Test 6:
        -- Extreme negative gradient.
        -- This test fails if the wide gradient is truncated before saturation.
        apply_update_and_check(
            -32768,
            32767,
            32767,
            32767,
            32767,
            "extreme positive saturation"
        );

        -- Test 7:
        -- Extreme positive gradient.
        -- This test fails if the wide gradient is truncated before saturation.
        apply_update_and_check(
            32767,
            -32768,
            32767,
            -32768,
            -32768,
            "extreme negative saturation"
        );

        assert false
            report "tb_gradient_descent PASSED: 7/7 checks"
            severity note;

        std.env.stop;
    end process;

end architecture Behavioral;
