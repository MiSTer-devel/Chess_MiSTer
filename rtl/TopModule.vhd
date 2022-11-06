library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity TopModule is
   port 
   (
      Clk          : in     std_logic;  
      reset        : in     std_logic;
      
      mirrorBoard  : in     std_logic;
      aiOn         : in     std_logic;
      strength     : in     integer range 0 to 15;
      randomness   : in     integer range 0 to 3;
      playerBlack  : in     std_logic;
      overlayOn    : in     std_logic;
      
      input_up     : in     std_logic;  
      input_down   : in     std_logic;  
      input_left   : in     std_logic;  
      input_right  : in     std_logic;  
      input_action : in     std_logic;  
      input_cancel : in     std_logic;  
      input_save   : in     std_logic;  
      input_load   : in     std_logic;  
      input_rewind : in     std_logic;  
      
      vga_h_sync   : out    std_logic;
      vga_v_sync   : out    std_logic;
      vga_h_blank  : out    std_logic;
      vga_v_blank  : out    std_logic;
      vga_R        : out    std_logic_vector(7 downto 0);
      vga_G        : out    std_logic_vector(7 downto 0);
      vga_B        : out    std_logic_vector(7 downto 0);
      Speaker      : out    std_logic := '0'
   );
end entity;

architecture arch of TopModule is

   signal vblank           : std_logic;
   signal hblank           : std_logic;
   signal CounterX         : integer range 0 to 1023;
   signal CounterY         : integer range 0 to 1023;
   signal Drawer_R         : std_logic_vector(7 downto 0);
   signal Drawer_G         : std_logic_vector(7 downto 0);
   signal Drawer_B         : std_logic_vector(7 downto 0);
   
   signal progressbarOn    : std_logic;
   signal progressbarColor : std_logic_vector(23 downto 0);
   
   signal overlay_0        : unsigned(0 to 79);
   signal overlay_1        : unsigned(0 to 71);
   type toverlayout is array (0 to 17) of std_logic_vector(23 downto 0);
   signal overlay_out      : toverlayout;
   signal overlay_combined : std_logic_vector(23 downto 0);
                           
   signal boardState       : tBoardState;
   signal cursor           : tPosition;
   signal markedCells      : tboardBit;
   signal markedPos        : tPosition;
   signal markedPosOn      : std_logic;
   signal cheated          : std_logic;
                           
   signal lastOn           : std_logic;
   signal lastFrom         : tPosition;
   signal lastTo           : tPosition;
                           
   signal progress         : integer range 0 to 63;
                           
   signal checkMate        : std_logic;
   signal check            : std_logic;
   signal draw             : std_logic;

