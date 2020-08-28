library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   
use STD.textio.all;

use work.pChess.all;

entity Evalboard is
   port 
   (
      Clk           : in     std_logic;  
      randomness    : in     integer range 0 to 3;
      start         : in     std_logic;  
      done          : out    std_logic := '0';
      boardvalue    : out    integer range -32768 to 32767;   
      boardstate    : in     tBoardState;
      calccount     : buffer integer := 0
   );
end entity;

architecture arch of Evalboard is

   signal board : tboard;

   type tState is
   (
      IDLE,
      ALLADD
   );
   signal state : tstate;
   
   signal random      : signed(10 downto 0) := (others => '0');
   signal randomvalue : integer range -1024 to 1023;
   
   type trowadds is array(0 to 7) of integer range -32768 to 32767;
   signal rowadds : trowadds;
   
   type tFieldScore is array(0 to 7, 0 to 7) of integer range -64 to 63;

   constant pawnPos : tFieldScore := 
   (
      (00,  00,  00,  00,  00,  00,  00,  00),
      (50,  50,  50,  50,  50,  50,  50,  50),
      (10,  10,  20,  30,  30,  20,  10,  10),
      (05,  05,  10,  25,  25,  10,  05,  05),
      (00,  00,  00,  20,  20,  00,  00,  00),
      (05, -05, -10,  00,  00, -10, -05,  05),
      (05,  10,  10, -20, -20,  10,  10,  05),
      (00,  00,  00,  00,  00,  00,  00,  00)
   );
   
   constant knightPos : tFieldScore := 
   (
      (-50, -40, -30, -30, -30, -30, -40, -50),
      (-40, -20,  00,  00,  00,  00, -20, -40),
      (-30,  00,  10,  15,  15,  10,  00, -30),
      (-30,  05,  15,  20,  20,  15,  05, -30),
      (-30,  00,  15,  20,  20,  15,  00, -30),
      (-30,  05,  10,  15,  15,  10,  05, -30),
      (-40, -20,  00,  05,  05,  00, -20, -40),
      (-50, -40, -30, -30, -30, -30, -40, -50)
   );
   
   constant bishopPos : tFieldScore := 
   (
      (-20, -10, -10, -10, -10, -10, -10, -20),
      (-10,  00,  00,  00,  00,  00,  00, -10),
      (-10,  00,  05,  10,  10,  05,  00, -10),
      (-10,  05,  05,  10,  10,  05,  05, -10),
      (-10,  00,  10,  10,  10,  10,  00, -10),
      (-10,  10,  10,  10,  10,  10,  10, -10),
      (-10,  05,  00,  00,  00,  00,  05, -10),
      (-20, -10, -10, -10, -10, -10, -10, -20)
   );
   
   constant rookPos : tFieldScore := 
   (
      (-20, -10, -10, -05, -05, -10, -10, -20),
      (-10,  00,  00,  00,  00,  00,  00, -10),
      (-10,  00,  05,  05,  05,  05,  00, -10),
      (-05,  00,  05,  05,  05,  05,  00, -05),
      ( 00,  00,  05,  05,  05,  05,  00, -05),
      (-10,  05,  05,  05,  05,  05,  00, -10),
      (-10,  00,  05,  00,  00,  00,  00, -10),
      (-20, -10, -10, -05, -05, -10, -10, -20)
   );
   
   constant queenPos : tFieldScore := 
   (
      (-20, -10, -10, -05, -05, -10, -10, -20),
      (-10,  00,  00,  00,  00,  00,  00, -10),
      (-10,  00,  05,  05,  05,  05,  00, -10),
      (-05,  00,  05,  05,  05,  05,  00, -05),
      ( 00,  00,  05,  05,  05,  05,  00, -05),
      (-10,  05,  05,  05,  05,  05,  00, -10),
      (-10,  00,  05,  00,  00,  00,  00, -10),
      (-20, -10, -10, -05, -05, -10, -10, -20)
   );
   
   constant kingPos : tFieldScore := 
   (
      (-30, -40, -40, -50, -50, -40, -40, -30),
      (-30, -40, -40, -50, -50, -40, -40, -30),
      (-30, -40, -40, -50, -50, -40, -40, -30),
      (-30, -40, -40, -50, -50, -40, -40, -30),
      (-20, -30, -30, -40, -40, -30, -30, -20),
      (-10, -20, -20, -20, -20, -20, -20, -10),
      ( 20,  20,  00,  00,  00,  00,  20,  20),
      ( 20,  30,  10,  00,  00,  10,  30,  20)
   );

