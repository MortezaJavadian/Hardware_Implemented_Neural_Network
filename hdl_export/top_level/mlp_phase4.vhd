library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;
use work.model_parameters_pkg.all;

entity mlp_phase4 is
    port (
        clk : in std_logic;
        rst : in std_logic;

        valid_in : in std_logic;
        data_in  : in std_logic_vector(31 downto 0);

        valid_out : out std_logic;

        class_out : out std_logic_vector(1 downto 0);

        uncertain_out : out std_logic;

        confidence_margin_out :
            out std_logic_vector(
                SCORE_WIDTH_C - 1 downto 0
            )
    );
end entity mlp_phase4;

architecture rtl of mlp_phase4 is

    signal features_comb : feature_vector_t;

    signal scores_comb : score_vector_t;

    signal scores_stage_1 : score_vector_t :=
        (others => (others => '0'));

    signal valid_stage_1 : std_logic := '0';

    signal class_comb : unsigned(1 downto 0);

    signal margin_comb :
        unsigned(SCORE_WIDTH_C - 1 downto 0);

begin

    features_comb(0) <=
        unsigned(data_in(31 downto 24));

    features_comb(1) <=
        unsigned(data_in(23 downto 16));

    features_comb(2) <=
        unsigned(data_in(15 downto 8));

    features_comb(3) <=
        unsigned(data_in(7 downto 0));

    U_LAYER : entity work.layer_balanced
        port map (
            inputs  => features_comb,
            weights => MODEL_WEIGHTS_C,
            biases  => MODEL_BIASES_C,
            scores  => scores_comb
        );

    U_ARGMAX : entity work.argmax
        port map (
            scores            => scores_stage_1,
            class_index       => class_comb,
            confidence_margin => margin_comb
        );

    process(clk, rst)
    begin
        if rst = '1' then
            scores_stage_1 <=
                (others => (others => '0'));

            valid_stage_1 <= '0';
            valid_out     <= '0';

            class_out <= (others => '0');

            confidence_margin_out <=
                (others => '0');

            uncertain_out <= '0';

        elsif rising_edge(clk) then

            valid_stage_1 <= valid_in;
            valid_out     <= valid_stage_1;

            if valid_in = '1' then
                scores_stage_1 <= scores_comb;
            end if;

            if valid_stage_1 = '1' then

                class_out <=
                    std_logic_vector(class_comb);

                confidence_margin_out <=
                    std_logic_vector(margin_comb);

                if margin_comb <
                    to_unsigned(
                        UNCERTAINTY_THRESHOLD_C,
                        SCORE_WIDTH_C
                    )
                then
                    uncertain_out <= '1';
                else
                    uncertain_out <= '0';
                end if;
            end if;
        end if;
    end process;

end architecture rtl;
