library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity argmax is
    port (
        scores            : in  score_vector_t;
        class_index       : out unsigned(1 downto 0);
        confidence_margin : out unsigned(SCORE_WIDTH_C - 1 downto 0)
    );
end entity argmax;

architecture Behavioral of argmax is
begin
    process(all)
        variable best_val     : score_t;
        variable second_val   : score_t;
        variable best_idx     : unsigned(1 downto 0);
        variable diff         : signed(SCORE_WIDTH_C downto 0);
        variable abs_diff     : unsigned(SCORE_WIDTH_C - 1 downto 0);
    begin
        best_val   := scores(0);
        second_val := scores(1);
        best_idx   := "00";

        if scores(1) > scores(0) then
            best_val   := scores(1);
            second_val := scores(0);
            best_idx   := "01";
        end if;

        if scores(2) > best_val then
            second_val := best_val;
            best_val   := scores(2);
            best_idx   := "10";
        elsif scores(2) > second_val then
            second_val := scores(2);
        end if;

        diff := resize(best_val, SCORE_WIDTH_C + 1) -
                resize(second_val, SCORE_WIDTH_C + 1);

        if diff < 0 then
            abs_diff := (others => '0');
        else
            abs_diff := unsigned(diff(SCORE_WIDTH_C - 1 downto 0));
        end if;

        class_index       <= best_idx;
        confidence_margin <= abs_diff;
    end process;
end architecture Behavioral;
