library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;

package model_parameters_pkg is

    constant MODEL_WEIGHTS_C : weight_matrix_t := (
        0 => (to_signed(39, WEIGHT_WIDTH_C),
              to_signed(83, WEIGHT_WIDTH_C),
              to_signed(-112, WEIGHT_WIDTH_C),
              to_signed(-54, WEIGHT_WIDTH_C)),
        1 => (to_signed(33, WEIGHT_WIDTH_C),
              to_signed(5, WEIGHT_WIDTH_C),
              to_signed(-12, WEIGHT_WIDTH_C),
              to_signed(-49, WEIGHT_WIDTH_C)),
        2 => (to_signed(-72, WEIGHT_WIDTH_C),
              to_signed(-88, WEIGHT_WIDTH_C),
              to_signed(124, WEIGHT_WIDTH_C),
              to_signed(103, WEIGHT_WIDTH_C))
    );

    constant MODEL_BIASES_C : score_vector_t := (
        0 => to_signed(2, SCORE_WIDTH_C),
        1 => to_signed(7, SCORE_WIDTH_C),
        2 => to_signed(-9, SCORE_WIDTH_C)
    );

    constant UNCERTAINTY_THRESHOLD_C : natural := 128;

end package model_parameters_pkg;
