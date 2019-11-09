// Copyright (c) 2006,19 MiSTer-X

module PS2KEY_HID
(
	input				clk50m,
	input				reset,

	input				ps2_clk,
	input				ps2_dat,

	output [15:0]	hidout_n,
	output  [3:0]	hidfunc
);

reg clk, ps2c, ps2d;
always @(posedge clk50m) begin
	clk  <= ~clk;
	ps2c <= ps2_clk;
	ps2d <= ps2_dat;
end

wire  [8:0] rx_data;
wire [15:0] hidout;

ps2krx recv(.reset(reset),.ps2c(ps2c),.ps2d(ps2d),.rxvcode(rx_data));
ps2kcv conv(.clk(clk),.reset(reset),.keyrecv(rx_data[8]),.keycode(rx_data[7:0]),.hid1(hidout),.hid2(hidfunc));

assign hidout_n = ~hidout;

endmodule


module ps2kcv
(
	input				clk,
	input				reset,
	input				keyrecv,
	input [7:0] 	keycode,

	output [15:0] 	hid1,
	output [3:0]	hid2
);

reg	bRS, bCR, bS2, bS1;
reg	bT7, bT6, bT5, bT4;
reg	bT3, bT2, bT1, bT0;
reg	bRG, bLF, bDW, bUP;

assign hid1 = { bRS, bCR, bS2, bS1, bT7, bT6, bT5, bT4, bT3, bT2, bT1, bT0, bRG, bLF, bDW, bUP };
assign hid2 = {4{bRS}} & { bT5, bT6, bT7, ~(bT5|bT6|bT7) };

reg	pkeyrecv;

reg	bRel;
wire 	bHit = ~bRel;

always @(posedge clk or posedge reset) begin
	if (reset) begin
		pkeyrecv <= 0;

		bRS	<= 0;
		bCR	<= 0;
		bS2	<= 0;
		bS1	<= 0;
		bT7	<= 0;
		bT6	<= 0;
		bT5	<= 0;
		bT4	<= 0;
		bT3	<= 0;
		bT2	<= 0;
		bT1	<= 0;
		bT0	<= 0;
		bRG	<= 0;
		bLF	<= 0;
		bDW	<= 0;
		bUP	<= 0;

		bRel	<= 0;
	end
	else begin
		// check receive scan code
		if ((keyrecv ^ pkeyrecv) & keyrecv) begin
			case (keycode)

				8'h75: bUP <= bHit;	// [up]
				8'h72: bDW <= bHit;	// [down]
				8'h6B: bLF <= bHit;	// [left]
				8'h74: bRG <= bHit;	// [right]

				8'h2B: bT7 <= bHit;	// F
				8'h23: bT6 <= bHit;	// D
				8'h1B: bT5 <= bHit;	// S
				8'h1C: bT4 <= bHit;	// A

				8'h2A: bT3 <= bHit;	// V
				8'h21: bT2 <= bHit;	// C
				8'h22: bT1 <= bHit;	// X
				8'h1A: bT0 <= bHit;	// Z

				8'h16: bS1 <= bHit;	// 1 (start1P)
				8'h1E: bS2 <= bHit;	// 2 (start2P)
				8'h26: bCR <= bHit;	// 3 (coin)
				8'h25: bRS <= bHit;	// 4 (reserved)

				default:;
			endcase
			bRel <= (keycode==8'hF0);
		end
		pkeyrecv <= keyrecv;
	end
end

endmodule


module ps2krx
(
	input		reset,

	input		ps2c,
	input		ps2d,

	output reg [8:0] rxvcode = 0
);

reg [9:0] rx_shift = 10'h3FF;

always @( negedge ps2c or posedge reset ) begin
	if( reset ) begin
		rx_shift <= 10'h3ff;
		rxvcode  <= 0;
	end
	else begin
		rx_shift <= { ps2d, rx_shift[9:1] };
		if ( ~rx_shift[0] ) begin
			rxvcode <= { 1'b1, rx_shift[8:1] };
			rx_shift <= 10'h3ff;
		end
		else rxvcode <= 0;
	end
end

endmodule

