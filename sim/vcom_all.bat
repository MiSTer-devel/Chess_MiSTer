RMDIR /s /q work
vlib work

vcom -2008 -O5 -vopt -quiet -work work ^
../rtl/pChess.vhd ^
../rtl/VGAOut.vhd ^
../rtl/tile_0.vhd ^
../rtl/tile_1.vhd ^
../rtl/white_pawn_60.vhd ^
../rtl/white_knight_60.vhd ^
../rtl/white_bishop_60.vhd ^
../rtl/white_rook_60.vhd ^
../rtl/white_queen_60.vhd ^
../rtl/white_king_60.vhd ^
../rtl/white_mister_60.vhd ^
../rtl/black_pawn_60.vhd ^
../rtl/black_knight_60.vhd ^
../rtl/black_bishop_60.vhd ^
../rtl/black_rook_60.vhd ^
../rtl/black_queen_60.vhd ^
../rtl/black_king_60.vhd ^
../rtl/black_mister_60.vhd ^
../rtl/Drawer.vhd ^
../rtl/ExecuteMove.vhd ^
../rtl/CheckFieldSave.vhd ^
../rtl/CheckMoves.vhd ^
../rtl/Evalboard.vhd ^
../rtl/Minimax.vhd ^
../rtl/Opponent.vhd ^
../rtl/Control.vhd ^
../rtl/overlay.vhd ^
../rtl/Progressbar.vhd ^
../rtl/TopModule.vhd

vcom -2008 -O5 -vopt -quiet -work work ^
globals.vhd ^
stringprocessor.vhd ^
tb.vhd

