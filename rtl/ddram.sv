//
// ddram.v
// Copyright (c) 2017,2019 Sorgelig
// Copyright (c) 2023 Waldo Alvarez https://pipflow.com (port from Genesis to ColecoVision)
//
// This source file is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version. 
//
// This source file is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the 
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
// ------------------------------------------

// I am making an FPGA Low Latency Trading Development Group, you can join our Discord here:
// https://discord.com/invite/JKpshJr

// 16-bit version

// Notes: If the state machine of this module is fused to the SDRAM 
// state machine and use_sdr is tested at start, likely multiplexers 
// could be removed to reduce the use of logic cells and wires. Also 
// timing can be improved.

module ddram
(
   //input         reset,                // Added reset input
	input         DDRAM_CLK,

	input         DDRAM_BUSY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	input  [63:0] DDRAM_DOUT,
	input         DDRAM_DOUT_READY,
	output        DDRAM_RD,
	output [63:0] DDRAM_DIN,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,

	input  [27:1] wraddr,
	input         write_rom_req,
	output reg    write_rom_ack,
	
	input  [15:0] din,
	
	input  [27:1] rdaddr,
	
	input  [15:0] rom_din,
	input   [1:0] rom_be,
	input         rom_we,
	input         rom_req,
	
	output reg    rom_ack,
	
	output reg    cpuwait,
	output [15:0] dout

	
);

// Initialize the registers
initial begin
    write_rom_ack = 0;
    rom_ack = 0;
    ram_read = 0;
    ram_write = 0;
    ram_be = 0;
    state = 0;
    ch = 0;
	 cpuwait = 1;
end

