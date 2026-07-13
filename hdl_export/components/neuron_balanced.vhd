library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity neuron_balanced is
    port (
        inputs  : in  feature_vector_t;
        weights : in  class_weight_vector_t;
        bias    : in  score_t;
        score   : out score_t
    );
end entity neuron_balanced;

architecture comb of neuron_balanced is
begin
    process(all)
        variable product_0 : signed(
            FEATURE_WIDTH_C + WEIGHT_WIDTH_C downto 0
        );

        variable product_1 : signed(
            FEATURE_WIDTH_C + WEIGHT_WIDTH_C downto 0
        );

        variable product_2 : signed(
            FEATURE_WIDTH_C + WEIGHT_WIDTH_C downto 0
        );

        variable product_3 : signed(
            FEATURE_WIDTH_C + WEIGHT_WIDTH_C downto 0
        );

        variable sum_01 : score_t;
        variable sum_23 : score_t;
        variable total  : score_t;
    begin
        product_0 :=
            signed('0' & inputs(0)) * weights(0);

        product_1 :=
            signed('0' & inputs(1)) * weights(1);

        product_2 :=
            signed('0' & inputs(2)) * weights(2);

        product_3 :=
            signed('0' & inputs(3)) * weights(3);

        sum_01 :=
            resize(product_0, SCORE_WIDTH_C) +
            resize(product_1, SCORE_WIDTH_C);

        sum_23 :=
            resize(product_2, SCORE_WIDTH_C) +
            resize(product_3, SCORE_WIDTH_C);

        total :=
            sum_01 +
            sum_23 +
            bias;

        score <= total;
    end process;
end architecture comb;
