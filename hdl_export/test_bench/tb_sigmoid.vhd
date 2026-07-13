library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_sigmoid is
end entity tb_sigmoid;

architecture Behavioral of tb_sigmoid is

    signal x_slv : std_logic_vector(7 downto 0);
    signal y_slv : std_logic_vector(7 downto 0);

begin

    UUT : entity work.Sigmoid
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
                report "FAIL: Sigmoid(" & integer'image(x_val) & ") = " &
                       integer'image(y_act) & ", expected " & integer'image(y_expected)
                severity failure;
        end procedure;
    begin
        check(-8, 0);
        check(-4, 5);
        check(-1, 69);
        check(0, 128);
        check(1, 186);
        check(4, 250);
        check(8, 255);
        check(-128, 0);
        check(127, 255);
        check(7, 255);
        check(-7, 0);
        check(5, 253);
        check(6, 254);
        check(-6, 1);
        check(-5, 2);
        check(-3, 12);
        check(-2, 30);
        check(2, 225);
        check(3, 243);

        assert false
            report "tb_sigmoid PASSED"
            severity note;
        std.env.stop;
    end process;

end architecture Behavioral;
