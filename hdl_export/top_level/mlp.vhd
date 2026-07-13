library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.nn_types_pkg.all;
use work.model_parameters_pkg.all;

entity MLP is
    port (
        clk                 : in  std_logic;
        rst                 : in  std_logic;
        valid_in            : in  std_logic;
        data_in             : in  std_logic_vector(31 downto 0);
        valid_out           : out std_logic;
        class_out           : out std_logic_vector(1 downto 0);
        uncertain_out       : out std_logic;
        confidence_margin_out: out std_logic_vector(SCORE_WIDTH_C - 1 downto 0)
    );
end entity MLP;

architecture Behavioral of MLP is

    signal inputs  : feature_vector_t;
    signal scores  : score_vector_t;
    signal cls_idx : unsigned(1 downto 0);
    signal margin  : unsigned(SCORE_WIDTH_C - 1 downto 0);
    signal margin_slv : std_logic_vector(SCORE_WIDTH_C - 1 downto 0);

    signal valid_r : std_logic;
    signal class_r : std_logic_vector(1 downto 0);
    signal marg_r  : std_logic_vector(SCORE_WIDTH_C - 1 downto 0);
    signal unc_r   : std_logic;

begin

    inputs(0) <= unsigned(data_in(31 downto 24));
    inputs(1) <= unsigned(data_in(23 downto 16));
    inputs(2) <= unsigned(data_in(15 downto 8));
    inputs(3) <= unsigned(data_in(7 downto 0));

    U_LAYER : entity work.layer
        port map (
            inputs  => inputs,
            weights => MODEL_WEIGHTS_C,
            biases  => MODEL_BIASES_C,
            scores  => scores
        );

    U_ARGMAX : entity work.argmax
        port map (
            scores            => scores,
            class_index       => cls_idx,
            confidence_margin => margin
        );

    margin_slv <= std_logic_vector(margin);

    process(clk, rst)
        variable threshold : unsigned(SCORE_WIDTH_C - 1 downto 0);
    begin
        if rst = '1' then
            valid_r <= '0';
            class_r <= (others => '0');
            marg_r  <= (others => '0');
            unc_r   <= '0';
        elsif rising_edge(clk) then
            if valid_in = '1' then
                valid_r <= '1';
                class_r <= std_logic_vector(cls_idx);
                marg_r  <= margin_slv;
                threshold := to_unsigned(UNCERTAINTY_THRESHOLD_C, SCORE_WIDTH_C);
                if margin < threshold then
                    unc_r <= '1';
                else
                    unc_r <= '0';
                end if;
            else
                valid_r <= '0';
            end if;
        end if;
    end process;

    valid_out    <= valid_r;
    class_out    <= class_r;
    confidence_margin_out <= marg_r;
    uncertain_out <= unc_r;

end architecture Behavioral;
