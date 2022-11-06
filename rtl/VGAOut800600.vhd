library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

entity VGAOut is
   port 
   (
      Clk         : in     std_logic;  
      vga_h_sync  : buffer std_logic := '0';
      vga_v_sync  : out    std_logic := '0';
      vblank      : out    std_logic := '0';
      hblank      : out    std_logic := '0';
      CounterX    : buffer integer range 0 to 2047 := 0;
      CounterY    : buffer integer range 0 to 1023 := 0
   );
end entity;

architecture arch of VGAOut is

   signal vga_HS : std_logic := '0';
   signal vga_VS : std_logic := '0';
   
   signal hbl : std_logic := '0';
   signal vbl : std_logic := '0';

begin

 process (Clk)
   begin
      if rising_edge(Clk) then
         
         CounterX <= CounterX + 1;
         if (CounterX = 1055) then -- Whole line 1056
            CounterX <= 0;
            CounterY <= CounterY + 1;
            if (CounterY > 626) then -- Whole frame 628 / Back porch 23
               CounterY <= 0;
            end if;
         end if;
         
         vga_HS <= '0';
         if ((CounterX >= 839) and (CounterX < 968)) then  -- Front porch 40 / Sync pulse 128 / Back porch 88
            vga_HS <= '1';
         end if;
         
         vga_VS <= '0';
         if ((CounterY >= 601) and (CounterY < 604)) then -- Front porch 1 / Sync pulse 4
            vga_VS <= '1';
         end if;
         
         vbl <= '0';
         if (CounterY > 599) then 
            vbl <= '1';
         end if;
         
         hbl <= '0';
         if (CounterX > 799) then 
            hbl <= '1';
         end if;
         
         vblank <= vbl;
         hblank <= hbl;
         
         vga_h_sync <= vga_HS;
	      if(vga_h_sync = '0' and vga_HS = '1') then 
            vga_v_sync <= vga_VS;
         end if;

      end if;
   end process;     
   
end architecture; 
