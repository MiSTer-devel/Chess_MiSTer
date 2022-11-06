library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity Progressbar is
   generic
   (
      MAX       : INTEGER;
      XMULT     : INTEGER;
      POSX      : INTEGER;
      POSY      : INTEGER;
      SIZEY     : INTEGER;
      RGB_BACK  : std_logic_vector(23 DOWNTO 0);
      RGB_FRONT : std_logic_vector(23 DOWNTO 0)
   );
   port 
   (
      Clk         : in     std_logic;  
      
      progress    : in     integer range 0 to MAX - 1;
      
      CounterX    : in     integer range 0 to 1023 := 0;
      CounterY    : in     integer range 0 to 1023 := 0;
      
      outputOn    : out    std_logic;
      outputColor : out    std_logic_vector(23 downto 0) := (others => '0')
   );
end entity;

architecture arch of Progressbar is

   constant XPIXELS : integer := MAX * XMULT + 4;

   signal xCount : integer range 0 to MAX - 2;
   signal xSlow  : integer range 0 to XMULT - 1;

begin

   process (Clk)
   begin
      if rising_edge(Clk) then
         
         outputOn <= '0';
         
         if (CounterY >= POSY and CounterY < POSY + SIZEY) then
            if (CounterX >= POSX and CounterX < POSX + XPIXELS) then
               outputOn    <= '1';
               outputColor <= RGB_BACK;
               if (CounterX >= POSX + 2 and CounterX < POSX + XPIXELS - 2) then
                  if (progress >= xCount and CounterY >= POSY + 2 and CounterY < POSY + SIZEY - 2) then
                     outputColor <= RGB_FRONT;
                  end if;
                  if (xSlow < XMULT - 1) then
                     xSlow <= xSlow + 1;
                  else
                     xSlow  <= 0;
                     if (xCount < MAX - 2) then
                        xCount <= xCount + 1;
                     end if;
                  end if;
               end if;
            else
               xCount <= 0;
               xSlow  <= 0;
            end if;
         end if;

      end if;
   end process;     
   
end architecture; 