library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity neuron is
    port (
        inputs  : in  feature_vector_t;
        weights : in  class_weight_vector_t;
        bias    : in  score_t;
        score   : out score_t
    );
end entity neuron;

architecture comb of neuron is
begin
    process(inputs, weights, bias)
        variable product_wide : signed(FEATURE_WIDTH_C + WEIGHT_WIDTH_C downto 0);
        variable accum        : score_t;
    begin
        accum := bias;
        for i in 0 to NUM_FEATURES_C - 1 loop
            product_wide := signed('0' & inputs(i)) * weights(i);
            accum := accum + resize(product_wide, SCORE_WIDTH_C);
        end loop;
        score <= accum;
    end process;
end architecture comb;
