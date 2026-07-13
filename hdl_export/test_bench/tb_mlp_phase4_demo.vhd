library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity tb_mlp_phase4_demo is
end entity tb_mlp_phase4_demo;

architecture Behavioral of tb_mlp_phase4_demo is

    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '1';
    signal valid_in             : std_logic := '0';
    signal data_in              : std_logic_vector(31 downto 0) := (others => '0');
    signal valid_out            : std_logic;
    signal class_out            : std_logic_vector(1 downto 0);
    signal uncertain_out        : std_logic;
    signal confidence_margin_out: std_logic_vector(SCORE_WIDTH_C - 1 downto 0);

    constant CLK_PERIOD : time := 10 ns;

begin

    clk <= not clk after CLK_PERIOD / 2;

    UUT : entity work.mlp_phase4
        port map (
            clk                  => clk,
            rst                  => rst,
            valid_in             => valid_in,
            data_in              => data_in,
            valid_out            => valid_out,
            class_out            => class_out,
            uncertain_out        => uncertain_out,
            confidence_margin_out => confidence_margin_out
        );

    process
        procedure run_sample(
            hex_input  : std_logic_vector(31 downto 0);
            exp_class  : integer;
            exp_margin : integer;
            exp_unc    : integer
        ) is
        begin
            data_in  <= hex_input;
            valid_in <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;

            valid_in <= '0';
            wait until rising_edge(clk);
            wait for 1 ns;

            assert valid_out = '1'
                report "FAIL: valid_out not 1"
                severity failure;

            assert to_integer(unsigned(class_out)) = exp_class
                report "FAIL: class_out got " &
                       integer'image(to_integer(unsigned(class_out))) &
                       " expected " & integer'image(exp_class)
                severity failure;

            assert to_integer(unsigned(confidence_margin_out)) = exp_margin
                report "FAIL: margin got " &
                       integer'image(to_integer(unsigned(confidence_margin_out))) &
                       " expected " & integer'image(exp_margin)
                severity failure;

            assert uncertain_out = std_logic(to_unsigned(exp_unc, 1)(0))
                report "FAIL: uncertain_out mismatch"
                severity failure;

            wait until rising_edge(clk);
            wait for 1 ns;
        end procedure;

    begin
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        -- Sample 1: confident setosa
        run_sample(x"33230E02", 0, 1621, 0);
        wait until rising_edge(clk);

        -- Sample 2: confident versicolor
        run_sample(x"46202F0E", 1, 1822, 0);
        wait until rising_edge(clk);

        -- Sample 3: confident virginica
        run_sample(x"3F213C19", 2, 2260, 0);
        wait until rising_edge(clk);

        -- Sample 4: uncertain versicolor
        run_sample(x"3F19310F", 1, 12, 1);
        wait until rising_edge(clk);

        -- Sample 5: uncertain, wrong class
        run_sample(x"3F1C330F", 1, 19, 1);
        wait until rising_edge(clk);

        -- Sample 6: uncertain, wrong class
        run_sample(x"3B203012", 2, 77, 1);
        wait until rising_edge(clk);

        assert false
            report "tb_mlp_phase4_demo PASSED"
            severity note;
        std.env.stop;
    end process;

end architecture Behavioral;
