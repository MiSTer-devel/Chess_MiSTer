library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity Drawer is
   port 
   (
      Clk         : in     std_logic;  
      
      mirrorBoard : in     std_logic;
      
      board       : in     tboard;
      cursor      : in     tPosition;
      markedCells : in     tboardBit;
      markedPos   : in     tPosition;
      markedPosOn : in     std_logic;
      cheated     : in     std_logic;
      
      lastOn      : in     std_logic;
      lastFrom    : in     tPosition;
      lastTo      : in     tPosition;
      
      vblank      : in     std_logic;  
      CounterX    : in     integer range 0 to 1023 := 0;
      CounterY    : in     integer range 0 to 1023 := 0;
      
      red         : out    std_logic_vector(7 downto 0) := (others => '0');
      green       : out    std_logic_vector(7 downto 0) := (others => '0');
      blue        : out    std_logic_vector(7 downto 0) := (others => '0')
   );
end entity;

architecture arch of Drawer is

   signal vblank_1           : std_logic := '0';
                             
   signal fieldCntX          : integer range 0 to 63 := 0;
   signal fieldCntY          : integer range 0 to 63 := 0;
   signal fieldPosX          : integer range 0 to 7 := 0;
   signal fieldPosY          : integer range 0 to 7 := 0;
                             
   signal fieldCntX_1        : integer range 0 to 63 := 0;
                             
   signal fieldColor         : std_logic := '0';
   signal fieldColor_1       : std_logic := '0';
   signal colorBoard         : unsigned(23 downto 0);
   signal shadedown          : std_logic := '0';
   signal shadedown_1        : std_logic := '0';
                             
   signal color_address      : integer range 0 to 3599 := 0;
   signal color_figure       : std_logic_vector(31 downto 0) := (others => '0');
   signal color_tile0        : std_logic_vector(31 downto 0);
   signal color_tile1        : std_logic_vector(31 downto 0);
   signal color_white_pawn   : std_logic_vector(31 downto 0);
   signal color_white_knight : std_logic_vector(31 downto 0);
   signal color_white_bishop : std_logic_vector(31 downto 0);
   signal color_white_rook   : std_logic_vector(31 downto 0);
   signal color_white_queen  : std_logic_vector(31 downto 0);
   signal color_white_king   : std_logic_vector(31 downto 0);
   signal color_white_mister : std_logic_vector(31 downto 0);
   signal color_black_pawn   : std_logic_vector(31 downto 0);
   signal color_black_knight : std_logic_vector(31 downto 0);
   signal color_black_bishop : std_logic_vector(31 downto 0);
   signal color_black_rook   : std_logic_vector(31 downto 0);
   signal color_black_queen  : std_logic_vector(31 downto 0);
   signal color_black_king   : std_logic_vector(31 downto 0);
   signal color_black_mister : std_logic_vector(31 downto 0);
   
   type tColor is
   (
      COLORRED,
      COLORGREEN,
      COLORBLUE
   );
   
   signal markerOn           : std_logic;
   signal markerColor        : tColor;
   signal markerOn_1         : std_logic;
   signal markerColor_1      : tColor;

