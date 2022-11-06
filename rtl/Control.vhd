library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity Control is
   port 
   (
      Clk          : in     std_logic;  
      reset        : in     std_logic;
      
      mirrorBoard  : in     std_logic;
      aiOn         : in     std_logic;
      strength     : in     integer range 0 to 15;
      randomness   : in     integer range 0 to 3;
      playerBlack  : in     std_logic;
                   
      input_up     : in     std_logic;  
      input_down   : in     std_logic;  
      input_left   : in     std_logic;  
      input_right  : in     std_logic;  
      input_action : in     std_logic;  
      input_cancel : in     std_logic;  
      input_save   : in     std_logic;  
      input_load   : in     std_logic;  
      input_rewind : in     std_logic;       
                   
      boardState   : buffer tBoardState := (BOARDINIT, INFOINIT);
      cursor       : buffer tPosition;
      markedCells  : buffer tboardBit;
      markedPos    : buffer tPosition;
      markedPosOn  : buffer std_logic;
      cheated      : out    std_logic := '0';
      
      lastOn       : out    std_logic := '0';
      lastFrom     : out    tPosition;
      lastTo       : out    tPosition;
      
      progress     : out    integer range 0 to 63;
      
      checkMate    : out    std_logic := '0';
      check        : buffer std_logic := '0';
      draw         : out    std_logic := '0'
   );
end entity;

architecture arch of Control is

   type tState is
   (
      CHECKCHECK,
      WAITCHECK,
      CHECKNOMOVE,
      PLAYERSELECTPIECE,
      FINDTARGETPOSITIONS,
      PLAYERSELECTTARGET,
      AIMOVE
   );
   signal state : tstate;
   
   signal up_corrected     : std_logic := '0';    
   signal down_corrected   : std_logic := '0';    
   signal left_corrected   : std_logic := '0';    
   signal right_corrected  : std_logic := '0';    
   
   signal input_up_1       : std_logic := '0';    
   signal input_down_1     : std_logic := '0';    
   signal input_left_1     : std_logic := '0';    
   signal input_right_1    : std_logic := '0';   
   signal input_action_1   : std_logic := '0';  
   signal input_cancel_1   : std_logic := '0'; 
   signal input_save_1     : std_logic := '0';  
   signal input_load_1     : std_logic := '0';  
   signal input_rewind_1   : std_logic := '0';     
                           
   signal checkMovesStart  : std_logic := '0';
   signal checkMovesDone   : std_logic;
   signal checkedMoves     : tboardBit;
   signal noMove           : std_logic;
                           
   signal ExecuteFrom      : tPosition;
   signal ExecuteTo        : tPosition;
   signal movedState       : tBoardState;
                           
   signal OpponentStart    : std_logic := '0';  
   signal OpponentDone     : std_logic;
   signal OpponentFrom     : tPosition;
   signal OpponentTo       : tPosition;
   signal OpponentStrength : integer range 1 to 15;
   signal OpponentNoMove   : std_logic;
   
   signal kingPos          : tPosition;
   signal fieldSaveStart   : std_logic := '0';
   signal fieldSaveDone    : std_logic;
   signal fieldSaveSave    : std_logic;
   signal fieldSaveBlack   : std_logic;

   signal saveState        : tBoardState;
   signal saveStateValid   : std_logic := '0';
   signal lastState        : tBoardState;
   signal lastStateValid   : std_logic := '0';
   
