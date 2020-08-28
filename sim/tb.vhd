library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;
use ieee.math_real.all;      
use STD.textio.all;

use work.globals.all;

entity etb  is
end entity;

architecture arch of etb is

   signal clk   : std_logic := '1';
   
   signal tx_command  : std_logic_vector(31 downto 0);
   signal tx_bytes    : integer range 0 to 4;
   signal tx_enable   : std_logic := '0';
   
   signal input_up      : std_logic := '0';
   signal input_down    : std_logic := '0';
   signal input_left    : std_logic := '0';
   signal input_right   : std_logic := '0';
   signal input_action  : std_logic := '0';
   signal input_cancel  : std_logic := '0';
   signal sys_reset     : std_logic := '0';
   signal vga_h_sync    : std_logic;
   signal vga_v_sync    : std_logic;
   signal vga_h_blank   : std_logic;
   signal vga_v_blank   : std_logic;
   signal vga_R         : std_logic_vector(7 downto 0);
   signal vga_G         : std_logic_vector(7 downto 0);
   signal vga_B         : std_logic_vector(7 downto 0);
   signal Speaker       : std_logic;

begin

   clk       <= not clk after 5 ns;
   
   process
   begin
      wait until rising_edge(clk);
      if (tx_enable = '1' and tx_command(7) = '1') then
         sys_reset    <= tx_command(0);
         input_up     <= tx_command(1);
         input_down   <= tx_command(2);
         input_left   <= tx_command(3);
         input_right  <= tx_command(4);
         input_action <= tx_command(5);
         input_cancel <= tx_command(6);
         wait until rising_edge(clk);
         wait until rising_edge(clk);
      end if;
   end process;
   
   idut : entity work.TopModule
   port map
   (
      Clk          => clk        ,
      reset        => sys_reset  ,
      
      mirrorBoard  => '0',
      aiOn         => '1',
      strength     => 3,
      randomness   => 0,
      playerBlack  => '0',
      overlayOn    => '1',
      
      input_up     => input_up    ,
      input_down   => input_down  ,
      input_left   => input_left  ,
      input_right  => input_right ,
      input_action => input_action,
      input_cancel => input_cancel,
      input_save   => '0',
      input_load   => '0',
      input_rewind => '0',
      
      vga_h_sync   => vga_h_sync ,
      vga_v_sync   => vga_v_sync ,
      vga_h_blank  => vga_h_blank,
      vga_v_blank  => vga_v_blank,
      vga_R        => vga_R      ,
      vga_G        => vga_G      ,
      vga_B        => vga_B      ,
      Speaker      => Speaker    
   );
 
   iestringprocessor : entity work.estringprocessor
   port map
   (
      ready       => '1',
      tx_command  => tx_command,
      tx_bytes    => tx_bytes,  
      tx_enable   => tx_enable, 
      rx_command  => x"00000000",
      rx_valid    => '1'
   );
    
   process
      file outfile: text;
      variable f_status: FILE_OPEN_STATUS;
      variable line_out : line;
      variable color : unsigned(31 downto 0);
      variable linecounter_int : integer;
      
      constant FRAMESIZE_X : integer := 640;
      constant FRAMESIZE_Y : integer := 480;
      
      variable xpos : integer := 0;
      variable ypos : integer := 0;
      
   begin
   
      file_open(f_status, outfile, "gra_fb_out.gra", write_mode);
      file_close(outfile);
      
      file_open(f_status, outfile, "gra_fb_out.gra", append_mode);
      write(line_out, string'("640#480")); 
      writeline(outfile, line_out);
      
      while (true) loop
         wait until rising_edge(clk);
                
         if (vga_h_blank = '1') then
            if (xpos > 0) then
               ypos := ypos + 1;
               file_close(outfile);
               file_open(f_status, outfile, "gra_fb_out.gra", append_mode);
            end if;
            xpos := 0;
         end if;
         
         if (vga_v_blank = '1') then
            ypos := 0;
         end if;

         if (vga_h_blank = '0' and vga_v_blank = '0') then
            color := (others => '0');
            color(23 downto 16) := unsigned(vga_R);
            color(15 downto  8) := unsigned(vga_G);
            color(7  downto  0) := unsigned(vga_B);

            write(line_out, to_integer(color));
            write(line_out, string'("#"));
            write(line_out, xpos);
            write(line_out, string'("#")); 
            write(line_out, ypos);
            writeline(outfile, line_out);
            
            xpos := xpos + 1;
         end if;
         
      end loop;
   
   end process;
   
end architecture;