begin

   itile0        : entity work.img_tile_0          port map (Clk, color_address, color_tile0  );
   itile1        : entity work.img_tile_1          port map (Clk, color_address, color_tile1  );
                                                   
   iwhite_pawn   : entity work.img_white_pawn_60   port map (Clk, color_address, color_white_pawn  );
   iwhite_knight : entity work.img_white_knight_60 port map (Clk, color_address, color_white_knight);
   iwhite_bishop : entity work.img_white_bishop_60 port map (Clk, color_address, color_white_bishop);
   iwhite_rook   : entity work.img_white_rook_60   port map (Clk, color_address, color_white_rook  );
   iwhite_queen  : entity work.img_white_queen_60  port map (Clk, color_address, color_white_queen );
   iwhite_king   : entity work.img_white_king_60   port map (Clk, color_address, color_white_king  );
   iwhite_mister : entity work.img_white_mister_60 port map (Clk, color_address, color_white_mister);
   iblack_pawn   : entity work.img_black_pawn_60   port map (Clk, color_address, color_black_pawn  );
   iblack_knight : entity work.img_black_knight_60 port map (Clk, color_address, color_black_knight);
   iblack_bishop : entity work.img_black_bishop_60 port map (Clk, color_address, color_black_bishop);
   iblack_rook   : entity work.img_black_rook_60   port map (Clk, color_address, color_black_rook  );
   iblack_queen  : entity work.img_black_queen_60  port map (Clk, color_address, color_black_queen );
   iblack_king   : entity work.img_black_king_60   port map (Clk, color_address, color_black_king  );
   iblack_mister : entity work.img_black_mister_60 port map (Clk, color_address, color_black_mister);

   process (Clk)
      variable color_mix_red     : unsigned(15 downto 0);
      variable color_mix_green   : unsigned(15 downto 0);
      variable color_mix_blue    : unsigned(15 downto 0);
      variable color_board_red   : unsigned(7 downto 0);
      variable color_board_green : unsigned(7 downto 0);
      variable color_board_blue  : unsigned(7 downto 0);
   begin
      if rising_edge(Clk) then
         
         vblank_1 <= vblank;
         if (vblank = '1' and vblank_1 = '0') then
            fieldCntX  <= 0;
            fieldCntY  <= 0;           
            fieldPosX  <= 0;
            fieldPosY  <= 0;
            fieldColor <= '0';
            if (mirrorBoard = '1') then
               fieldPosY  <= 7;
            end if;
         end if;
         
         if (CounterX = 630 and CounterY < 480) then
            fieldCntY <= fieldCntY + 1;
            if (fieldCntY = 59) then
               fieldCntY  <= 0;
               if (mirrorBoard = '1') then
                  if (fieldPosY > 0) then 
                     fieldPosY  <= fieldPosY - 1; 
                  end if;
               else
                  if (fieldPosY < 7) then 
                     fieldPosY  <= fieldPosY + 1; 
                  end if;
               end if;
               fieldColor <= not fieldColor;
            end if;
         end if;
         
         color_address <= fieldCntY * 60 + fieldCntX;
            
         fieldColor_1 <= fieldColor;
         colorBoard <= unsigned(color_tile1(23 downto 0));
         if (fieldColor_1 = '1') then
            colorBoard <= unsigned(color_tile0(23 downto 0));
         end if;
         
         case(board(fieldPosY, fieldPosX)) is
            when FIGURE_EMPTY        => color_figure <= (others => '0');  
            when FIGURE_WHITE_PAWN   => color_figure <= color_white_pawn  ;  
            when FIGURE_WHITE_KNIGHT => color_figure <= color_white_knight;  
            when FIGURE_WHITE_BISHOP => color_figure <= color_white_bishop;  
            when FIGURE_WHITE_ROOK   => color_figure <= color_white_rook  ;  
            when FIGURE_WHITE_QUEEN  => color_figure <= color_white_queen ;  
            when FIGURE_WHITE_KING   => if (cheated = '1') then color_figure <= color_white_mister; else color_figure <= color_white_king; end if;
            when FIGURE_Black_PAWN   => color_figure <= color_black_pawn  ;  
            when FIGURE_Black_KNIGHT => color_figure <= color_black_knight;  
            when FIGURE_Black_BISHOP => color_figure <= color_black_bishop;  
            when FIGURE_Black_ROOK   => color_figure <= color_black_rook  ;  
            when FIGURE_Black_QUEEN  => color_figure <= color_black_queen ;  
            when FIGURE_Black_KING   => if (cheated = '1') then color_figure <= color_black_mister; else color_figure <= color_black_king; end if;
            when others => null;
         end case;
         
         color_mix_red   := unsigned(color_figure(31 downto 24)) * unsigned(color_figure(7 downto 0));
         color_mix_green := unsigned(color_figure(31 downto 24)) * unsigned(color_figure(15 downto 8));
         color_mix_blue  := unsigned(color_figure(31 downto 24)) * unsigned(color_figure(23 downto 16));
         
         color_board_red   := unsigned(colorBoard(23 downto 16));
         color_board_green := unsigned(colorBoard(15 downto 8));
         color_board_blue  := unsigned(colorBoard( 7 downto 0));
         shadedown_1 <= shadedown;
         if (shadedown_1 = '1') then
            color_board_red   := color_board_red   / 4;
            color_board_green := color_board_green / 4;
            color_board_blue  := color_board_blue  / 4;
         end if;
         
         color_mix_red   := color_mix_red   + ((255 - unsigned(color_figure(31 downto 24))) * color_board_red);
         color_mix_green := color_mix_green + ((255 - unsigned(color_figure(31 downto 24))) * color_board_green);
         color_mix_blue  := color_mix_blue  + ((255 - unsigned(color_figure(31 downto 24))) * color_board_blue);
         
         fieldCntX_1 <= fieldCntX;
         
         markerOn  <= '0';
         shadedown <= '0';
         if ((fieldCntX < 4 or fieldCntX > 55 or fieldCntY < 4 or fieldCntY > 55)) then
            if (lastOn = '1' and ((fieldPosX = lastFrom.x and fieldPosY = lastFrom.y) or (fieldPosX = lastTo.x and fieldPosY = lastTo.y))) then
               shadedown <= '1';
            end if;
         
            if (markedCells(fieldPosY, fieldPosX) = '1') then
               markerOn    <= '1';
               markerColor <= COLORGREEN;
            end if;
            if (markedPosOn = '1' and fieldPosX = markedPos.x and fieldPosY = markedPos.y) then
               markerOn    <= '1';
               markerColor <= COLORRED;
            end if;
            if (fieldPosX = cursor.x and fieldPosY = cursor.y) then
               markerOn    <= '1';
               markerColor <= COLORBLUE;
            end if;
         end if;
         
         markerOn_1    <= markerOn;
         markerColor_1 <= markerColor;
         
         if (CounterX >= 150 and CounterX < 630 and CounterY < 480) then
            fieldCntX <= fieldCntX + 1;
            if (fieldCntX = 59) then
               fieldCntX  <= 0;
               if (mirrorBoard = '1') then
                  if (fieldPosX > 0) then 
                     fieldPosX  <= fieldPosX - 1;
                  end if;
               else
                  if (fieldPosX < 7) then 
                     fieldPosX  <= fieldPosX + 1;
                  end if;
               end if;
               fieldColor <= not fieldColor;
            end if;
         end if;
           
         if (CounterX >= 152 and CounterX < 632 and CounterY < 480) then
            if (markerOn_1 = '1') then
               case (markerColor_1) is
                  when COLORGREEN => red   <= x"00"; green <= x"FF"; blue  <= x"00"; 
                  when COLORRED   => red   <= x"FF"; green <= x"00"; blue  <= x"00";
                  when COLORBLUE  => red   <= x"20"; green <= x"A0"; blue  <= x"FF";
               end case;
            else
               red   <= std_logic_vector(color_mix_red  (15 downto 8));
               green <= std_logic_vector(color_mix_green(15 downto 8));
               blue  <= std_logic_vector(color_mix_blue (15 downto 8)); 
            end if;
            
         else
            if (mirrorBoard = '1') then
               fieldPosX <= 7;
            else
               fieldPosX <= 0;
            end if;
            red   <= (others => '0');
            green <= (others => '0');
            blue  <= (others => '0'); 
         end if;

      end if;
   end process;     
   
end architecture; 