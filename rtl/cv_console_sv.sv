
//-----------------------------------------------------------------------------
//
// FPGA Colecovision
//
// $Id: cv_addr_dec.vhd,v 1.3 2006/01/05 22:22:29 arnim Exp $
//
// Address Decoder
//
//-----------------------------------------------------------------------------

// Copyright (c) 2006, Arnim Laeuger (arnim.laeuger@gmx.net)
// Copyright (c) 2023, Waldo Alvarez (https://pipflow.com) port to System Verilog

// All rights reserved

// Redistribution and use in source and synthezised forms, with or without
// modification, are permitted provided that the following conditions are met:

// Redistributions of source code must retain the above copyright notice,
// this list of conditions and the following disclaimer.

// Redistributions in synthesized form must reproduce the above copyright
// notice, this list of conditions and the following disclaimer in the
// documentation and/or other materials provided with the distribution.

// Neither the name of the author nor the names of other contributors may
// be used to endorse or promote products derived from this software without
// specific prior written permission.

// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
// THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
// PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

// Please report bugs to the author, but before you do so, please
// make sure that this is not a derivative work and that
// you have the latest version of this file.
//
//-----------------------------------------------------------------------------

// I am making an FPGA Low Latency Trading Development Group, you can join our Discord here:

// https://discord.com/invite/JKpshJr


