library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity ExecuteMove is
   port 
   (
      state_in      : in  tBoardState;
      posFrom       : in  tPosition;
      posTo         : in  tPosition;
      state_out     : out tBoardState
   );
end entity;

architecture arch of ExecuteMove is

begin

   process (state_in, posFrom, posTo)
   begin
   
      state_out <= state_in;
      
      state_out.info.blackTurn <= not state_in.info.blackTurn;
   
      state_out.board(posTo.y, posTo.x) <= state_in.board(posFrom.y, posFrom.x);
      
      if (posFrom.y = 0 and posFrom.x = 4) then state_out.info.blackKingMoved  <= '1'; end if;
      if (posFrom.y = 0 and posFrom.x = 0) then state_out.info.blackRook1Moved <= '1'; end if;
      if (posFrom.y = 0 and posFrom.x = 7) then state_out.info.blackRook2Moved <= '1'; end if;
      if (posFrom.y = 7 and posFrom.x = 4) then state_out.info.whiteKingMoved  <= '1'; end if;
      if (posFrom.y = 7 and posFrom.x = 0) then state_out.info.whiteRook1Moved <= '1'; end if;
      if (posFrom.y = 7 and posFrom.x = 7) then state_out.info.whiteRook2Moved <= '1'; end if;
      
      -- castling
      if (state_in.board(posFrom.y, posFrom.x)(2 downto 0) = FIGURE_KING) then
         if (posTo.x < posFrom.x - 1 or posTo.x > posFrom.x + 1) then
            if (posTo.x < 4) then -- queen side
               state_out.board(posTo.y, 3) <= state_in.board(posTo.y, 0);
               state_out.board(posTo.y, 0) <= FIGURE_EMPTY;
            else           
               state_out.board(posTo.y, 5) <= state_in.board(posTo.y, 7);
               state_out.board(posTo.y, 7) <= FIGURE_EMPTY;
            end if;
         end if;
      end if;
      
      state_out.info.allowEnPassant  <= '0';
      state_out.info.enPassantColumn <= posTo.x;
      state_out.info.enPassantRow    <= posTo.y;
      if (state_in.board(posFrom.y, posFrom.x)(2 downto 0) = FIGURE_PAWN) then
         -- double step
         if (posTo.y < posFrom.y - 1 or posTo.y > posFrom.y + 1) then
            state_out.info.allowEnPassant <= '1';
         end if;
         -- en passant
         if (posFrom.x /= posTo.x and state_in.board(posTo.y, posTo.x) = FIGURE_EMPTY) then
            state_out.board(posFrom.y, posTo.x) <= FIGURE_EMPTY;
         end if;
         -- promote
         if (state_in.board(posFrom.y, posFrom.x) = FIGURE_WHITE_PAWN and posTo.y = 0) then state_out.board(posTo.y, posTo.x) <= FIGURE_WHITE_QUEEN; end if;
         if (state_in.board(posFrom.y, posFrom.x) = FIGURE_BLACK_PAWN and posTo.y = 7) then state_out.board(posTo.y, posTo.x) <= FIGURE_BLACK_QUEEN; end if;
      end if;
      
      state_out.board(posFrom.y, posFrom.x) <= FIGURE_EMPTY;
         
   end process;     
   
end architecture; 