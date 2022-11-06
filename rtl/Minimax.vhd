library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity Minimax is
   generic
   (
      LEVEL : integer range 0 to 15
   );
   port 
   (
      Clk             : in     std_logic;  
      start           : in     std_logic;  
      done            : out    std_logic := '0';
      progress        : out    integer range 0 to 63 := 0;
      
      stoplevel       : in     integer range 0 to 15;
      NextStart       : out    std_logic := '0';
      NextDone        : in     std_logic;
      NextScore       : in     integer range -32768 to 32767;
      
      alpha_in        : in     integer range -32768 to 32767;
      beta_in         : in     integer range -32768 to 32767;
      alpha_out       : out    integer range -32768 to 32767;
      beta_out        : out    integer range -32768 to 32767;
      
      checkPos        : buffer tPosition;
      checkMovesStart : out    std_logic := '0';
      checkMovesDone  : in     std_logic;
      checkedMoves_in : in     tboardBit;
      checkedNone     : in     std_logic;
      noMovePossible  : out    std_logic := '0';
      
      EvalboardStart  : out    std_logic := '0';
      EvalboardDone   : in     std_logic;
      EvalboardValue  : in     integer range -32768 to 32767;     
      
      boardstate_in   : in     tBoardState;
      boardstate_out  : out    tBoardState;
      bestScore       : buffer integer range -32768 to 32767;  
      bestFrom        : out    tPosition;
      bestTo          : out    tPosition
   );
end entity;

architecture arch of Minimax is

   signal board : tboard;
   signal info  : tBoardInfo;

   type tFindState is
   (
      IDLE,
      FINDPIECE,
      WAITMOVES,
      MOVESDONE,
      WAITFINISH
   );
   signal findState : tFindState;
   
   type tmoveState is
   (
      REQUESTMOVES,
      FINDMOVE,
      EVALBOARD,
      EVALNEXT
   );
   signal moveState : tmoveState;
   
   signal newSearchFind    : std_logic;
   signal newSearchMove    : std_logic;
                           
   signal checkPiece       : tboardBit;
   signal checkedMovesFind : tboardBit;
   signal checkedMoves     : tboardBit;
                           
   signal movePos          : tPosition;
   signal boardstate_new   : tBoardState;
   signal checkPosMove     : tPosition;
                           
   signal alpha            : integer range -32768 to 32767;
   signal beta             : integer range -32768 to 32767;
   signal alphabetaSkip    : std_logic := '0';
   
