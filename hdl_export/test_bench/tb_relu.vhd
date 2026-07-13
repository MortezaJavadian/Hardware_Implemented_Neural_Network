library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_relu is
end entity tb_relu;

architecture Behavioral of tb_relu is

    signal x_slv : std_logic_vector(7 downto 0);
    signal y_slv : std_logic_vector(7 downto 0);

begin

    UUT : entity work.ReLU
        generic map (DATA_WIDTH => 8)
        port map (
            x => x_slv,
            y => y_slv
        );

    process
        procedure check(x_val : integer; y_expected : integer) is
            variable y_act : integer;
        begin
            x_slv <= std_logic_vector(to_signed(x_val, 8));
            wait for 1 ns;
            y_act := to_integer(unsigned(y_slv));
            assert y_act = y_expected
                report "FAIL: ReLU(" & integer'image(x_val) & ") = " &
                       integer'image(y_act) & ", expected " & integer'image(y_expected)
                severity failure;
        end procedure;
    begin
        check(-5, 0);
        check(0, 0);
        check(7, 7);
        check(127, 127);
        check(-128, 0);
        check(1, 1);
        check(-1, 0);
        check(42, 42);
        check(-42, 0);

        assert false
            report "tb_relu PASSED"
            severity note;
        std.env.stop;
    end process;

end architecture Behavioral;
