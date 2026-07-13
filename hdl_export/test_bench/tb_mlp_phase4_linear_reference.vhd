library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

use work.nn_types_pkg.all;

entity tb_mlp_phase4_linear_reference is
    generic (
        VECTOR_FILE : string := "hdl_export/test_bench/data/iris_vectors.txt"
    );
end entity tb_mlp_phase4_linear_reference;

architecture Behavioral of tb_mlp_phase4_linear_reference is

    signal clk                  : std_logic := '0';
    signal rst                  : std_logic := '1';
    signal valid_in             : std_logic := '0';
    signal data_in              : std_logic_vector(31 downto 0) := (others => '0');
    signal valid_out            : std_logic;
    signal class_out            : std_logic_vector(1 downto 0);
    signal uncertain_out        : std_logic;
    signal confidence_margin_out: std_logic_vector(SCORE_WIDTH_C - 1 downto 0);

    constant CLK_PERIOD : time := 10 ns;
    signal vector_count : integer := 0;

begin

    clk <= not clk after CLK_PERIOD / 2;

    UUT : entity work.mlp_phase4_linear_reference
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
        file vfile      : text open read_mode is VECTOR_FILE;
        variable vline  : line;
        variable v_bits : std_logic_vector(31 downto 0);
        variable v_cls  : integer;
        variable v_unc  : integer;
        variable v_marg : integer;
        variable space  : character;
        variable good   : boolean;
    begin
        rst <= '1';
        wait until rising_edge(clk);
        wait until rising_edge(clk);
        rst <= '0';
        wait until rising_edge(clk);

        while not endfile(vfile) loop
            readline(vfile, vline);

            read(vline, v_bits, good);
            assert good report "Failed to read binary vector" severity failure;

            read(vline, space, good);
            read(vline, v_cls, good);
            assert good report "Failed to read class" severity failure;

            read(vline, space, good);
            read(vline, v_unc, good);
            assert good report "Failed to read uncertain" severity failure;

            read(vline, space, good);
            read(vline, v_marg, good);
            assert good report "Failed to read margin" severity failure;

            data_in  <= v_bits;
            valid_in <= '1';
            wait until rising_edge(clk);
            wait for 1 ns;

            assert valid_out = '0'
                report "FAIL: valid_out should be 0 at first edge for vector " &
                       integer'image(vector_count + 1)
                severity failure;

            valid_in <= '0';
            wait until rising_edge(clk);
            wait for 1 ns;

            assert valid_out = '1'
                report "FAIL: valid_out should be 1 for vector " &
                       integer'image(vector_count + 1)
                severity failure;

            assert to_integer(unsigned(class_out)) = v_cls
                report "FAIL: class mismatch for vector " &
                       integer'image(vector_count + 1) &
                       ": got " & integer'image(to_integer(unsigned(class_out))) &
                       " expected " & integer'image(v_cls)
                severity failure;

            assert uncertain_out = std_logic(to_unsigned(v_unc, 1)(0))
                report "FAIL: uncertain mismatch for vector " &
                       integer'image(vector_count + 1)
                severity failure;

            assert to_integer(unsigned(confidence_margin_out)) = v_marg
                report "FAIL: margin mismatch for vector " &
                       integer'image(vector_count + 1) &
                       ": got " & integer'image(to_integer(unsigned(confidence_margin_out))) &
                       " expected " & integer'image(v_marg)
                severity failure;

            vector_count <= vector_count + 1;
            wait until rising_edge(clk);
            wait for 1 ns;

            assert valid_out = '0'
                report "FAIL: valid_out should be 0 after deasserting valid_in for vector " &
                       integer'image(vector_count)
                severity failure;
        end loop;

        assert vector_count = 150
            report "FAIL: vector_count = " & integer'image(vector_count) &
                   ", expected 150"
            severity failure;

        assert false
            report "tb_mlp_phase4_linear_reference PASSED: 150/150 vectors matched with two-cycle latency"
            severity note;
        std.env.stop;
    end process;

end architecture Behavioral;