begin

   board <= boardstate_in.board;
   info  <= boardstate_in.info;
   
   alpha_out <= alpha;
   beta_out  <= beta;
   
   process (Clk)
   begin
      if rising_edge(Clk) then
      
         done            <= '0';
         checkMovesStart <= '0';
         
         case (findState) is
         
            when IDLE =>
               if (start = '1') then
                  findState       <= FINDPIECE;
                  checkPos        <= (0, 0);
                  newSearchFind   <= '0';
                  checkPiece      <= NOMOVES;
                  noMovePossible  <= '1';
                  progress        <= 0;
                  for iy in 7 downto 0 loop
                     for ix in 7 downto 0 loop
                        if (board(iy, ix)(2 downto 0) /= FIGURE_NULL and board(iy, ix)(3) = info.blackTurn) then
                           checkPiece(iy, ix) <= '1';
                        end if;
                     end loop;
                  end loop;
               end if;
               
            when FINDPIECE =>
               if (checkPiece = NOMOVES) then
                  progress  <= 63;
                  findState <= WAITFINISH;
               elsif (newSearchFind = '0' and checkPiece(checkPos.y, checkPos.x) = '1') then
                  progress <= checkPos.y * 8 + checkPos.x;
                  checkPiece(checkPos.y, checkPos.x)  <= '0';
                  checkMovesStart <= '1';
                  findState       <= WAITMOVES;
               else
                  newSearchFind <= '0';
                  for iy in 7 downto 0 loop
                     for ix in 7 downto 0 loop
                        if (checkPiece(iy, ix) = '1') then
                           checkPos.x <= ix;
                           checkPos.y <= iy;
                        end if;
                     end loop;
                  end loop;
               end if;
               
            when WAITMOVES =>
               if (checkMovesDone = '1') then
                  checkedMovesFind <= checkedMoves_in;
                  if (checkedNone = '1') then
                     findState     <= FINDPIECE;
                     newSearchFind <= '1';
                  else
                     findState      <= MOVESDONE;
                     noMovePossible <= '0';
                  end if;
               end if;
               
            when MOVESDONE =>
               if (alphabetaSkip = '1') then
                  findState     <= IDLE;
                  done          <= '1';
               elsif (moveState = REQUESTMOVES) then
                  findState     <= FINDPIECE;
                  newSearchFind <= '1';
               end if;
               
            when WAITFINISH =>
               if (moveState = REQUESTMOVES) then
                  done           <= '1';
                  findState      <= IDLE;
               end if;
               
         end case;
                  

      end if;
   end process; 
   
   iExecuteMove : entity work.ExecuteMove
   port map
   (
      state_in  => boardstate_in,
      posFrom   => checkPosMove,
      posTo     => movePos,
      state_out => boardstate_new
   );
   
   process (Clk)
      variable newAlpha : integer range -32768 to 32767;
      variable newBeta  : integer range -32768 to 32767;
   begin
      if rising_edge(Clk) then
         
         EvalboardStart  <= '0';
         NextStart       <= '0';
         
         if (start = '1') then
         
            moveState       <= REQUESTMOVES;
            alphabetaSkip   <= '0';
            alpha           <= alpha_in;
            beta            <= beta_in; 
            if (boardstate_in.info.blackTurn = '1') then
               bestScore <= 32000;
            else
               bestScore <= -32000;
            end if;
            
            if (moveState /= REQUESTMOVES) then
               report "should never happen" severity failure; 
            end if;
            
         else
         
            case (moveState) is
            
               when REQUESTMOVES =>
                  movePos       <= (0, 0);
                  checkedMoves <= checkedMovesFind;
                  checkPosMove <= checkPos;
                  newSearchMove <= '0';
                  if (findState = MOVESDONE and alphabetaSkip = '0') then
                     moveState    <= FINDMOVE;
                  end if;  
                     
               when FINDMOVE =>
                  boardstate_out <= boardstate_new;
                  if (checkedMoves = NOMOVES) then
                     moveState <= REQUESTMOVES;
                  elsif (newSearchMove = '0' and checkedMoves(movePos.y, movePos.x) = '1') then
                     checkedMoves(movePos.y, movePos.x)  <= '0';
                     if (LEVEL = stoplevel) then
                        EvalboardStart <= '1';
                        moveState      <= EVALBOARD;
                     else
                        NextStart      <= '1';
                        moveState      <= EVALNEXT;
                     end if;
                  else
                     newSearchMove <= '0';
                     for iy in 7 downto 0 loop
                        for ix in 7 downto 0 loop
                           if (checkedMoves(iy, ix) = '1') then
                              movePos.x <= ix;
                              movePos.y <= iy;
                           end if;
                        end loop;
                     end loop;
                  end if;
                  
               when EVALBOARD =>
                  if (EvalboardDone = '1') then
                     moveState      <= FINDMOVE;
                     newSearchMove  <= '1';
                     if ((info.blackTurn = '0' and EvalboardValue > bestScore) or (info.blackTurn = '1' and EvalboardValue < bestScore)) then
                        bestScore <= EvalboardValue;
                        bestFrom  <= checkPosMove;
                        bestTo    <= movePos;
                     end if;
                     -- alphabeta
                     if (info.blackTurn = '0') then
                        newAlpha := alpha;
                        if (EvalboardValue > bestScore) then
                           newAlpha := EvalboardValue;
                        end if;
                        if (beta <= newAlpha and level > 1) then
                           alphabetaSkip  <= '1';
                           moveState      <= REQUESTMOVES;
                        end if;
                        alpha <= newAlpha;
                     else
                        newBeta := beta;
                        if (EvalboardValue < bestScore) then
                           newBeta := EvalboardValue;
                        end if;
                        if (newBeta <= alpha and level > 1) then
                           alphabetaSkip  <= '1';
                           moveState      <= REQUESTMOVES;
                        end if;
                        beta <= newBeta;
                     end if;
                  end if;             
                  
               when EVALNEXT =>
                  if (NextDone = '1') then
                     moveState      <= FINDMOVE;
                     newSearchMove  <= '1';
                     if ((info.blackTurn = '0' and NextScore > bestScore) or (info.blackTurn = '1' and NextScore < bestScore)) then
                        bestScore <= NextScore;
                        bestFrom  <= checkPosMove;
                        bestTo    <= movePos;
                     end if;
                     -- alphabeta
                     if (info.blackTurn = '0') then
                        newAlpha := alpha;
                        if (NextScore > bestScore) then
                           newAlpha := NextScore;
                        end if;
                        if (beta <= newAlpha and level > 1) then
                           alphabetaSkip  <= '1';
                           moveState      <= REQUESTMOVES;
                        end if;
                        alpha <= newAlpha;
                     else
                        newBeta := beta;
                        if (NextScore < bestScore) then
                           newBeta := NextScore;
                        end if;
                        if (newBeta <= alpha and level > 1) then
                           alphabetaSkip  <= '1';
                           moveState      <= REQUESTMOVES;
                        end if;
                        beta <= newBeta;
                     end if;
                  end if; 
   
            end case;
         
         end if;

      end if;
   end process;     
   
end architecture; 