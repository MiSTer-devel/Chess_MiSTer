library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity CheckMoves is
   port 
   (
      Clk           : in     std_logic;  
      start         : in     std_logic;  
      done          : out    std_logic := '0';
         
      boardstate    : in     tBoardState;
      checkPos      : in     tPosition;
      moves         : buffer tboardBit;
      noMove        : out    std_logic := '0'
   );
end entity;

architecture arch of CheckMoves is

   signal board      : tboard;

   type tState is
   (
      IDLE,
      PAWNMOVE,
      KNIGHTMOVE,
      BISHOPMOVE,
      ROOKMOVE,
      KINGMOVE,
      CASTLINGSAVELEFT,
      CASTLINGSAVERIGHT,
      CASTLINGWAITCHECK,
      CHECKKINGSAVESTART,
      CHECKKINGSAVE,
      WAITCHECK
   );
   signal state : tstate;
   
   signal color      : std_logic;
   signal isQueen    : std_logic;
   signal isKing     : std_logic;
   
   signal i          : integer range 1 to 7;
   signal pathcheck  : std_logic_vector(0 to 3);
                                      
   signal posTo      : tPosition;
   signal movedState : tBoardState;
   
   signal kingPos    : tPosition;
   signal kingPosOld : tPosition;

   signal fieldSaveStart : std_logic := '0';
   signal fieldSaveDone  : std_logic;
   signal fieldSaveSave  : std_logic;
   
   signal castling_posX  : integer range 0 to 7;
   signal castling_posY  : integer range 0 to 7;
   signal castlingLeft   : std_logic := '0'; 
   signal castlingRight  : std_logic := '0'; 
   signal castlingPos    : tPosition; 
   
   signal checkMoves     : tboardBit;
   