`timescale 1ns / 1ps


module cv_console_sv #(
    parameter integer is_pal_g = 0,
    parameter integer compat_rgb_g = 0
) (
    // Global Interface
    input logic clk_i,
    input logic wait_cart,
    input logic clk_en_10m7_i,
    input logic reset_n_i,
    input logic sg1000,
    input logic dahjeeA_i,  // SG-1000 RAM extension at 0x2000-0x3fff
    output logic por_n_o,

    // Controller Interface
    input logic [1:0] ctrl_p1_i,
    input logic [1:0] ctrl_p2_i,
    input logic [1:0] ctrl_p3_i,
    input logic [1:0] ctrl_p4_i,
    output logic [1:0] ctrl_p5_o,
    input logic [1:0] ctrl_p6_i,
    input logic [1:0] ctrl_p7_i,
    output logic [1:0] ctrl_p8_o,
    input logic [1:0] ctrl_p9_i,
    input logic [7:0] joy0_i,
    input logic [7:0] joy1_i,

    // BIOS ROM Interface
    output logic [12:0] bios_rom_a_o,
    output logic bios_rom_ce_n_o,
    input logic [7:0] bios_rom_d_i,

    // CPU RAM Interface
    output logic [14:0] cpu_ram_a_o,
    output logic cpu_ram_ce_n_o,
    output logic cpu_ram_rd_n_o,
    output logic cpu_ram_we_n_o,
    input logic [7:0] cpu_ram_d_i,
    output logic [7:0] cpu_ram_d_o,

    // Video RAM Interface
    output logic [13:0] vram_a_o,
    output logic vram_we_o,
    output logic [7:0] vram_d_o,
    input logic [7:0] vram_d_i,

    // Cartridge ROM Interface
    output logic [19:0] cart_a_o,
    input logic [5:0] cart_pages_i,
    output logic cart_en_80_n_o,
    output logic cart_en_a0_n_o,
    output logic cart_en_c0_n_o,
    output logic cart_en_e0_n_o,
    output logic cart_rd,
    input logic [7:0] cart_d_i,
    output logic cart_en_sg1000_n_o,

    // RGB Video Interface
    input logic border_i,
    output logic [3:0] col_o,
    output logic [7:0] rgb_r_o,
    output logic [7:0] rgb_g_o,
    output logic [7:0] rgb_b_o,
    output logic hsync_n_o,
    output logic vsync_n_o,
    output logic blank_n_o,
    output logic hblank_o,
    output logic vblank_o,
    output logic comp_sync_n_o,

    // Audio Interface
    output logic [13:0] audio_o
);

// Internal signal declarations (translated from VHDL)

    logic por_n_s;
    logic reset_n_s;

    logic clk_en_3m58_p_s;
    logic clk_en_3m58_n_s;

    // CPU signals
    logic wait_n_s;
    logic nmi_n_s;
    logic int_n_s;
    logic iorq_n_s;
    logic m1_n_s;
    logic m1_wait_q;
    logic rd_n_s, wr_n_s;
    logic mreq_n_s;
    logic rfsh_n_s;
    logic [15:0] a_s;
    logic [7:0] d_to_cpu_s, d_from_cpu_s;

    // VDP18 signal
    logic [7:0] d_from_vdp_s;
    logic vdp_int_n_s;

    // SN76489 signal
    logic psg_ready_s;
    logic [13:0] psg_b_audio_s;

    // AY-8910 signal
    logic [7:0] ay_d_s;
    logic [11:0] ay_ch_a_s;
    logic [11:0] ay_ch_b_s;
    logic [11:0] ay_ch_c_s;
    logic [13:0] psg_a_audio_s;

    // Controller signals
    logic [7:0] d_from_ctrl_s;
    logic [7:0] d_to_ctrl_s;
    logic ctrl_int_n_s;

    // Address decoder signals
    logic bios_rom_ce_n_s;
    logic ram_ce_n_s;
    logic vdp_r_n_s, vdp_w_n_s;
    logic psg_we_n_s;
    logic ay_addr_we_n_s;
    logic ay_data_we_n_s;
    logic ay_data_rd_n_s;
    logic ctrl_r_n_s;
    logic ctrl_en_key_n_s, ctrl_en_joy_n_s;
    logic cart_en_80_n_s, cart_en_a0_n_s, cart_en_c0_n_s, cart_en_e0_n_s;
    logic [5:0] cart_page_s;

    logic cart_en_sg1000_n_s;
    logic vdd_s;





// Assignments
assign vdd_s = 1'b1;
assign audio_o = psg_a_audio_s + psg_b_audio_s;

// Conditional assignments
assign int_n_s = (sg1000 == 1'b0) ? ctrl_int_n_s : vdp_int_n_s;
assign nmi_n_s = (sg1000 == 1'b0) ? vdp_int_n_s : (joy0_i[7] & joy1_i[7]);

// Reset generation
cv_por por_b (
    .clk_i(clk_i),
    .por_n_o(por_n_s)
);

assign por_n_o = por_n_s;
assign reset_n_s = por_n_s & reset_n_i;


// Clock generation
cv_clock_sv clock_b (
    .clk_i(clk_i),
    .clk_en_10m7_i(clk_en_10m7_i),
    .reset_n_i(reset_n_s),
    .clk_en_3m58_p_o(clk_en_3m58_p_s),
    .clk_en_3m58_n_o(clk_en_3m58_n_s)
);

// T80 CPU
T80pa #(
    .Mode(0)
) t80a_b (
    // The Mode parameter is set during instantiation in SystemVerilog
    .RESET_n(reset_n_s),
    .CLK(clk_i),
    .CEN_p(clk_en_3m58_p_s),
    .CEN_n(clk_en_3m58_n_s),
    .WAIT_n(wait_n_s),
    .INT_n(int_n_s),
    .NMI_n(nmi_n_s),
    .BUSRQ_n(vdd_s),
    .M1_n(m1_n_s),
    .MREQ_n(mreq_n_s),
    .IORQ_n(iorq_n_s),
    .RD_n(rd_n_s),
    .WR_n(wr_n_s),
    .RFSH_n(rfsh_n_s),
    .HALT_n(1'bZ),  // 'open' in VHDL is often translated to high impedance 'Z' in SystemVerilog
    .BUSAK_n(1'bZ),
    .A(a_s),
    .DI(d_to_cpu_s),
    .DO(d_from_cpu_s)
);

// Setting the Mode parameter for T80 CPU
//defparam t80a_b.Mode = 0;




// Signal Assignments


assign wait_n_s = wait_cart & (psg_ready_s & ~m1_wait_q);



always_ff @(posedge clk_i or negedge reset_n_s) begin
    if (!reset_n_s) begin
        m1_wait_q <= 1'b0;
    end else if (clk_en_3m58_p_s) begin
        m1_wait_q <= ~m1_wait_q;
    end
end



// TMS9928A Video Display Processor

// If this module is modified to render more sprites than what the original hardware allows, without 
// modifying the status register, it could potentially eliminate sprite flickering in certain games.

// Some games resort to flickering sprites as a workaround. The original hardware restricts the number 
// of sprites that can be drawn to no more than four on the same horizontal line.

vdp18_core #(
    .is_pal_g(is_pal_g),
    .compat_rgb_g(compat_rgb_g)
) vdp18_b (
    .clk_i(clk_i),
    .clk_en_10m7_i(clk_en_10m7_i),
    .reset_n_i(reset_n_s),
    .csr_n_i(vdp_r_n_s),
    .csw_n_i(vdp_w_n_s),
    .mode_i(a_s[0]),
    .int_n_o(vdp_int_n_s),
    .cd_i(d_from_cpu_s),
    .cd_o(d_from_vdp_s),
    .vram_we_o(vram_we_o),
    .vram_a_o(vram_a_o),
    .vram_d_o(vram_d_o),
    .vram_d_i(vram_d_i),
    .col_o(col_o),
    .rgb_r_o(rgb_r_o),
    .rgb_g_o(rgb_g_o),
    .rgb_b_o(rgb_b_o),
    .hsync_n_o(hsync_n_o),
    .vsync_n_o(vsync_n_o),
    .blank_n_o(blank_n_o),
    .border_i(border_i),
    .hblank_o(hblank_o),
    .vblank_o(vblank_o),
    .comp_sync_n_o(comp_sync_n_o)
);

// YM2149 Audio Processor

ym2149_audio psg_a (
    .clk_i(clk_i),
    .en_clk_psg_i(clk_en_3m58_p_s),
    .reset_n_i(reset_n_s),
    .bdir_i(~ay_addr_we_n_s | ~ay_data_we_n_s),
    .bc_i(~ay_addr_we_n_s | ~ay_data_rd_n_s),
    .data_i(d_from_cpu_s),
    .data_r_o(ay_d_s),
    .ch_a_o(ay_ch_a_s),
    .ch_b_o(ay_ch_b_s),
    .ch_c_o(ay_ch_c_s),
    .mix_audio_o(psg_a_audio_s),
    .sel_n_i(1'b0)
);




// SN76489 Programmable Sound Generator

sn76489_audio #(
    .FAST_IO_G(1'b0),        // Note: Assuming '0' is boolean, represented as 1'b0 in SystemVerilog
    .MIN_PERIOD_CNT_G(17)
) psg_b (
    .clk_i(clk_i),
    .en_clk_psg_i(clk_en_3m58_p_s),
    .ce_n_i(psg_we_n_s),
    .wr_n_i(psg_we_n_s),
    .ready_o(psg_ready_s),
    .data_i(d_from_cpu_s),
    .mix_audio_o(psg_b_audio_s)
);


// Setting the parameters for psg_b

defparam psg_b.FAST_IO_G = 1'b0;
defparam psg_b.MIN_PERIOD_CNT_G = 17;

// Controller Ports
cv_ctrl ctrl_b (
    .clk_i(clk_i),
    .clk_en_3m58_i(clk_en_3m58_p_s),
    .reset_n_i(reset_n_s),
    .ctrl_en_key_n_i(ctrl_en_key_n_s),
    .ctrl_en_joy_n_i(ctrl_en_joy_n_s),
    .a1_i(a_s[1]),
    .ctrl_p1_i(ctrl_p1_i),
    .ctrl_p2_i(ctrl_p2_i),
    .ctrl_p3_i(ctrl_p3_i),
    .ctrl_p4_i(ctrl_p4_i),
    .ctrl_p5_o(ctrl_p5_o),
    .ctrl_p6_i(ctrl_p6_i),
    .ctrl_p7_i(ctrl_p7_i),
    .ctrl_p8_o(ctrl_p8_o),
    .ctrl_p9_i(ctrl_p9_i),
    .d_o(d_from_ctrl_s),
    .int_n_o(ctrl_int_n_s)
);


// Address Decoder

cv_addr_dec_sv addr_dec_b (
    .clk_i(clk_i),
    .reset_n_i(reset_n_i),
    .sg1000(sg1000),
    .dahjeeA_i(dahjeeA_i),
    .a_i(a_s),
    .d_i(d_from_cpu_s),
    .cart_pages_i(cart_pages_i),
    .cart_page_o(cart_page_s),
    .iorq_n_i(iorq_n_s),
    .rd_n_i(rd_n_s),
    .wr_n_i(wr_n_s),
    .mreq_n_i(mreq_n_s),
    .rfsh_n_i(rfsh_n_s),
    .bios_rom_ce_n_o(bios_rom_ce_n_s),
    .ram_ce_n_o(ram_ce_n_s),
    .vdp_r_n_o(vdp_r_n_s),
    .vdp_w_n_o(vdp_w_n_s),
    .psg_we_n_o(psg_we_n_s),
    .ay_addr_we_n_o(ay_addr_we_n_s),
    .ay_data_we_n_o(ay_data_we_n_s),
    .ay_data_rd_n_o(ay_data_rd_n_s),
    .ctrl_r_n_o(ctrl_r_n_s),
    .ctrl_en_key_n_o(ctrl_en_key_n_s),
    .ctrl_en_joy_n_o(ctrl_en_joy_n_s),
    .cart_en_80_n_o(cart_en_80_n_s),
    .cart_en_a0_n_o(cart_en_a0_n_s),
    .cart_en_c0_n_o(cart_en_c0_n_s),
    .cart_en_e0_n_o(cart_en_e0_n_s),
    .cart_en_sg1000_n_o(cart_en_sg1000_n_s)
);


// Other Assignments
assign bios_rom_ce_n_o = bios_rom_ce_n_s;
assign cpu_ram_ce_n_o = ram_ce_n_s;
assign cpu_ram_we_n_o = wr_n_s;
assign cpu_ram_rd_n_o = rd_n_s;
assign cart_en_80_n_o = cart_en_80_n_s;
assign cart_en_a0_n_o = cart_en_a0_n_s;
assign cart_en_c0_n_o = cart_en_c0_n_s;
assign cart_en_e0_n_o = cart_en_e0_n_s;
assign cart_en_sg1000_n_o = cart_en_sg1000_n_s;
assign cart_rd = ~(cart_en_80_n_s & cart_en_a0_n_s & cart_en_c0_n_s & cart_en_e0_n_s & cart_en_sg1000_n_s);

// Bus multiplexer logic
always_comb begin
    if (sg1000 == 1'b0) begin
        d_to_ctrl_s = d_from_ctrl_s;
    end else if (a_s[0] == 1'b0) begin
        d_to_ctrl_s = {joy1_i[2], joy1_i[3], joy0_i[5], joy0_i[4], joy0_i[0], joy0_i[1], joy0_i[2], joy0_i[3]};
    end else begin
        d_to_ctrl_s = {3'b111, reset_n_i, joy1_i[5], joy1_i[4], joy1_i[0], joy1_i[1]};
    end
end

// Bus multiplexer

cv_bus_mux_sv bus_mux_b (
    .bios_rom_ce_n_i(bios_rom_ce_n_s),
    .ram_ce_n_i(ram_ce_n_s),
    .vdp_r_n_i(vdp_r_n_s),
    .ctrl_r_n_i(ctrl_r_n_s),
    .cart_en_80_n_i(cart_en_80_n_s),
    .cart_en_a0_n_i(cart_en_a0_n_s),
    .cart_en_c0_n_i(cart_en_c0_n_s),
    .cart_en_e0_n_i(cart_en_e0_n_s),
    .cart_en_sg1000_n_i(cart_en_sg1000_n_s),
    .ay_data_rd_n_i(ay_data_rd_n_s),
    .bios_rom_d_i(bios_rom_d_i),
    .cpu_ram_d_i(cpu_ram_d_i),
    .vdp_d_i(d_from_vdp_s),
    .ctrl_d_i(d_to_ctrl_s),
    .cart_d_i(cart_d_i),
    .ay_d_i(ay_d_s),
    .d_o(d_to_cpu_s)
);



// Misc outputs

assign bios_rom_a_o = a_s[12:0];
assign cpu_ram_a_o = a_s[14:0];
assign cpu_ram_d_o = d_from_cpu_s;
assign cart_a_o = (sg1000 == 1'b0) ? {cart_page_s, a_s[13:0]} : {4'b0000, a_s[15:0]};



endmodule
