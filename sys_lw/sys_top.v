
//  MiSTer hardware abstraction module (Arcade LightWeight version)
//  (c)2019 MiSTer-X

//== Based on: 
//============================================================================
//
//  MiSTer hardware abstraction module (Arcade version)
//  (c)2017-2019 Sorgelig
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

module sys_top
(
	/////////// CLOCK //////////
	input         FPGA_CLK1_50,
	input         FPGA_CLK2_50,
	input         FPGA_CLK3_50,

	//////////// VGA ///////////
	output  [5:0] VGA_R,
	output  [5:0] VGA_G,
	output  [5:0] VGA_B,
	inout         VGA_HS,  // VGA_HS is secondary SD card detect when VGA_EN = 1 (inactive)
	output		  VGA_VS,
	input         VGA_EN,  // active low

	/////////// AUDIO //////////
	output		  AUDIO_L,
	output		  AUDIO_R,
	output		  AUDIO_SPDIF,

	//////////// HDMI //////////
	output        HDMI_I2C_SCL,
	inout         HDMI_I2C_SDA,

	output        HDMI_MCLK,
	output        HDMI_SCLK,
	output        HDMI_LRCLK,
	output        HDMI_I2S,

	output        HDMI_TX_CLK,
	output        HDMI_TX_DE,
	output [23:0] HDMI_TX_D,
	output        HDMI_TX_HS,
	output        HDMI_TX_VS,
	
	input         HDMI_TX_INT,

	//////////// SDR ///////////
	output [12:0] SDRAM_A,
	inout  [15:0] SDRAM_DQ,
	output        SDRAM_DQML,
	output        SDRAM_DQMH,
	output        SDRAM_nWE,
	output        SDRAM_nCAS,
	output        SDRAM_nRAS,
	output        SDRAM_nCS,
	output  [1:0] SDRAM_BA,
	output        SDRAM_CLK,
	output        SDRAM_CKE,

	//////////// I/O ///////////
	output        LED_USER,
	output        LED_HDD,
	output        LED_POWER,
	input         BTN_USER,
	input         BTN_OSD,
	input         BTN_RESET,

	//////////// SDIO ///////////
	inout   [3:0] SDIO_DAT,
	inout         SDIO_CMD,
	output        SDIO_CLK,
	input         SDIO_CD,

	////////// MB KEY ///////////
	input   [1:0] KEY,

	////////// MB SWITCH ////////
	input   [3:0] SW,

	////////// MB LED ///////////
	output  [7:0] LED,

	///////// USER IO ///////////
	inout   [5:0] USER_IO
);

wire RESET = ~BTN_RESET;
wire PON_RESET = RESET;


wire [15:0] HID;
PS2KEY_HID hid(FPGA_CLK1_50,PON_RESET,USER_IO[0],USER_IO[1],HID);
assign USER_IO[5:2]={4{1'bz}};


wire  [5:0] PIX_R,PIX_G,PIX_B;
wire			HSYNC,VSYNC;

assign VGA_VS = VGA_EN ? 1'bZ      : VSYNC;
assign VGA_HS = VGA_EN ? 1'bZ      : HSYNC;
assign VGA_R  = VGA_EN ? 6'bZZZZZZ : PIX_R;
assign VGA_G  = VGA_EN ? 6'bZZZZZZ : PIX_G;
assign VGA_B  = VGA_EN ? 6'bZZZZZZ : PIX_B;


wire [15:0] SND_L,SND_R;
AUDIO_OUT aout(FPGA_CLK1_50,PON_RESET,SND_L,SND_R,AUDIO_L,AUDIO_R,AUDIO_SPDIF);


assign {LED_USER,LED_HDD,LED_POWER}={BTN_USER,BTN_OSD,BTN_RESET};

assign HDMI_I2C_SDA = 1'bz;
assign {HDMI_I2C_SCL,HDMI_MCLK,HDMI_SCLK,HDMI_LRCLK,HDMI_I2S,HDMI_TX_CLK,HDMI_TX_DE,HDMI_TX_D,HDMI_TX_HS,HDMI_TX_VS}={33{1'b0}};
	
assign LED = 0;
assign {SDIO_CLK, SDIO_CMD, SDIO_DAT[3:0]} = {6{1'bZ}};
assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = {39{1'bZ}};


EMU_LW emu(FPGA_CLK2_50,RESET,HID,{PIX_B,PIX_G,PIX_R},HSYNC,VSYNC,SND_L,SND_R);

endmodule


module AUDIO_OUT
(
	input				CLK50M,
	input				RESET,

	input [15:0]	iL,
	input [15:0]	iR,
	
	output			oL,
	output			oR,
	output			oD
);

sigma_delta_dac #(15) dacL(oL,{~iL[15],iL[14:0]},CLK50M,RESET);
sigma_delta_dac #(15) dacR(oR,{~iR[15],iR[14:0]},CLK50M,RESET);

spdif dif(CLK50M,RESET,1'b0,oD,iR,iL);

endmodule