assign DDRAM_BURSTCNT = ram_burst;
assign DDRAM_BE       = ram_be | {8{ram_read}};
assign DDRAM_ADDR     = {4'b0011, ram_address}; // RAM at 0x30000000
assign DDRAM_RD       = ram_read;
assign DDRAM_DIN      = ram_data;
assign DDRAM_WE       = ram_write;



/*

 bit manipulation statement that extracts a 16-bit portion from a larger bit vector, ram_q, and assigns it to dout.

 Let's break it down for better understanding:

ram_q: This is a bit vector (64 bits) from which you want to extract data.

rdaddr[2:1]: This is a part of the rdaddr signal. In this case, you're taking bits 2 and 1 of rdaddr.

This portion of the address is being used to determine the starting point of the 16-bit segment you 
want to extract from ram_q.

{rdaddr[2:1], 4'b0000}: The {} notation is used for concatenation in Verilog. Here, you are concatenating the 
two bits from rdaddr[2:1] with four zero bits (4'b0000). This effectively multiplies the value in rdaddr[2:1] 
by 16. The result is a bit vector that represents the starting bit position in ram_q from where you want to 
begin extracting data.

+:16: This is Verilog's part-select operator. It means "starting from the bit position calculated
 by {rdaddr[2:1], 4'b0000}, select 16 bits".

assign dout = ...;: This line assigns the extracted 16-bit value to the output dout.

Putting it all together:

If rdaddr[2:1] is 00, {rdaddr[2:1], 4'b0000} results in 00000 in binary, which is 0 in decimal. Thus, 
bits [0:15] (the first 16 bits) of ram_q are assigned to dout.

If rdaddr[2:1] is 01, {rdaddr[2:1], 4'b0000} results in 010000 in binary, which is 16 in decimal. 
Thus, bits [16:31] of ram_q are assigned to dout.

This pattern continues, with rdaddr[2:1] determining which 16-bit chunk 
of ram_q is assigned to dout.

This kind of operation is used in memory interfaces where you want 
to extract a specific part of a data word based on a part of the address signal.

*/

assign dout  =  ram_q[{rdaddr[2:1],  4'b0000} +:16];


reg  [7:0] ram_burst;
reg [63:0] ram_q, next_q;
reg [63:0] ram_data;
reg [27:3] ram_address, cache_addr;
reg        ram_read = 0;
reg        ram_write = 0;
reg  [7:0] ram_be = 0;
reg        ch = 0;
reg [2:0]  state  = 0;



/*
always @(posedge DDRAM_CLK or negedge reset) begin

   if (!reset) begin
        // Reset conditions: Set all the registers to their initial states
        we_ack <= 0;
        rom_ack <= 0;
        ram_read <= 0;
        ram_write <= 0;
        ram_be <= 0;
        state <= 0;
        ch <= 0;
   end else*/
	
always @(posedge DDRAM_CLK) begin
	if(!DDRAM_BUSY) begin
		ram_write <= 0;
		ram_read  <= 0;

		case(state)
		   // State 0: Idle or Request Processing State
         // Checks for write, ROM, and read requests and initiates appropriate actions.
			
			0: 
			   
			   if(write_rom_ack != write_rom_req) begin
			   // Write operation is requested
					ram_be      <= 8'd3<<{wraddr[2:1],1'b0};
					ram_data		<= {4{din}};
					ram_address <= wraddr[27:3];
					ram_write 	<= 1;
					ram_burst   <= 1;
					ch          <= 1;
					state       <= 1;
				end
				else if(rom_req != /*rom_ack*/ 0) begin
				
				
				
				// ROM read operation is requested
					if(rom_we) begin
						ram_be      <= {6'd0,rom_be}<<{rdaddr[2:1],1'b0};
						ram_data		<= {4{rom_din}};
						ram_address <= rdaddr[27:3];
						ram_write 	<= 1;
						ram_burst   <= 1;
						ch          <= 0;
						state       <= 1;
					end
					else if(cache_addr == rdaddr[27:3]) rom_ack <= rom_req;
					else if((cache_addr+1'd1) == rdaddr[27:3]) begin
						rom_ack     <= rom_req;
						ram_q       <= next_q;
						cache_addr  <= rdaddr[27:3];
						ram_address <= rdaddr[27:3]+1'd1;
						ram_read    <= 1;
						ram_burst   <= 1;
						ch          <= 0;
						state       <= 3;
						// cpuwait <= 0; // Assert cpuwait (start of read) Not needed, data is already available
					end
					else begin
						ram_address <= rdaddr[27:3];
						cache_addr  <= rdaddr[27:3];
						ram_read    <= 1;
						ram_burst   <= 2;
						ch          <= 0;
						state       <= 2;
						cpuwait <= 0; // Assert cpuwait (start of read)
					end 
				end
				

			1: begin
			// State 1: Write Operation Completion State
         // Completes a write operation and acknowledges the request.
         // Resets the cache addresses and updates the request acknowledgments.
					cache_addr  <= '1;
					cache_addr[3]  <= 0;
					
					if(ch) write_rom_ack <= write_rom_req;
               else rom_ack <= rom_req;
					
					state <= 0;
				end

			2: if(DDRAM_DOUT_READY) begin
			// State 2: Read Operation Setup State
         // Sets up a read operation.
         // Checks if DDRAM data output is ready and then moves to State 3 for further processing.
					
					ram_q  <= DDRAM_DOUT;
               rom_ack <= rom_req;
               state <= 3;
					cpuwait <= 1;
					
				end

			3: if(DDRAM_DOUT_READY) begin
			// State 3: Read Operation Completion State
         // Completes a read operation.
         // Stores the DDRAM data output and transitions to the Idle State (State 0) for new requests.
					
					next_q <= DDRAM_DOUT;
					state <= 4;
					cpuwait <= 1; 
					
				end
				
		    4: begin
                // State 4: Wait until rom_req becomes 0
                if(rom_req == 0) begin
                    state <= 0; // Transition back to idle state once rom_req is 0
                end
                // No other actions needed in this state, just waiting
            end
				
		endcase
	end
end

endmodule
