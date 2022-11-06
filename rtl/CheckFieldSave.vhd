library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity CheckFieldSave is
   port 
   (
      Clk           : in     std_logic;  
      start         : in     std_logic;  
      done          : out    std_logic := '0';
      save          : out    std_logic := '0';
            
      boardstate    : in     tBoardState;
      blackTurn     : in     std_logic;
      checkPos      : in     tPosition
   );
end entity;

architecture arch of CheckFieldSave is

   signal board      : tboard;

   type tState is
   (
      IDLE,
      KNIGHTCHECK,
      ALLCHECK
   );
   signal state : tstate;
   
   signal i          : integer range 1 to 7;
   signal pathcheck  : std_logic_vector(0 to 7);

begin

   board <= boardstate.board;
   
   process (Clk)
   begin
      if rising_edge(Clk) then
      
         done <= '0';

         case (state) is
         
            when IDLE =>
               if (start = '1') then
                  save      <= '1';
                  state     <= KNIGHTCHECK;
                  i         <= 1;
                  pathcheck <= (others => '1');
               end if;
      
            when KNIGHTCHECK =>
               state <= ALLCHECK;
               if (
                   (checkPos.x > 1 and checkPos.y > 0 and ((board(checkPos.y - 1, checkPos.x - 2)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y - 1, checkPos.x - 2)(3) = blackTurn))) or
                   (checkPos.x > 0 and checkPos.y > 1 and ((board(checkPos.y - 2, checkPos.x - 1)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y - 2, checkPos.x - 1)(3) = blackTurn))) or
                   (checkPos.x > 1 and checkPos.y < 7 and ((board(checkPos.y + 1, checkPos.x - 2)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y + 1, checkPos.x - 2)(3) = blackTurn))) or
                   (checkPos.x > 0 and checkPos.y < 6 and ((board(checkPos.y + 2, checkPos.x - 1)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y + 2, checkPos.x - 1)(3) = blackTurn))) or
                   (checkPos.x < 6 and checkPos.y > 0 and ((board(checkPos.y - 1, checkPos.x + 2)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y - 1, checkPos.x + 2)(3) = blackTurn))) or
                   (checkPos.x < 7 and checkPos.y > 1 and ((board(checkPos.y - 2, checkPos.x + 1)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y - 2, checkPos.x + 1)(3) = blackTurn))) or
                   (checkPos.x < 6 and checkPos.y < 7 and ((board(checkPos.y + 1, checkPos.x + 2)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y + 1, checkPos.x + 2)(3) = blackTurn))) or
                   (checkPos.x < 7 and checkPos.y < 6 and ((board(checkPos.y + 2, checkPos.x + 1)(2 downto 0) = FIGURE_KNIGHT) and (board(checkPos.y + 2, checkPos.x + 1)(3) = blackTurn)))
                  ) then
                  state <= IDLE;
                  done  <= '1';
                  save  <= '0';
               end if;
            
            when ALLCHECK =>
               if (i = 7 or pathcheck = "00000000") then
                  state <= IDLE;
                  done  <= '1';
               else
                  i <= i + 1;
               end if;
               -- straight path
               if (pathcheck(0) = '1') then
                  if (checkPos.x >= i) then
                     if (board(checkPos.y, checkPos.x - i)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(0) <= '0';
                        if (board(checkPos.y, checkPos.x - i)(3) = blackTurn) then
                           case (board(checkPos.y, checkPos.x - i)(2 downto 0)) is
                              when FIGURE_ROOK | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                        end if;
                     end if;
                  else
                     pathcheck(0) <= '0';
                  end if;
               end if;
               if (pathcheck(1) = '1') then
                  if (checkPos.x + i < 8) then
                     if (board(checkPos.y, checkPos.x + i)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(1) <= '0';
                        if (board(checkPos.y, checkPos.x + i)(3) = blackTurn) then
                           case (board(checkPos.y, checkPos.x + i)(2 downto 0)) is
                              when FIGURE_ROOK | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                        end if;
                     end if;
                  else
                     pathcheck(1) <= '0';
                  end if;
               end if;
               if (pathcheck(2) = '1') then
                  if (checkPos.y >= i) then
                     if (board(checkPos.y - i, checkPos.x)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(2) <= '0';
                        if (board(checkPos.y - i, checkPos.x)(3) = blackTurn) then
                           case (board(checkPos.y - i, checkPos.x)(2 downto 0)) is
                              when FIGURE_ROOK | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                        end if;
                     end if;
                  else
                     pathcheck(2) <= '0';
                  end if;
               end if;
               if (pathcheck(3) = '1') then
                  if (checkPos.y + i < 8) then
                     if (board(checkPos.y + i, checkPos.x)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(3) <= '0';
                        if (board(checkPos.y + i, checkPos.x)(3) = blackTurn) then
                           case (board(checkPos.y + i, checkPos.x)(2 downto 0)) is
                              when FIGURE_ROOK | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                        end if;
                     end if;
                  else
                     pathcheck(3) <= '0';
                  end if;
               end if;
               -- diagonal path
               if (pathcheck(4) = '1') then
                  if (checkPos.x >= i and checkPos.y >= i) then
                     if (board(checkPos.y - i, checkPos.x - i)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(4) <= '0';
                        if (board(checkPos.y - i, checkPos.x - i)(3) = blackTurn) then
                           case (board(checkPos.y - i, checkPos.x - i)(2 downto 0)) is
                              when FIGURE_BISHOP | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                           if (board(checkPos.y - i, checkPos.x - i) = FIGURE_BLACK_PAWN and i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                        end if;
                     end if;
                  else
                     pathcheck(4) <= '0';
                  end if;
               end if;
               if (pathcheck(5) = '1') then
                  if (checkPos.x + i < 8 and checkPos.y >= i) then
                     if (board(checkPos.y - i, checkPos.x + i)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(5) <= '0';
                        if (board(checkPos.y - i, checkPos.x + i)(3) = blackTurn) then
                           case (board(checkPos.y - i, checkPos.x + i)(2 downto 0)) is
                              when FIGURE_BISHOP | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                           if (board(checkPos.y - i, checkPos.x + i) = FIGURE_BLACK_PAWN and i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                        end if;
                     end if;
                  else
                     pathcheck(5) <= '0';
                  end if;
               end if;
               if (pathcheck(6) = '1') then
                  if (checkPos.x >= i and checkPos.y + i < 8) then
                     if (board(checkPos.y + i, checkPos.x - i)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(6) <= '0';
                        if (board(checkPos.y + i, checkPos.x - i)(3) = blackTurn) then
                           case (board(checkPos.y + i, checkPos.x - i)(2 downto 0)) is
                              when FIGURE_BISHOP | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                           if (board(checkPos.y + i, checkPos.x - i) = FIGURE_WHITE_PAWN and i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                        end if;
                     end if;
                  else
                     pathcheck(6) <= '0';
                  end if;
               end if;
               if (pathcheck(7) = '1') then
                  if (checkPos.x + i < 8 and checkPos.y + i < 8) then
                     if (board(checkPos.y + i, checkPos.x + i)(2 downto 0) /= FIGURE_NULL) then
                        pathcheck(7) <= '0';
                        if (board(checkPos.y + i, checkPos.x + i)(3) = blackTurn) then
                           case (board(checkPos.y + i, checkPos.x + i)(2 downto 0)) is
                              when FIGURE_BISHOP | FIGURE_QUEEN => done <= '1'; state <= IDLE; save  <= '0';
                              when FIGURE_KING => if (i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                              when others => null;
                           end case;
                           if (board(checkPos.y + i, checkPos.x + i) = FIGURE_WHITE_PAWN and i = 1) then done <= '1'; state <= IDLE; save  <= '0'; end if;
                        end if;
                     end if;
                  else
                     pathcheck(7) <= '0';
                  end if;
               end if;

            
         end case;

      end if;
   end process;     
   
end architecture; 