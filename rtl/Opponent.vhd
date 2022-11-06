library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;   

use work.pChess.all;

entity Opponent is
   generic(
      DEPTH : integer := 7
   );
   port 
   (
      Clk            : in     std_logic;  
      start          : in     std_logic;  
      done           : out    std_logic := '0';
      progress       : out    integer range 0 to 63;
                     
      strength       : in     integer range 1 to DEPTH;
      randomness     : in     integer range 0 to 3;
                     
      boardstate     : in     tBoardState;
      moveFrom       : out    tPosition;
      moveTo         : out    tPosition;
      noMovePossible : out    std_logic
   );
end entity;

architecture arch of Opponent is

   -- check moves
   signal boardstateAct   : tBoardState;
   signal checkPos        : tPosition;
   signal checkMovesStart : std_logic;
   signal checkMovesDone  : std_logic;
   signal checkedMoves    : tboardBit;
   signal noMove          : std_logic;
   
   signal check_idle      : std_logic := '1';
   signal check_buffer    : std_logic_vector(1 to DEPTH) := (others => '0');
   signal check_mux       : integer range 1 to DEPTH;

   -- evalboard
   signal EvalboardStart  : std_logic;
   signal EvalboardDone   : std_logic;
   signal EvalboardValue  : integer range -32768 to 32767;
   signal EvalboardState  : tBoardState;
   
   -- minimax
   type tBoardStateArray    is array(1 to DEPTH) of tBoardState;
   type tBoardScoreArray    is array(1 to DEPTH) of integer range -32768 to 32767;
   type tBoardProgressArray is array(1 to DEPTH) of integer range 0 to 63;
   type tBoardPosArray      is array(1 to DEPTH) of tPosition;
   
   signal MinimaxStart          : std_logic_vector(1 to DEPTH);
   signal MinimaxDone           : std_logic_vector(1 to DEPTH);
   signal MinimaxProgress       : tBoardProgressArray;
                                
   signal MinimaxNextStart      : std_logic_vector(1 to DEPTH);
   signal MinimaxNextDone       : std_logic_vector(1 to DEPTH);
   signal MinimaxNextScore      : tBoardScoreArray;
                                
   signal MinimaxAlpha_in       : tBoardScoreArray;
   signal MinimaxBeta_in        : tBoardScoreArray;
   signal MinimaxAlpha_out      : tBoardScoreArray;
   signal MinimaxBeta_out       : tBoardScoreArray;
                                
   signal MinimaxCheckPos       : tBoardPosArray;
   signal MinimaxCheckStart     : std_logic_vector(1 to DEPTH);
   signal MinimaxCheckDone      : std_logic_vector(1 to DEPTH);
   signal MinimaxNoMovePossible : std_logic_vector(1 to DEPTH);
   
   signal MinimaxMovePos        : tBoardPosArray;
   signal MinimaxEvalStart      : std_logic_vector(1 to DEPTH);
                                
   signal MinimaxStateIn        : tBoardStateArray;
   signal MinimaxStateOut       : tBoardStateArray;
   signal MinimaxScore          : tBoardScoreArray;
   signal MinimaxFrom           : tBoardPosArray;
   signal MinimaxTo             : tBoardPosArray;

begin

   boardstateAct <= MinimaxStateIn(check_mux);
   checkPos      <= MinimaxCheckPos(check_mux);

   iCheckMoves : entity work.CheckMoves
   port map
   (
      Clk           => Clk,
      start         => checkMovesStart,
      done          => checkMovesDone,  
      boardstate    => boardstateAct,
      checkPos      => checkPos,
      moves         => checkedMoves,
      noMove        => noMove
   );
   
   EvalboardStart <= MinimaxEvalStart(strength);
   EvalboardState <= MinimaxStateOut(strength);
   
   iEvalboard : entity work.Evalboard
   port map
   (
      Clk           => Clk,
      randomness    => randomness,
      start         => EvalboardStart,
      done          => EvalboardDone,
      boardvalue    => EvalboardValue,
      boardstate    => EvalboardState,
      calccount     => open
   );
   
   MinimaxStateIn(1) <= boardstate;
   
   gMinimax: for i in 1 to DEPTH generate
   begin
   
      iMinimax : entity work.Minimax
      generic map
      ( 
         LEVEL => i
      )
      port map
      (
         Clk             => Clk,
         start           => MinimaxStart(i),
         done            => MinimaxDone(i),
         progress        => MinimaxProgress(i),
        
         stoplevel       => strength,
         NextStart       => MinimaxNextStart(i),
         NextDone        => MinimaxNextDone(i), 
         NextScore       => MinimaxNextScore(i),
         
         alpha_in        => MinimaxAlpha_in(i),
         beta_in         => MinimaxBeta_in(i),  
         alpha_out       => MinimaxAlpha_out(i),
         beta_out        => MinimaxBeta_out(i), 
         
         checkPos        => MinimaxCheckPos(i), 
         checkMovesStart => MinimaxCheckStart(i),
         checkMovesDone  => MinimaxCheckDone(i),
         checkedMoves_in => checkedMoves,        
         checkedNone     => noMove,     
         noMovePossible  => MinimaxNoMovePossible(i),
         
         EvalboardStart  => MinimaxEvalStart(i),
         EvalboardDone   => EvalboardDone, 
         EvalboardValue  => EvalboardValue,     
         
         boardstate_in   => MinimaxStateIn(i),
         boardstate_out  => MinimaxStateOut(i),
         bestScore       => MinimaxScore(i),
         bestFrom        => MinimaxFrom(i),
         bestTo          => MinimaxTo(i)
      );
      
      MinimaxCheckDone(i) <= '1' when (checkMovesDone = '1' and check_mux = i) else '0';
      
   end generate;
   
   gmultiLayer : if DEPTH > 1 generate
   begin
      gLinkMinimax: for i in 2 to DEPTH generate
      begin
   
         MinimaxStateIn(i)       <= MinimaxStateOut(i - 1);
         MinimaxStart(i)         <= MinimaxNextStart(i - 1);
         MinimaxNextDone(i - 1)  <= MinimaxDone(i);
         MinimaxNextScore(i - 1) <= MinimaxScore(i);
         MinimaxAlpha_in(i)      <= MinimaxAlpha_out(i - 1);
         MinimaxBeta_in(i)       <= MinimaxBeta_out(i - 1);
         
      end generate;
   end generate;

   
   MinimaxStart(1)    <= start;
   done               <= MinimaxDone(1);
   moveFrom           <= MinimaxFrom(1);
   moveTo             <= MinimaxTo(1);
   MinimaxAlpha_in(1) <= -32768;
   MinimaxBeta_in(1)  <= 32767;
   noMovePossible     <= MinimaxNoMovePossible(1);
   progress           <= MinimaxProgress(1);
   
      
   process (Clk)
      variable check_buffer_new : std_logic_vector(1 to DEPTH);
   begin
      if rising_edge(Clk) then
      
         checkMovesStart  <= '0';
      
         check_buffer_new := check_buffer or MinimaxCheckStart;
          if (checkMovesDone = '1') then
            check_buffer_new(check_mux) := '0';
            check_idle                  <= '1';
         end if;
         check_buffer <= check_buffer_new;
         
         for i in 1 to DEPTH loop
            if ((check_idle = '1' or checkMovesDone = '1') and check_buffer_new(i) = '1') then
               check_idle      <= '0';
               checkMovesStart <= '1';
               check_mux       <= i;
            end if;
         end loop;
      
      end if;
   end process;   
   
   
end architecture; 