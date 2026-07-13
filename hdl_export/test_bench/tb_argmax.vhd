library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity tb_argmax is
end entity tb_argmax;

architecture Behavioral of tb_argmax is

    signal scores_in      : score_vector_t;
    signal class_index_out: unsigned(1 downto 0);
    signal margin_out     : unsigned(SCORE_WIDTH_C - 1 downto 0);

begin

    UUT : entity work.argmax
        port map (
            scores            => scores_in,
            class_index       => class_index_out,
            confidence_margin => margin_out
        );

    process
        procedure check(s0, s1, s2 : integer;
                        exp_class  : integer;
                        exp_margin : integer) is
        begin
            scores_in(0) <= to_signed(s0, SCORE_WIDTH_C);
            scores_in(1) <= to_signed(s1, SCORE_WIDTH_C);
            scores_in(2) <= to_signed(s2, SCORE_WIDTH_C);
            wait for 1 ns;
            assert to_integer(class_index_out) = exp_class
                report "FAIL: class_index wrong for scores (" &
                       integer'image(s0) & "," & integer'image(s1) & "," &
                       integer'image(s2) & "): got " &
                       integer'image(to_integer(class_index_out)) &
                       " expected " & integer'image(exp_class)
                severity failure;
            assert to_integer(margin_out) = exp_margin
                report "FAIL: margin wrong for scores (" &
                       integer'image(s0) & "," & integer'image(s1) & "," &
                       integer'image(s2) & "): got " &
                       integer'image(to_integer(margin_out)) &
                       " expected " & integer'image(exp_margin)
                severity failure;
        end procedure;
    begin
        check(10, 3, -4, 0, 7);
        check(1, 8, 5, 1, 3);
        check(-3, -2, 4, 2, 6);
        check(10, 10, 5, 0, 0);
        check(1, 7, 7, 1, 0);
        check(5, 5, 5, 0, 0);
        check(-10, -20, -30, 0, 10);
        check(0, 0, 1, 2, 1);

        assert false
            report "tb_argmax PASSED"
            severity note;
        std.env.stop;
    end process;

end architecture Behavioral;
