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

// I am making an FPGA Low Latency Trading Development Group, you can 
// join our Discord here: https://discord.com/invite/JKpshJr

module cv_addr_dec_sv (
    input logic clk_i,
    input logic reset_n_i,
    input logic sg1000,
    input logic dahjeeA_i,
    input logic [15:0] a_i,
    input logic [7:0] d_i,
    input logic [5:0] cart_pages_i,
    output logic [5:0] cart_page_o,
    input logic iorq_n_i,
    input logic rd_n_i,
    input logic wr_n_i,
    input logic mreq_n_i,
    input logic rfsh_n_i,
    output logic bios_rom_ce_n_o,
    output logic ram_ce_n_o,
    output logic vdp_r_n_o,
    output logic vdp_w_n_o,
    output logic psg_we_n_o,
    output logic ay_addr_we_n_o,
    output logic ay_data_we_n_o,
    output logic ay_data_rd_n_o,
    output logic ctrl_r_n_o,
    output logic ctrl_en_key_n_o,
    output logic ctrl_en_joy_n_o,
    output logic cart_en_80_n_o,
    output logic cart_en_a0_n_o,
    output logic cart_en_c0_n_o,
    output logic cart_en_e0_n_o,
    output logic cart_en_sg1000_n_o
);

    logic megacart_en;
    logic [5:0] megacart_page;
    logic bios_en;


  // Purpose:
  //   Implements the address decoding logic.
  
  
  
    always_comb begin
	 
	 logic [2:0] mux_v;
	 
        // Default assignments
        bios_rom_ce_n_o = 1'b1;
        ram_ce_n_o = 1'b1;
        vdp_r_n_o = 1'b1;
        vdp_w_n_o = 1'b1;
        psg_we_n_o = 1'b1;
        ay_addr_we_n_o = 1'b1;
        ay_data_we_n_o = 1'b1;
        ay_data_rd_n_o = 1'b1;
        ctrl_r_n_o = 1'b1;
        ctrl_en_key_n_o = 1'b1;
        ctrl_en_joy_n_o = 1'b1;
        cart_en_80_n_o = 1'b1;
        cart_en_a0_n_o = 1'b1;
        cart_en_c0_n_o = 1'b1;
        cart_en_e0_n_o = 1'b1;
        cart_en_sg1000_n_o = 1'b1;

        // MegaCart Enable Logic
        megacart_en = sg1000 == 1'b0 && (
            cart_pages_i == 6'b000011 || // 64k
            cart_pages_i == 6'b000111 || // 128k
            cart_pages_i == 6'b001111 || // 256k
            cart_pages_i == 6'b011111 || // 512k
            cart_pages_i == 6'b111111    // 1M
        );

        // Paging Logic
        case (a_i[15:14])
            2'b10: cart_page_o = megacart_en ? cart_pages_i : 6'b000000;
            2'b11: cart_page_o = megacart_en ? megacart_page : 6'b000001;
            default: cart_page_o = 6'b000000;
        endcase

        // Memory Access Logic
        if (!mreq_n_i && rfsh_n_i) begin
            if (sg1000) begin
                if (a_i[15:14] == 2'b11) begin // c000 - ffff
                    ram_ce_n_o = 1'b0;
                end else if (a_i[15:13] == 3'b001 && dahjeeA_i) begin // 2000 - 3fff
                    ram_ce_n_o = 1'b0;
                end else begin
                    cart_en_sg1000_n_o = 1'b0;
                end
            end else begin
                case (a_i[15:13])
                    3'b000: if (bios_en) begin
                        bios_rom_ce_n_o = 1'b0;
                    end else begin
                        ram_ce_n_o = 1'b0;
                    end
                    3'b001, 3'b010, 3'b011: ram_ce_n_o = 1'b0; // 2000 - 7fff
                    3'b100: cart_en_80_n_o = 1'b0;
                    3'b101: cart_en_a0_n_o = 1'b0;
                    3'b110: cart_en_c0_n_o = 1'b0;
                    3'b111: cart_en_e0_n_o = 1'b0;
                endcase
            end
        end

        // IO Access Logic
        if (!iorq_n_i) begin
            if (!sg1000 && a_i[7]) begin
                mux_v = {a_i[6], a_i[5], wr_n_i};
                case (mux_v)
                    3'b000: ctrl_en_key_n_o = 1'b0;
                    3'b010: vdp_w_n_o = 1'b0;
                    3'b011: if (!rd_n_i) vdp_r_n_o = 1'b0;
                    3'b100: ctrl_en_joy_n_o = 1'b0;
                    3'b110: psg_we_n_o = 1'b0;
                    3'b111: if (!rd_n_i) ctrl_r_n_o = 1'b0;
                endcase
            end

            if (sg1000) begin
                mux_v = {a_i[7], a_i[6], wr_n_i};
                case (mux_v)
                    3'b010: psg_we_n_o = 1'b0;
                    3'b100: vdp_w_n_o = 1'b0;
                    3'b101: if (!rd_n_i) vdp_r_n_o = 1'b0;
                    3'b111: if (!rd_n_i) ctrl_r_n_o = 1'b0;
                endcase
            end

            if (a_i[7:0] == 8'h50 && !wr_n_i) ay_addr_we_n_o = 1'b0;
            else if (a_i[7:0] == 8'h51 && !wr_n_i) ay_data_we_n_o = 1'b0;
            else if (a_i[7:0] == 8'h52 && !rd_n_i) ay_data_rd_n_o = 1'b0;
        end
    end

    // megacart process
    always_ff @(posedge clk_i or negedge reset_n_i) begin
        if (!reset_n_i) begin
            megacart_page <= 6'b000000;
            bios_en <= 1'b1;
        end else begin
            // MegaCart paging logic
            if (megacart_en && rfsh_n_i && !mreq_n_i && !rd_n_i && a_i[15:6] == {8'hFF, 2'b11}) begin
                megacart_page <= a_i[5:0] & cart_pages_i;
            end

            // SGM BIOS enable/disable logic
            if (sg1000) begin
                bios_en <= 1'b0;
            end else if (!iorq_n_i && mreq_n_i && rfsh_n_i && !wr_n_i && a_i[7:0] == 8'h7F) begin
                bios_en <= d_i[1];
            end
        end
    end

endmodule
