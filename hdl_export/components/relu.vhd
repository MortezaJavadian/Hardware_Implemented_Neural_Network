library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ReLU is
    generic (
        DATA_WIDTH : positive := 32
    );
    port (
        x : in  std_logic_vector(DATA_WIDTH - 1 downto 0);
        y : out std_logic_vector(DATA_WIDTH - 1 downto 0)
    );
end entity ReLU;

architecture Behavioral of ReLU is
begin
    process(all)
    begin
        if signed(x) < 0 then
            y <= (others => '0');
        else
            y <= x;
        end if;
    end process;
end architecture Behavioral;
