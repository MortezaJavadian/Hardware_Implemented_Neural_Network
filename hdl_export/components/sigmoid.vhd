library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Sigmoid is
    port (
        x : in  std_logic_vector(7 downto 0);
        y : out std_logic_vector(7 downto 0)
    );
end entity Sigmoid;

architecture LUT of Sigmoid is
begin
    process(x)
        variable idx : signed(7 downto 0);
    begin
        idx := signed(x);
        if idx <= to_signed(-8, 8) then
            y <= std_logic_vector(to_unsigned(0, 8));
        elsif idx = to_signed(-7, 8) then
            y <= std_logic_vector(to_unsigned(0, 8));
        elsif idx = to_signed(-6, 8) then
            y <= std_logic_vector(to_unsigned(1, 8));
        elsif idx = to_signed(-5, 8) then
            y <= std_logic_vector(to_unsigned(2, 8));
        elsif idx = to_signed(-4, 8) then
            y <= std_logic_vector(to_unsigned(5, 8));
        elsif idx = to_signed(-3, 8) then
            y <= std_logic_vector(to_unsigned(12, 8));
        elsif idx = to_signed(-2, 8) then
            y <= std_logic_vector(to_unsigned(30, 8));
        elsif idx = to_signed(-1, 8) then
            y <= std_logic_vector(to_unsigned(69, 8));
        elsif idx = to_signed(0, 8) then
            y <= std_logic_vector(to_unsigned(128, 8));
        elsif idx = to_signed(1, 8) then
            y <= std_logic_vector(to_unsigned(186, 8));
        elsif idx = to_signed(2, 8) then
            y <= std_logic_vector(to_unsigned(225, 8));
        elsif idx = to_signed(3, 8) then
            y <= std_logic_vector(to_unsigned(243, 8));
        elsif idx = to_signed(4, 8) then
            y <= std_logic_vector(to_unsigned(250, 8));
        elsif idx = to_signed(5, 8) then
            y <= std_logic_vector(to_unsigned(253, 8));
        elsif idx = to_signed(6, 8) then
            y <= std_logic_vector(to_unsigned(254, 8));
        elsif idx = to_signed(7, 8) then
            y <= std_logic_vector(to_unsigned(255, 8));
        else
            y <= std_logic_vector(to_unsigned(255, 8));
        end if;
    end process;
end architecture LUT;
