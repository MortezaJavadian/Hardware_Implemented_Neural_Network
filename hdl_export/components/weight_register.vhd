library ieee;
use ieee.std_logic_1164.all;

entity weight_register is
    generic (
        DATA_WIDTH : positive := 32
    );
    port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        data   : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        output : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity weight_register;

architecture Behavioral of weight_register is
    signal reg : std_logic_vector(DATA_WIDTH - 1 downto 0);
begin
    process(clk, rst)
    begin
        if rst = '1' then
            reg <= (others => '0');
        elsif rising_edge(clk) then
            reg <= data;
        end if;
    end process;

    output <= reg;
end architecture Behavioral;
