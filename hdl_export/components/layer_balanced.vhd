library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

entity layer_balanced is
    port (
        inputs  : in  feature_vector_t;
        weights : in  weight_matrix_t;
        biases  : in  score_vector_t;
        scores  : out score_vector_t
    );
end entity layer_balanced;

architecture struct of layer_balanced is
begin
    GEN_NEURONS : for class_index in
        0 to NUM_CLASSES_C - 1
    generate
        U_NEURON : entity work.neuron_balanced
            port map (
                inputs  => inputs,
                weights => weights(class_index),
                bias    => biases(class_index),
                score   => scores(class_index)
            );
    end generate;
end architecture struct;