begin

   up_corrected    <= input_up    when mirrorBoard = '0' else input_down;
   down_corrected  <= input_down  when mirrorBoard = '0' else input_up;
   left_corrected  <= input_left  when mirrorBoard = '0' else input_right;
   right_corrected <= input_right when mirrorBoard = '0' else input_left;
   
   iCheckMoves : entity work.CheckMoves
   port map
   (
      Clk           => Clk,
      start         => checkMovesStart,
      done          => checkMovesDone,  
      boardstate    => boardstate,
      checkPos      => markedpos,
      moves         => checkedMoves,
      noMove        => noMove
   );

   iExecuteMove : entity work.ExecuteMove
   port map
   (
      state_in  => boardstate,
      posFrom   => ExecuteFrom,
      posTo     => ExecuteTo,
      state_out => movedState
   );
   
   ExecuteFrom <= OpponentFrom when state = AIMOVE else markedpos;
   ExecuteTo   <= OpponentTo   when state = AIMOVE else cursor;
   
   iOpponent: entity work.Opponent
   port map
   (
      Clk             => Clk, 
      start           => OpponentStart,
      done            => OpponentDone, 
      progress        => progress,
      strength        => OpponentStrength,
      randomness      => randomness,
      boardstate      => boardstate,   
      moveFrom        => OpponentFrom, 
      moveTo          => OpponentTo,    
      noMovePossible  => OpponentNoMove    
   );

   iCheckFieldSave : entity work.CheckFieldSave
   port map
   (
      Clk           => Clk,
      start         => fieldSaveStart,
      done          => fieldSaveDone,
      save          => fieldSaveSave,
         
      boardstate    => boardstate,
      blackTurn     => fieldSaveBlack,
      checkPos      => kingPos
   );

   process (Clk)
   begin
      if rising_edge(Clk) then
      
         input_up_1     <= up_corrected;
         input_down_1   <= down_corrected; 
         input_left_1   <= left_corrected;  
         input_right_1  <= right_corrected; 
         input_action_1 <= input_action;
         input_cancel_1 <= input_cancel;
         input_save_1   <= input_save;  
         input_load_1   <= input_load;  
         input_rewind_1 <= input_rewind;
         
         checkMovesStart <= '0';
         OpponentStart   <= '0';
         
         fieldSaveStart  <= '0';
         
         if (reset = '1') then
         
            state       <= CHECKCHECK;
         
            boardstate.board <= BOARDINIT;
            boardstate.info  <= INFOINIT;
            cursor           <= (4, 6);
            markedCells      <= (others => (others => '0'));
            markedPosOn      <= '0';
            
            checkMate        <= '0';
            check            <= '0';
            draw             <= '0';
            
            lastOn           <= '0';
            
            lastStateValid   <= '0';
            
            cheated          <= '0';
            
         else
         
            case (state) is
            
               when CHECKCHECK =>
                  state <= WAITCHECK;
                  fieldSaveStart <= '1';
                  fieldSaveBlack <= not boardstate.info.blackTurn;
                  for x in 0 to 7 loop
                     for y in 0 to 7 loop
                        if (boardstate.board(y,x)(2 downto 0) = FIGURE_KING and boardstate.board(y,x)(3) = boardstate.info.blackTurn) then
                           kingPos.x <= x;
                           kingPos.y <= y;
                        end if;                     
                     end loop;
                  end loop;
                  
               when WAITCHECK =>
                  if (fieldSaveDone = '1') then
                     check            <= not fieldSaveSave;
                     state            <= CHECKNOMOVE;
                     OpponentStart    <= '1';
                     OpponentStrength <= 1;
                  end if;
                  
               when CHECKNOMOVE =>
                  if (OpponentDone = '1') then
                     checkMate <= OpponentNoMove and check;
                     draw      <= OpponentNoMove and not check;
                     if (OpponentNoMove = '0') then
                        if (aiOn = '1' and boardstate.info.blackTurn /= playerBlack) then
                           state            <= AIMOVE;
                           OpponentStart    <= '1';
                           OpponentStrength <= strength + 1;
                        else
                           state            <= PLAYERSELECTPIECE;
                        end if;
                     end if;
                  end if; 
            
               when PLAYERSELECTPIECE =>
                  if (up_corrected    = '1' and input_up_1    = '0' and cursor.y > 0) then cursor.y <= cursor.y - 1; end if;
                  if (down_corrected  = '1' and input_down_1  = '0' and cursor.y < 7) then cursor.y <= cursor.y + 1; end if;
                  if (left_corrected  = '1' and input_left_1  = '0' and cursor.x > 0) then cursor.x <= cursor.x - 1; end if;
                  if (right_corrected = '1' and input_right_1 = '0' and cursor.x < 7) then cursor.x <= cursor.x + 1; end if;
                  if (input_save = '1' and input_save_1 = '0') then
                     saveStateValid <= '1';
                     saveState      <= boardState;
                  end if;
                  if (input_load = '1' and input_load_1 = '0' and saveStateValid = '1') then
                     boardState     <= saveState;
                     lastStateValid <= '0';
                     lastOn         <= '0';
                     cheated        <= '1';
                  end if;
                  if (input_rewind = '1' and input_rewind_1 = '0' and lastStateValid = '1') then
                     boardState     <= lastState;
                     lastStateValid <= '0';
                     lastOn         <= '0';
                     cheated        <= '1';
                  end if;
                  if (input_action_1 = '1' and input_action = '0') then
                     if (boardstate.board(cursor.y, cursor.x)(3) = boardstate.info.blackTurn) then
                        state           <= FINDTARGETPOSITIONS;
                        markedPosOn     <= '1';
                        markedpos       <= cursor;
                        checkMovesStart <= '1';
                     end if;
                  end if;
                  
               when FINDTARGETPOSITIONS =>
                  if (checkMovesDone = '1') then
                     state       <= PLAYERSELECTTARGET;
                     markedCells <= checkedMoves;
                     if (checkedMoves = NOMOVES) then
                        state       <= CHECKCHECK;
                        markedPosOn <= '0';
                     end if;
                  end if;
               
               when PLAYERSELECTTARGET =>
                  if (up_corrected    = '1' and input_up_1    = '0' and cursor.y > 0) then cursor.y <= cursor.y - 1; end if;
                  if (down_corrected  = '1' and input_down_1  = '0' and cursor.y < 7) then cursor.y <= cursor.y + 1; end if;
                  if (left_corrected  = '1' and input_left_1  = '0' and cursor.x > 0) then cursor.x <= cursor.x - 1; end if;
                  if (right_corrected = '1' and input_right_1 = '0' and cursor.x < 7) then cursor.x <= cursor.x + 1; end if;
                  if (input_save = '1' and input_save_1 = '0') then
                     saveStateValid <= '1';
                     saveState      <= boardState;
                  end if;
                  if (input_cancel_1 = '1' and input_cancel = '0') then
                     state       <= CHECKCHECK;
                     markedPosOn <= '0';
                     markedCells <= (others => (others => '0'));
                  end if;
                  if (input_action_1 = '1' and input_action = '0') then
                     if (markedCells(cursor.y, cursor.x) = '1') then
                        state          <= CHECKCHECK;
                        markedPosOn    <= '0';
                        markedCells    <= (others => (others => '0'));
                        boardstate     <= movedState;
                        lastOn         <= '1';
                        lastFrom       <= ExecuteFrom;
                        lastTo         <= ExecuteTo;
                        lastStateValid <= '1';
                        lastState      <= boardstate;
                     end if;
                  end if;
                  
               when AIMOVE =>
                  if (OpponentDone = '1') then
                     state       <= CHECKCHECK;
                     boardstate  <= movedState;
                     lastOn      <= '1';
                     lastFrom    <= ExecuteFrom;
                     lastTo      <= ExecuteTo;
                  end if;
            
            
            end case;
         
         end if;
         

      end if;
   end process;     
   
end architecture; 