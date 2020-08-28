module emu
(
	//Master input clock
	input         CLK_50M,

	//Async reset from top-level module.
	//Can be used as initial reset.
	input         RESET,

	//Must be passed to hps_io module
	inout  [45:0] HPS_BUS,

	//Base video clock. Usually equals to CLK_SYS.
	output        CLK_VIDEO,

	//Multiple resolutions are supported using different CE_PIXEL rates.
	//Must be based on CLK_VIDEO
	output        CE_PIXEL,

	//Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
	output  [7:0] VIDEO_ARX,
	output  [7:0] VIDEO_ARY,

	output  [7:0] VGA_R,
	output  [7:0] VGA_G,
	output  [7:0] VGA_B,
	output        VGA_HS,
	output        VGA_VS,
	output        VGA_DE,    // = ~(VBlank | HBlank)
	output        VGA_F1,
	output  [1:0] VGA_SL,

	output        LED_USER,  // 1 - ON, 0 - OFF.

	// b[1]: 0 - LED status is system status OR'd with b[0]
	//       1 - LED status is controled solely by b[0]
	// hint: supply 2'b00 to let the system control the LED.
	output  [1:0] LED_POWER,
	output  [1:0] LED_DISK,

	// I/O board button press simulation (active high)
	// b[1]: user button
	// b[0]: osd button
	output  [1:0] BUTTONS,

	output [15:0] AUDIO_L,
	output [15:0] AUDIO_R,
	output        AUDIO_S, // 1 - signed audio samples, 0 - unsigned
	output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

	//ADC
	inout   [3:0] ADC_BUS,

	//SD-SPI
	output        SD_SCK,
	output        SD_MOSI,
	input         SD_MISO,
	output        SD_CS,
	input         SD_CD,

	//High latency DDR3 RAM interface
	//Use for non-critical time purposes
	output        DDRAM_CLK,
	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	//SDRAM interface with lower latency
	output        SDRAM_CLK,
	output        SDRAM_CKE,
	output [12:0] SDRAM_A,
	output  [1:0] SDRAM_BA,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nCS,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nWE,

	input         UART_CTS,
	output        UART_RTS,
	input         UART_RXD,
	output        UART_TXD,
	output        UART_DTR,
	input         UART_DSR,

	// Open-drain User port.
	// 0 - D+/RX
	// 1 - D-/TX
	// 2..6 - USR2..USR6
	// Set USER_OUT to 1 to read from USER_IN.
	input   [6:0] USER_IN,
	output  [6:0] USER_OUT,

	input         OSD_STATUS
);

assign ADC_BUS  = 'Z;
assign USER_OUT = '1;

assign AUDIO_S   = 0;
assign AUDIO_L   = audio;
assign AUDIO_R   = AUDIO_L;
assign AUDIO_MIX = 0;

assign LED_USER  = 0;
assign LED_DISK  = 0;
assign LED_POWER = 0;
assign BUTTONS   = 0;

assign VIDEO_ARX = status[8] ? 8'd16 : 8'd4;
assign VIDEO_ARY = status[8] ? 8'd9  : 8'd3;

assign VGA_F1 = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CKE, SDRAM_CLK, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;

`include "build_id.v"
parameter CONF_STR = {
	"Chess;;",
	"-;",
	"O7,Opponent,AI,Human;",
	"O46,AI Strength,1,2,3,4,5,6,7;",
	"O23,AI Randomness,0,1,2,3;",
	"O1,Player Color,White,Black;",
	"O9,Boardview,White,Black;",
	"OA,Overlay,Off,On;",
   "-;",
	"O8,Aspect Ratio,4:3,16:9;",
	"-;",
	"R0,Reset;",
	"J1,Action,Cancel,SaveState,LoadState,Rewind;",
	"jn,A,B;",
	"jp,A,B;",
	"V,v",`BUILD_DATE
};

wire reset = RESET | status[0] | buttons[1];

wire [21:0] gamma_bus;
wire [63:0] status;

wire [2:0] buttons;
wire [15:0] joyA;

hps_io #(.STRLEN(($size(CONF_STR)>>3))) hps_io
(
	.clk_sys(clk),
	.HPS_BUS(HPS_BUS),
	.conf_str(CONF_STR),

	.buttons(buttons),

	.joystick_0(joyA),

	.status(status),
	.gamma_bus(gamma_bus)
);


wire clk;

pll pll
(
	.refclk(CLK_50M),
	.outclk_0(clk)
);

wire [15:0] audio = {1'b0, speaker, 14'd0};
wire speaker;

wire vsync, hsync, vblank, hblank;
wire [7:0] red, green, blue;

TopModule Chess (
	.Clk(clk),
	.reset(reset),
   .mirrorBoard(status[9]),
   .aiOn(~status[7]),
   .strength(status[6:4]),
   .randomness(status[3:2]),
   .playerBlack(status[1]),
   .overlayOn(status[10]),
   .input_up(joyA[3]),
   .input_down(joyA[2]),
   .input_left(joyA[1]),
   .input_right(joyA[0]),
   .input_action(joyA[4]),
   .input_cancel(joyA[5]),
   .input_save(joyA[6]),
   .input_load(joyA[7]),
   .input_rewind(joyA[8]),
	.vga_h_sync(hsync),
	.vga_v_sync(vsync),
	.vga_h_blank(hblank),
	.vga_v_blank(vblank),
	.vga_R(red),
	.vga_G(green),
	.vga_B(blue),
	.Speaker(speaker)
);

assign VGA_F1 = 0;
assign VGA_SL = 0;
assign CLK_VIDEO = clk;
assign CE_PIXEL = 1;

gamma_fast gamma
(
	.clk_vid(CLK_VIDEO),
	.ce_pix(1),

	.gamma_bus(gamma_bus),

	.HSync(hsync),
	.VSync(vsync),
	.DE(~(hblank | vblank)),
	.RGB_in({red, green, blue}),

	.HSync_out(VGA_HS),
	.VSync_out(VGA_VS),
	.DE_out(VGA_DE),
	.RGB_out({VGA_R, VGA_G, VGA_B})
);


endmodule