begin

   board <= boardstate.board;
   
   process (Clk)
      variable sum : integer range -32768 to 32767;
   begin
      if rising_edge(Clk) then
      
         done <= '0';
         
         random <= random + 1;
         case (randomness) is
            when 0 => randomvalue <= 0;
            when 1 => randomvalue <= to_integer(random(4 downto 0));
            when 2 => randomvalue <= to_integer(random(8 downto 0));
            when 3 => randomvalue <= to_integer(random);
            when others => null;
         end case;

         case (state) is
         
            when IDLE =>
               if (start = '1') then
                  state     <= ALLADD;
                  calccount <= calccount + 1;
               end if;
            
               for y in 0 to 7 loop
                  sum := 0;
                  for x in 0 to 7 loop
                     case (board(y, x)) is
                        when FIGURE_WHITE_PAWN   => sum := sum + (100  +   pawnPos(y, x));
                        when FIGURE_WHITE_KNIGHT => sum := sum + (300  + knightPos(y, x));
                        when FIGURE_WHITE_BISHOP => sum := sum + (300  + bishopPos(y, x));
                        when FIGURE_WHITE_ROOK   => sum := sum + (500  +   rookPos(y, x));
                        when FIGURE_WHITE_QUEEN  => sum := sum + (900  +  queenPos(y, x));
                        when FIGURE_WHITE_KING   => sum := sum + (9000 +   kingPos(y, x));
                        when FIGURE_BLACK_PAWN   => sum := sum - (100  -   pawnPos(7 - y, x));
                        when FIGURE_BLACK_KNIGHT => sum := sum - (300  + knightPos(y, x));
                        when FIGURE_BLACK_BISHOP => sum := sum - (300  - bishopPos(7 - y, x));
                        when FIGURE_BLACK_ROOK   => sum := sum - (500  -   rookPos(7 - y, x));
                        when FIGURE_BLACK_QUEEN  => sum := sum - (900  +  queenPos(y, x));
                        when FIGURE_BLACK_KING   => sum := sum - (9000 -   kingPos(7 - y, x));
                        when others => null;
                     end case;
                  end loop;
                  rowadds(y) <= sum;
               end loop;

            when ALLADD =>
               state      <= IDLE;
               done       <= '1';
               sum := 0;
               for y in 0 to 7 loop
                  sum := sum + rowadds(y);
               end loop;
               boardvalue <= sum + randomvalue;
            
         end case;

      end if;
   end process;  

-- synthesis translate_off
--   process
--      file outfile: text;
--      variable f_status: FILE_OPEN_STATUS;
--      variable line_out : line;
--      variable count : integer;
--   begin
--   
--      file_open(f_status, outfile, "eval_export.csv", write_mode);
--      file_close(outfile);
--      
--      count := 0;
--      
--      while (true) loop
--         wait until rising_edge(clk);
--                
--         if (start = '1') then
--            file_open(f_status, outfile, "eval_export.csv", append_mode);
--            write(line_out, count);
--            writeline(outfile, line_out);
--            count := count + 1;
--            for y in 0 to 7 loop
--               for x in 0 to 7 loop
--                  write(line_out, to_hstring(signed(boardstate.board(y, x))));
--               end loop;
--               writeline(outfile, line_out);
--            end loop;
--            write(line_out, string'("####################")); 
--            writeline(outfile, line_out);
--            file_close(outfile);
--         end if;
-- 
--      end loop;
--   
--   end process; 
-- synthesis translate_on   
   
end architecture; 