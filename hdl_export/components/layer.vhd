library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity layer is
    port (
        inputs  : in  feature_vector_t;
        weights : in  weight_matrix_t;
        biases  : in  score_vector_t;
        scores  : out score_vector_t
    );
end entity layer;

architecture struct of layer is
begin
    GEN_NEURONS : for c in 0 to NUM_CLASSES_C - 1 generate
        U_NEURON : entity work.neuron
            port map (
                inputs  => inputs,
                weights => weights(c),
                bias    => biases(c),
                score   => scores(c)
            );
    end generate;
end architecture struct;