begin

   iControl : entity work.Control
   port map
   (
      Clk          => Clk,         
      reset        => reset,  

      mirrorBoard  => mirrorBoard,
      aiOn         => aiOn,
      strength     => strength,
      randomness   => randomness,
      playerBlack  => playerBlack,
                                  
      input_up     => input_up,   
      input_down   => input_down,  
      input_left   => input_left,  
      input_right  => input_right, 
      input_action => input_action,
      input_cancel => input_cancel,
      input_save   => input_save,  
      input_load   => input_load,  
      input_rewind => input_rewind,
                                  
      boardState   => boardState,       
      cursor       => cursor,      
      markedCells  => markedCells,
      markedPos    => markedPos, 
      markedPosOn  => markedPosOn,
      cheated      => cheated,
      
      lastOn       => lastOn,  
      lastFrom     => lastFrom,
      lastTo       => lastTo, 

      progress     => progress,  
      
      checkMate    => checkMate,
      check        => check,    
      draw         => draw     
   );
 
   iVGAOut : entity work.VGAOut
   port map
   (
      Clk         => Clk,       
      vga_h_sync  => vga_h_sync,
      vga_v_sync  => vga_v_sync,
      vblank      => vblank,    
      hblank      => hblank,    
      CounterX    => CounterX, 
      CounterY    => CounterY  
   );
   
   vga_h_blank <= hblank;
   vga_v_blank <= vblank;
   
   iDrawer : entity work.Drawer
   port map
   (
      Clk         => Clk,  
      
      mirrorBoard => mirrorBoard,
      
      board       => boardState.board,      
      cursor      => cursor,     
      markedCells => markedCells,
      markedPos   => markedPos,  
      markedPosOn => markedPosOn,
      cheated     => cheated,
      
      lastOn      => lastOn,  
      lastFrom    => lastFrom,
      lastTo      => lastTo,  
      
      vblank      => vblank,   
      CounterX    => CounterX, 
      CounterY    => CounterY, 
      
      red         => Drawer_R,    
      green       => Drawer_G,    
      blue        => Drawer_B   
   );
   
   iProgressbar : entity work.Progressbar
   generic map
   (
      MAX       => 64,
      XMULT     => 2,
      POSX      => 12,
      POSY      => 10,
      SIZEY     => 20,
      RGB_BACK  => x"FFFFFF",
      RGB_FRONT => x"FF0000"
   )
   port map
   (
      Clk         => Clk,
      progress    => progress,
      CounterX    => CounterX,
      CounterY    => CounterY,
      outputOn    => progressbarOn,   
      outputColor => progressbarColor
   );
   
   overlay_0 <= x"5748495445205455524e" when boardState.Info.blackTurn = '0' else x"424c41434b205455524e";
   ioverlay0 : entity work.overlay
   generic map
   (
      COLS                   => 10,
      BACKGROUNDON           => '0',
      RGB_BACK               => x"000000",
      RGB_FRONT              => x"FFFFFF",
      OFFSETX                => 16,
      OFFSETY                => 48
   )
   port map
   (
      clk                    => Clk,
      ena                    => '1',           
      i_pixel_out_x          => CounterX,
      i_pixel_out_y          => CounterY,
      i_pixel_out_data       => x"000000", 
      o_pixel_out_data       => overlay_out(0),    
      textstring             => overlay_0
   );
   
   overlay_1 <= x"434845434b4d415445" when checkMate = '1' else x"434845434b20202020" when check = '1' else x"445241572020202020" when draw = '1' else x"202020202020202020";
   ioverlay1 : entity work.overlay
   generic map
   (
      COLS                   => 9,
      BACKGROUNDON           => '0',
      RGB_BACK               => x"000000",
      RGB_FRONT              => x"FFFFFF",
      OFFSETX                => 16,
      OFFSETY                => 64
   )
   port map
   (
      clk                    => Clk,
      ena                    => '1',                    
      i_pixel_out_x          => CounterX,
      i_pixel_out_y          => CounterY,
      i_pixel_out_data       => x"000000", 
      o_pixel_out_data       => overlay_out(1),
      textstring             => overlay_1
   );
   
   gboardprints: for i in 0 to 7 generate
      signal inputvalNumbers : unsigned(0 to 7);
      signal inputvalLetters : unsigned(0 to 7);
   begin
   
      inputvalNumbers <= x"31" + to_unsigned(7 - i, 8) when mirrorBoard = '0' else x"31" + to_unsigned(i, 8);
      inputvalLetters <= x"41" + to_unsigned(i, 8) when mirrorBoard = '0' else x"41" + to_unsigned(7 - i, 8);
   
      ioverlayNumbers : entity work.overlay
      generic map
      (
         COLS                   => 1,
         BACKGROUNDON           => '0',
         RGB_BACK               => x"000000",
         RGB_FRONT              => x"FFFFFF",
         OFFSETX                => 631,
         OFFSETY                => 25 + i * 60
      )
      port map
      (
         clk                    => Clk,
         ena                    => '1',      
         i_pixel_out_x          => CounterX,
         i_pixel_out_y          => CounterY,
         i_pixel_out_data       => x"000000", 
         o_pixel_out_data       => overlay_out(2 + i),   
         textstring             => inputvalNumbers
      );
      
      ioverlayLetters : entity work.overlay
      generic map
      (
         COLS                   => 1,
         BACKGROUNDON           => '0',
         RGB_BACK               => x"000000",
         RGB_FRONT              => x"FFFFFF",
         OFFSETX                => 151 + i * 60,
         OFFSETY                => 468
      )
      port map
      (
         clk                    => Clk,
         ena                    => '1',      
         i_pixel_out_x          => CounterX,
         i_pixel_out_y          => CounterY,
         i_pixel_out_data       => x"000000", 
         o_pixel_out_data       => overlay_out(10 + i),   
         textstring             => inputvalLetters
      );
   end generate;
   
   process (overlay_out)
      variable wired_or : std_logic_vector(23 downto 0);
   begin
      wired_or := overlay_out(0) or overlay_out(1);
      if (overlayOn = '1') then
         for i in 2 to (overlay_out'length - 1) loop
            wired_or := wired_or or overlay_out(i);
         end loop;
      end if;
      overlay_combined <= wired_or;
   end process;
   
   vga_R <= progressbarColor(23 downto 16) when progressbarOn = '1' else (Drawer_R or overlay_combined(23 downto 16));
   vga_G <= progressbarColor(15 downto 8)  when progressbarOn = '1' else (Drawer_G or overlay_combined(15 downto 8));
   vga_B <= progressbarColor(7 downto 0)   when progressbarOn = '1' else (Drawer_B or overlay_combined(7 downto 0));

   
end architecture; 
