
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


`timescale 1ns / 1ps

module cv_bus_mux_sv (
    input logic bios_rom_ce_n_i,
    input logic ram_ce_n_i,
    input logic vdp_r_n_i,
    input logic ctrl_r_n_i,
    input logic cart_en_80_n_i,
    input logic cart_en_a0_n_i,
    input logic cart_en_c0_n_i,
    input logic cart_en_e0_n_i,
    input logic cart_en_sg1000_n_i,
    input logic ay_data_rd_n_i,
    input logic [7:0] bios_rom_d_i,
    input logic [7:0] cpu_ram_d_i,
    input logic [7:0] vdp_d_i,
    input logic [7:0] ctrl_d_i,
    input logic [7:0] cart_d_i,
    input logic [7:0] ay_d_i,
    output logic [7:0] d_o
);

    // Constants and variables
    localparam [7:0] d_inact_c = 8'hFF;
    logic [7:0] d_bios_v, d_ram_v, d_vdp_v, d_ctrl_v, d_cart_v, d_ay_v;

    // Default assignments
    always_comb begin
        d_bios_v = d_inact_c;
        d_ram_v  = d_inact_c;
        d_vdp_v  = d_inact_c;
        d_ctrl_v = d_inact_c;
        d_cart_v = d_inact_c;
        d_ay_v   = d_inact_c;

        if (bios_rom_ce_n_i == 1'b0) d_bios_v = bios_rom_d_i;
        if (ram_ce_n_i == 1'b0)      d_ram_v  = cpu_ram_d_i;
        if (vdp_r_n_i == 1'b0)       d_vdp_v  = vdp_d_i;
        if (ctrl_r_n_i == 1'b0)      d_ctrl_v = ctrl_d_i;
        // Modified cart_en logic to match VHDL behavior
        if ((cart_en_80_n_i & cart_en_a0_n_i & cart_en_c0_n_i & cart_en_e0_n_i & cart_en_sg1000_n_i) == 1'b0)
            d_cart_v = cart_d_i;
        if (ay_data_rd_n_i == 1'b0)  d_ay_v = ay_d_i;

        d_o = d_bios_v & d_ram_v & d_vdp_v & d_ctrl_v & d_cart_v & d_ay_v;
    end

endmodule
