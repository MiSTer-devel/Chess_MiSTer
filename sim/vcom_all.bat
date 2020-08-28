RMDIR /s /q work
vlib work

vcom -2008 -O5 -vopt -quiet -work work ^
../pChess.vhd ^
../VGAOut.vhd ^
../tile_0.vhd ^
../tile_1.vhd ^
../white_pawn_60.vhd ^
../white_knight_60.vhd ^
../white_bishop_60.vhd ^
../white_rook_60.vhd ^
../white_queen_60.vhd ^
../white_king_60.vhd ^
../white_mister_60.vhd ^
../black_pawn_60.vhd ^
../black_knight_60.vhd ^
../black_bishop_60.vhd ^
../black_rook_60.vhd ^
../black_queen_60.vhd ^
../black_king_60.vhd ^
../black_mister_60.vhd ^
../Drawer.vhd ^
../ExecuteMove.vhd ^
../CheckFieldSave.vhd ^
../CheckMoves.vhd ^
../Evalboard.vhd ^
../Minimax.vhd ^
../Opponent.vhd ^
../Control.vhd ^
../overlay.vhd ^
../Progressbar.vhd ^
../TopModule.vhd

vcom -2008 -O5 -vopt -quiet -work work ^
globals.vhd ^
stringprocessor.vhd ^
tb.vhd

