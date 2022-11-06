library IEEE;
use IEEE.std_logic_1164.all;  
use IEEE.numeric_std.all;     

package pChess is

   constant COLOR_WHITE   : std_logic := '0';
   constant COLOR_BLACK   : std_logic := '1';

   constant FIGURE_NULL   : std_logic_vector(2 downto 0) := "000";
   constant FIGURE_PAWN   : std_logic_vector(2 downto 0) := "001";
   constant FIGURE_KNIGHT : std_logic_vector(2 downto 0) := "010";
   constant FIGURE_BISHOP : std_logic_vector(2 downto 0) := "011";
   constant FIGURE_ROOK   : std_logic_vector(2 downto 0) := "100";
   constant FIGURE_QUEEN  : std_logic_vector(2 downto 0) := "101";
   constant FIGURE_KING   : std_logic_vector(2 downto 0) := "110";

   constant FIGURE_EMPTY        : std_logic_vector(3 downto 0) := "0000";
   constant FIGURE_WHITE_PAWN   : std_logic_vector(3 downto 0) := "0001";
   constant FIGURE_WHITE_KNIGHT : std_logic_vector(3 downto 0) := "0010";
   constant FIGURE_WHITE_BISHOP : std_logic_vector(3 downto 0) := "0011";
   constant FIGURE_WHITE_ROOK   : std_logic_vector(3 downto 0) := "0100";
   constant FIGURE_WHITE_QUEEN  : std_logic_vector(3 downto 0) := "0101";
   constant FIGURE_WHITE_KING   : std_logic_vector(3 downto 0) := "0110";
   constant FIGURE_Black_PAWN   : std_logic_vector(3 downto 0) := "1001";
   constant FIGURE_Black_KNIGHT : std_logic_vector(3 downto 0) := "1010";
   constant FIGURE_Black_BISHOP : std_logic_vector(3 downto 0) := "1011";
   constant FIGURE_Black_ROOK   : std_logic_vector(3 downto 0) := "1100";
   constant FIGURE_Black_QUEEN  : std_logic_vector(3 downto 0) := "1101";
   constant FIGURE_Black_KING   : std_logic_vector(3 downto 0) := "1110";
   
   type tboard is array(0 to 7, 0 to 7) of std_logic_vector(3 downto 0);
   type tboardBit is array(0 to 7, 0 to 7) of std_logic;
   
   type tBoardInfo is record
      blackTurn       : std_logic;
      whiteKingMoved  : std_logic;
      whiteRook1Moved : std_logic;
      whiteRook2Moved : std_logic;
      blackKingMoved  : std_logic;
      blackRook1Moved : std_logic;
      blackRook2Moved : std_logic;
      allowEnPassant  : std_logic;
      enPassantColumn : integer range 0 to 7;
      enPassantRow    : integer range 0 to 7;
   end record;
   
   type tBoardState is record
      board : tboard;
      info  : tBoardInfo;
   end record;
   
   type tPosition is record
      x : integer range 0 to 7;
      y : integer range 0 to 7;
   end record;
   
   constant BOARDINIT : tboard := 
   (
      ("1100", "1010", "1011", "1101", "1110", "1011", "1010", "1100"),
      ("1001", "1001", "1001", "1001", "1001", "1001", "1001", "1001"),
      ("0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000"),
      ("0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000"),
      ("0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000"),
      ("0000", "0000", "0000", "0000", "0000", "0000", "0000", "0000"),
      ("0001", "0001", "0001", "0001", "0001", "0001", "0001", "0001"),
      ("0100", "0010", "0011", "0101", "0110", "0011", "0010", "0100")
   );
   
   constant INFOINIT : tBoardInfo := 
   (
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      '0',
      0,
      0
   );
   
   constant NOMOVES : tboardBit := (others => (others => '0'));
   
end package;