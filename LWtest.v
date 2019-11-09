// Copyright (c) 2019 MiSTer-X

module EMU_LW
(
	input				CLK50M,
	input				RESET,
	
	input  [15:0]	HID,

	output [17:0]	COLOR,
	output			HSYNC,
	output			VSYNC,
	
	output [15:0]	SND_L,
	output [15:0]	SND_R
);

// See for more details: sys_lw/ps2_key_hid.v
// HID = ~{ bRS, bCR, bS2, bS1, bT7, bT6, bT5, bT4, bT3, bT2, bT1, bT0, bRG, bLF, bDW, bUP };

wire TRIG0 = HID[4]; // PS/2 keyboard Z
wire TRIG1 = HID[5]; // PS/2 keyboard X


// Generate pixel clock & square wave tone
reg [16:0] clkdiv;
always @(posedge CLK50M) clkdiv <= clkdiv+1;

wire PCLK = clkdiv[2];	// 6.250MHz
wire SQW0 = clkdiv[15];	// 762.94Hz
wire SQW1 = clkdiv[16];	// 381.47Hz


// Color-Bar Generator
wire [8:0] HPOS,VPOS;
reg  [2:0] O;
reg  [5:0] W;
always @(posedge PCLK) begin
	if (HPOS==383)	 begin W <= 0; O <= 3'b111; end
	else if (W==40) begin W <= 0; O <= O-1;	 end
	else W <= W+1;
end
wire [17:0] iRGB = {{2{O[0]}},4'h0,{2{O[2]}},4'h0,{2{O[1]}},4'h0};


// HV Timing Generator & VGA output
HVGEN hv(
	.HPOS(HPOS),.VPOS(VPOS),.PCLK(PCLK),.iRGB(iRGB),
	.oRGB(COLOR),.HSYN(HSYNC),.VSYN(VSYNC)
);


// Audio output
assign SND_L = (SQW0 & TRIG0) ? 16'h6000 : 0;
assign SND_R = (SQW1 & TRIG1) ? 16'h6000 : 0;

endmodule


module HVGEN
(
	output  [8:0]		HPOS,
	output  [8:0]		VPOS,
	input 				PCLK,
	input	 [17:0]		iRGB,

	output reg [17:0]	oRGB,
	output reg			HBLK = 1,
	output reg			VBLK = 1,
	output reg			HSYN = 1,
	output reg			VSYN = 1
);

reg [8:0] hcnt = 0;
reg [8:0] vcnt = 0;

assign HPOS = hcnt;
assign VPOS = vcnt;

// 288x224
always @(posedge PCLK) begin
	case (hcnt)
		287: begin HBLK <= 1; HSYN <= 0; hcnt <= hcnt+1; end
		311: begin HSYN <= 1; hcnt <= hcnt+1; end
		383: begin
			HBLK <= 0; HSYN <= 1; hcnt <= 0;
			case (vcnt)
				223: begin VBLK <= 1; vcnt <= vcnt+1; end
				226: begin VSYN <= 0; vcnt <= vcnt+1; end
				233: begin VSYN <= 1; vcnt <= vcnt+1; end
				262: begin VBLK <= 0; vcnt <= 0; end
				default: vcnt <= vcnt+1;
			endcase
		end
		default: hcnt <= hcnt+1;
	endcase
	oRGB <= (HBLK|VBLK) ? 18'h0 : iRGB;
end

endmodule

