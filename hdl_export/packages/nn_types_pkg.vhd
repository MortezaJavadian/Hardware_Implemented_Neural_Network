library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package nn_types_pkg is

    constant NUM_FEATURES_C   : natural := 4;
    constant NUM_CLASSES_C    : natural := 3;
    constant FEATURE_WIDTH_C  : natural := 8;
    constant WEIGHT_WIDTH_C   : natural := 8;
    constant SCORE_WIDTH_C    : natural := 24;

    subtype feature_t is unsigned(FEATURE_WIDTH_C - 1 downto 0);
    subtype weight_t  is signed(WEIGHT_WIDTH_C - 1 downto 0);
    subtype score_t   is signed(SCORE_WIDTH_C - 1 downto 0);

    type feature_vector_t is array (0 to NUM_FEATURES_C - 1) of feature_t;
    type class_weight_vector_t is array (0 to NUM_FEATURES_C - 1) of weight_t;
    type weight_matrix_t is array (0 to NUM_CLASSES_C - 1) of class_weight_vector_t;
    type score_vector_t is array (0 to NUM_CLASSES_C - 1) of score_t;

end package nn_types_pkg;
