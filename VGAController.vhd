library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
use work.Constants.all;

entity VGAController is
  Port (
    hSync, vSync: out std_logic;
    hPosCurrent : in integer range 1 to TOT_H; 
    vPosCurrent : in integer range 1 to TOT_V
  );
end VGAController;

architecture Behavioral of VGAController is   
--Intermediate carrier signal   
signal VGAClock: std_logic;   
begin
    hSync <= '0' when (hPosCurrent > FP_H) and (hPosCurrent < FP_H + SP_H + 1) else '1';
    vSync <= '0' when (vPosCurrent > FP_V) and (vPosCurrent < FP_V + SP_V + 1) else '1';

end Behavioral;