begin

   iExecuteMove : entity work.ExecuteMove
   port map
   (
      state_in  => boardstate,
      posFrom   => checkPos,
      posTo     => posTo,
      state_out => movedState
   );
   
   iCheckFieldSave : entity work.CheckFieldSave
   port map
   (
      Clk           => Clk,
      start         => fieldSaveStart,
      done          => fieldSaveDone,
      save          => fieldSaveSave,
         
      boardstate    => movedState,
      blackTurn     => movedState.info.blackTurn,
      checkPos      => kingPos
   );

   board <= boardstate.board;
   
   castlingPos.x <= castling_posX;
   castlingPos.y <= castling_posY;
   
   kingPos <= castlingPos when state = CASTLINGWAITCHECK else posTo when isKing = '1' else kingPosOld;

   process (Clk)
   begin
      if rising_edge(Clk) then
      
         done           <= '0';
         fieldSaveStart <= '0';
      
         case (state) is
         
            when IDLE =>
               color     <= board(checkPos.y, checkPos.x)(3);
               isQueen   <= '0';
               isKing    <= '0';
               i         <= 1;
               pathcheck <= "1111";
               posTo     <= (0, 0);
               for x in 0 to 7 loop
                  for y in 0 to 7 loop
                     if (board(y, x)(2 downto 0) = FIGURE_KING and board(y, x)(3) = boardstate.info.blackTurn) then
                        kingPosOld.x <= x;
                        kingPosOld.y <= y;
                     end if;                     
                  end loop;
               end loop;
               if (start = '1') then
                  moves <= (others => (others => '0'));
                  case (board(checkPos.y, checkPos.x)(2 downto 0)) is
                     when FIGURE_PAWN   => state <= PAWNMOVE;
                     when FIGURE_KNIGHT => state <= KNIGHTMOVE;
                     when FIGURE_BISHOP => state <= BISHOPMOVE;
                     when FIGURE_ROOK   => state <= ROOKMOVE;
                     when FIGURE_QUEEN  => state <= BISHOPMOVE; isQueen <= '1';
                     when FIGURE_KING   => state <= BISHOPMOVE; isKing  <= '1';
                     when others        => done <= '1';
                  end case;
               end if;
        
            when PAWNMOVE =>
               state <= CHECKKINGSAVESTART;
               if (color = COLOR_WHITE) then
                  if (board(checkPos.y - 1, checkPos.x) = FIGURE_EMPTY) then moves(checkPos.y - 1, checkPos.x) <= '1'; end if;
                  if (board(4, checkPos.x) = FIGURE_EMPTY and board(5, checkPos.x) = FIGURE_EMPTY and checkPos.y = 6) then moves(4, checkPos.x) <= '1'; end if;
                  if (checkPos.x > 0 and (board(checkPos.y - 1, checkPos.x - 1)(2 downto 0) /= FIGURE_NULL) and (board(checkPos.y - 1, checkPos.x - 1)(3) /= color)) then moves(checkPos.y - 1, checkPos.x - 1) <= '1'; end if;
                  if (checkPos.x < 7 and (board(checkPos.y - 1, checkPos.x + 1)(2 downto 0) /= FIGURE_NULL) and (board(checkPos.y - 1, checkPos.x + 1)(3) /= color)) then moves(checkPos.y - 1, checkPos.x + 1) <= '1'; end if;
               else
                  if (board(checkPos.y + 1, checkPos.x) = FIGURE_EMPTY) then moves(checkPos.y + 1, checkPos.x) <= '1'; end if;
                  if (board(3, checkPos.x) = FIGURE_EMPTY and board(2, checkPos.x) = FIGURE_EMPTY and checkPos.y = 1) then moves(3, checkPos.x) <= '1'; end if;
                  if (checkPos.x > 0 and (board(checkPos.y + 1, checkPos.x - 1)(2 downto 0) /= FIGURE_NULL) and (board(checkPos.y + 1, checkPos.x - 1)(3) /= color)) then moves(checkPos.y + 1, checkPos.x - 1) <= '1'; end if;
                  if (checkPos.x < 7 and (board(checkPos.y + 1, checkPos.x + 1)(2 downto 0) /= FIGURE_NULL) and (board(checkPos.y + 1, checkPos.x + 1)(3) /= color)) then moves(checkPos.y + 1, checkPos.x + 1) <= '1'; end if;
               end if;
               -- en passant
               if (boardstate.info.allowEnPassant = '1') then
                  if (checkPos.y = boardstate.info.enPassantRow) then
                     if (checkPos.x - 1 = boardstate.info.enPassantColumn or checkPos.x + 1 = boardstate.info.enPassantColumn) then
                        if (color = COLOR_WHITE) then
                           moves(checkPos.y - 1, boardstate.info.enPassantColumn) <= '1';
                        else
                           moves(checkPos.y + 1, boardstate.info.enPassantColumn) <= '1';
                        end if;
                     end if;
                  end if;
               end if;

            when KNIGHTMOVE =>
               state <= CHECKKINGSAVESTART;
               if (checkPos.x > 1 and checkPos.y > 0 and ((board(checkPos.y - 1, checkPos.x - 2)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y - 1, checkPos.x - 2)(3) /= color))) then moves(checkPos.y - 1, checkPos.x - 2) <= '1'; end if;
               if (checkPos.x > 0 and checkPos.y > 1 and ((board(checkPos.y - 2, checkPos.x - 1)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y - 2, checkPos.x - 1)(3) /= color))) then moves(checkPos.y - 2, checkPos.x - 1) <= '1'; end if;
               if (checkPos.x > 1 and checkPos.y < 7 and ((board(checkPos.y + 1, checkPos.x - 2)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y + 1, checkPos.x - 2)(3) /= color))) then moves(checkPos.y + 1, checkPos.x - 2) <= '1'; end if;
               if (checkPos.x > 0 and checkPos.y < 6 and ((board(checkPos.y + 2, checkPos.x - 1)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y + 2, checkPos.x - 1)(3) /= color))) then moves(checkPos.y + 2, checkPos.x - 1) <= '1'; end if;
               if (checkPos.x < 6 and checkPos.y > 0 and ((board(checkPos.y - 1, checkPos.x + 2)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y - 1, checkPos.x + 2)(3) /= color))) then moves(checkPos.y - 1, checkPos.x + 2) <= '1'; end if;
               if (checkPos.x < 7 and checkPos.y > 1 and ((board(checkPos.y - 2, checkPos.x + 1)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y - 2, checkPos.x + 1)(3) /= color))) then moves(checkPos.y - 2, checkPos.x + 1) <= '1'; end if;
               if (checkPos.x < 6 and checkPos.y < 7 and ((board(checkPos.y + 1, checkPos.x + 2)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y + 1, checkPos.x + 2)(3) /= color))) then moves(checkPos.y + 1, checkPos.x + 2) <= '1'; end if;
               if (checkPos.x < 7 and checkPos.y < 6 and ((board(checkPos.y + 2, checkPos.x + 1)(2 downto 0) = FIGURE_NULL) or (board(checkPos.y + 2, checkPos.x + 1)(3) /= color))) then moves(checkPos.y + 2, checkPos.x + 1) <= '1'; end if;
            
            when BISHOPMOVE =>               
               if (pathcheck(0) = '1') then
                  if (checkPos.x >= i and checkPos.y >= i) then
                     if (board(checkPos.y - i, checkPos.x - i)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y - i, checkPos.x - i) <= '1'; end if;
                     if (board(checkPos.y - i, checkPos.x - i)(3) /= color)                then moves(checkPos.y - i, checkPos.x - i) <= '1'; end if;
                     if (board(checkPos.y - i, checkPos.x - i)(2 downto 0) /= FIGURE_NULL) then pathcheck(0) <= '0'; end if;
                  else
                     pathcheck(0) <= '0';
                  end if;
               end if;
               if (pathcheck(1) = '1') then
                  if (checkPos.x + i < 8 and checkPos.y >= i) then
                     if (board(checkPos.y - i, checkPos.x + i)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y - i, checkPos.x + i) <= '1'; end if;
                     if (board(checkPos.y - i, checkPos.x + i)(3) /= color)                then moves(checkPos.y - i, checkPos.x + i) <= '1'; end if;
                     if (board(checkPos.y - i, checkPos.x + i)(2 downto 0) /= FIGURE_NULL) then pathcheck(1) <= '0'; end if;
                  else
                     pathcheck(1) <= '0';
                  end if;
               end if;
               if (pathcheck(2) = '1') then
                  if (checkPos.x >= i and checkPos.y + i < 8) then
                     if (board(checkPos.y + i, checkPos.x - i)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y + i, checkPos.x - i) <= '1'; end if;
                     if (board(checkPos.y + i, checkPos.x - i)(3) /= color)                then moves(checkPos.y + i, checkPos.x - i) <= '1'; end if;
                     if (board(checkPos.y + i, checkPos.x - i)(2 downto 0) /= FIGURE_NULL) then pathcheck(2) <= '0'; end if;
                  else
                     pathcheck(2) <= '0';
                  end if;
               end if;
               if (pathcheck(3) = '1') then
                  if (checkPos.x + i < 8 and checkPos.y + i < 8) then
                     if (board(checkPos.y + i, checkPos.x + i)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y + i, checkPos.x + i) <= '1'; end if;
                     if (board(checkPos.y + i, checkPos.x + i)(3) /= color)                then moves(checkPos.y + i, checkPos.x + i) <= '1'; end if;
                     if (board(checkPos.y + i, checkPos.x + i)(2 downto 0) /= FIGURE_NULL) then pathcheck(3) <= '0'; end if;
                  else
                     pathcheck(3) <= '0';
                  end if;
               end if;
               if (i < 7 and isKing = '0' and pathcheck /= "0000") then
                  i <= i + 1;
               else
                  if (isQueen = '1' or isKing = '1') then
                     state     <= ROOKMOVE;
                     i         <= 1;
                     pathcheck <= "1111";
                  else
                     state <= CHECKKINGSAVESTART;
                  end if;
               end if;
               
            
            when ROOKMOVE =>
               if (pathcheck(0) = '1') then
                  if (checkPos.x >= i) then
                     if (board(checkPos.y, checkPos.x - i)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y, checkPos.x - i) <= '1'; end if;
                     if (board(checkPos.y, checkPos.x - i)(3) /= color)                then moves(checkPos.y, checkPos.x - i) <= '1'; end if;
                     if (board(checkPos.y, checkPos.x - i)(2 downto 0) /= FIGURE_NULL) then pathcheck(0) <= '0'; end if;
                  else
                     pathcheck(0) <= '0';
                  end if;
               end if;
               if (pathcheck(1) = '1') then
                  if (checkPos.x + i < 8) then
                     if (board(checkPos.y, checkPos.x + i)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y, checkPos.x + i) <= '1'; end if;
                     if (board(checkPos.y, checkPos.x + i)(3) /= color)                then moves(checkPos.y, checkPos.x + i) <= '1'; end if;
                     if (board(checkPos.y, checkPos.x + i)(2 downto 0) /= FIGURE_NULL) then pathcheck(1) <= '0'; end if;
                  else
                     pathcheck(1) <= '0';
                  end if;
               end if;
               if (pathcheck(2) = '1') then
                  if (checkPos.y >= i) then
                     if (board(checkPos.y - i, checkPos.x)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y - i, checkPos.x) <= '1'; end if;
                     if (board(checkPos.y - i, checkPos.x)(3) /= color)                then moves(checkPos.y - i, checkPos.x) <= '1'; end if;
                     if (board(checkPos.y - i, checkPos.x)(2 downto 0) /= FIGURE_NULL) then pathcheck(2) <= '0'; end if;
                  else
                     pathcheck(2) <= '0';
                  end if;
               end if;
               if (pathcheck(3) = '1') then
                  if (checkPos.y + i < 8) then
                     if (board(checkPos.y + i, checkPos.x)(2 downto 0) = FIGURE_NULL)  then moves(checkPos.y + i, checkPos.x) <= '1'; end if;
                     if (board(checkPos.y + i, checkPos.x)(3) /= color)                then moves(checkPos.y + i, checkPos.x) <= '1'; end if;
                     if (board(checkPos.y + i, checkPos.x)(2 downto 0) /= FIGURE_NULL) then pathcheck(3) <= '0'; end if;
                  else
                     pathcheck(3) <= '0';
                  end if;
               end if;
               if (i < 7 and isKing = '0' and pathcheck /= "0000") then
                  i <= i + 1;
               else
                  if (isKing = '1') then
                     state <= KINGMOVE;
                  else
                     state <= CHECKKINGSAVESTART;
                  end if;
               end if;
            
            when KINGMOVE =>
               state <= CASTLINGSAVELEFT;
               -- castling check only, moved are done before
               castling_posX <= 2;
               castling_posY <= 0;
               if (color = COLOR_WHITE) then castling_posY <= 7; end if;
               castlingLeft  <= '0';
               castlingRight <= '0';
               if (color = COLOR_WHITE and boardstate.info.whiteKingMoved = '0') then
                  if (boardstate.info.whiteRook1Moved = '0') then
                     if (board(7, 1)(2 downto 0) = FIGURE_NULL and board(7, 2)(2 downto 0) = FIGURE_NULL and board(7, 3)(2 downto 0) = FIGURE_NULL) then
                        castlingLeft <= '1';
                     end if;
                  end if;
                  if (boardstate.info.whiteRook2Moved = '0') then
                     if (board(7, 5)(2 downto 0) = FIGURE_NULL and board(7, 6)(2 downto 0) = FIGURE_NULL) then
                        castlingRight <= '1';
                        castlingRight <= '1';
                     end if;
                  end if;
               end if;
               if (color = COLOR_BLACK and boardstate.info.blackKingMoved = '0') then
                  if (boardstate.info.blackRook1Moved = '0') then
                     if (board(0, 1)(2 downto 0) = FIGURE_NULL and board(0, 2)(2 downto 0) = FIGURE_NULL and board(0, 3)(2 downto 0) = FIGURE_NULL) then
                        castlingLeft <= '1';
                     end if;
                  end if;
                  if (boardstate.info.blackRook2Moved = '0') then
                     if (board(0, 5)(2 downto 0) = FIGURE_NULL and board(0, 6)(2 downto 0) = FIGURE_NULL) then
                        castlingRight <= '1';
                     end if;
                  end if;
               end if;
               
            when CASTLINGSAVELEFT =>
               if (castlingLeft = '1') then
                  fieldSaveStart <= '1';
                  state          <= CASTLINGWAITCHECK;
               else
                  state         <= CASTLINGSAVERIGHT;
                  castling_posX <= 4;
               end if;
            
            when CASTLINGSAVERIGHT =>
               if (castlingRight = '1') then
                  fieldSaveStart <= '1';
                  state         <= CASTLINGWAITCHECK;
               else
                  state         <= CHECKKINGSAVESTART;
               end if;
               
            when CASTLINGWAITCHECK =>
               if (fieldSaveDone = '1') then
                  castling_posX  <= castling_posX + 1; 
                  if (castlingLeft = '1') then
                     if (fieldSaveSave = '0') then
                        state         <= CASTLINGSAVERIGHT;
                        castling_posX <= 4;
                        castlingLeft  <= '0';
                     elsif (castling_posX = 4) then
                        state         <= CASTLINGSAVERIGHT;
                        castling_posX <= 4;
                        castlingLeft  <= '0';
                        moves(castling_posY, 2) <= '1';
                     else
                        state <= CASTLINGSAVELEFT;
                     end if;
                  else
                     if (fieldSaveSave = '0') then
                        state <= CHECKKINGSAVESTART;
                     elsif (castling_posX = 6) then
                        state <= CHECKKINGSAVESTART;
                        moves(castling_posY, 6) <= '1';
                     else
                        state <= CASTLINGSAVERIGHT;
                     end if;
                  end if;
               end if;
            
            when CHECKKINGSAVESTART =>
               checkmoves <= moves;
               state      <= CHECKKINGSAVE;
               
            when CHECKKINGSAVE =>
               if (checkMoves = NOMOVES) then
                  done  <= '1';
                  state <= IDLE;
                  if (moves = NOMOVES) then
                     noMove <= '1';
                  else
                     noMove <= '0';
                  end if;
               elsif (checkMoves(posTo.y, posTo.x) = '1') then
                  state                        <= WAITCHECK;
                  fieldSaveStart               <= '1';
                  checkMoves(posTo.y, posTo.x) <= '0';
               else
                  for iy in 7 downto 0 loop
                     for ix in 7 downto 0 loop
                        if (checkMoves(iy, ix) = '1') then
                           posTo.x <= ix;
                           posTo.y <= iy;
                        end if;
                     end loop;
                  end loop;
               end if;
               
            when WAITCHECK =>
               if (fieldSaveDone = '1') then
                  if (fieldSaveSave = '0') then
                     moves(posTo.y, posTo.x) <= '0';
                  end if;
                  state  <= CHECKKINGSAVE;
                  for iy in 7 downto 0 loop
                     for ix in 7 downto 0 loop
                        if (checkMoves(iy, ix) = '1') then
                           posTo.x <= ix;
                           posTo.y <= iy;
                        end if;
                     end loop;
                  end loop;
               end if;
               
         
         end case;

      end if;
   end process;     
   
end architecture; 