/*
Copyright by Saaijith Vigneswaran, Maariz Almamun, and Nicola Nicolici (gang members)
Developed for the Digital Systems Design course (COE3DQ5)
Department of Electrical and Computer Engineering
McMaster University
Ontario, Canada Earth
*/

`timescale 1ns/100ps

`ifndef DISABLE_DEFAULT_NET
`default_nettype none
`endif

`include "define_state.h"

// It connects the m1 top-level statmachine
// It gives the instants needed to write to the Sram 
module  the_maariz_milestone (
		input logic Clock_50,
		input logic Resetn,
		input logic m3_enable,
		
		//SRAM Controller 
		input logic [17:0] SRAM_read_data,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,
		output logic [17:0] SRAM_address,
		output logic m3_disable
		); 

parameter bitstream_SRAM_location = 18'd76800,
          OFFSET_U = 18'd76800;
		  OFFSET_V = 18'd115200;
			

logic [5:0] bitstream_index; //Counter of which bit within shift register is being next read in
logic [17:0] address_incrementer; //SRAM address index
logic [13:0] counter_block; //counts which 8x8 block is being worked on (last one is = 2399)

logic [9:0] clock_cycles; //Checks # of clock cycles since program begins
logic [4:0] wait_cycle; //Increments when waiting for SRAM read data to appear

logic Q_val;
logic [1:0] load_register; //counter which counts until SRAM_read_data prepared
logic [47:0] the_shift_register; //To be utilized as a shift register made of 3 sub registers of 16 bit each

logic iz_y_write;
logic iz_u_write;
logic [17:0] ultimate_offset_write;

logic [5:0] counter_pixel_write; // Counter of what S value to store next, rolls over
logic [4:0] counter_row_write; //counter of what block # within a row
logic [5:0] counter_column_write; 



//state_type state;
M3_STATE_type M3_STATE;


logic [6:0]  DRAM_address_a; //Will become DRAM_address_a[2] once integrated in M2
logic [6:0]  DRAM_address_b; 
logic [31:0]  DRAM_write_data_a;  	
logic [31:0]  DRAM_write_data_b;		
logic DRAM_we_n_a; 
logic DRAM_we_n_b;		
logic [31:0]  DRAM_read_data_a;		
logic [31:0]  DRAM_read_data_b;

		
dual_port_RAM2 dual_port_RAM_inst2 (		
	.address_a ( DRAM_address_a[0] ),//input		
	.address_b ( DRAM_address_b[0] ),//input		
	.clock ( Clock_50 ),//input		
	.data_a ( DRAM_write_data_a[0] ),		
	.data_b ( DRAM_write_data_b[0] ),		
	.wren_a ( DRAM_we_n_a[0]),		
	.wren_b ( DRAM_we_n_b[0] ),		
	.q_a ( DRAM_read_data_a[0] ),//output		
	.q_b ( DRAM_read_data_b[0]) //output		
	);



//VARIABLES TO DECLARE
//M3_STATE

always_ff @ (posedge Clock_50 or negedge Resetn) begin
	if (Resetn == 1'b0) begin
		SRAM_write_data <= 16'd0;
		m3_disable <= 1'b0;
		SRAM_we_n <= 1'b1; //Initialize for reading
		SRAM_address <= 18'd0;
		
		clock_cycles <= 10'd0;
		wait_cycle <= 5'd0;
		
		counter_pixel_write <= 6'd0; // Counter of what segment of what 8x8 block, rolls over
		bitstream_index <= 6'd0; //Counter of which bit within shift register is being next read in
		address_incrementer <= 18'd2; //SRAM address index
		counter_block <= 14'd0;
		
		Q_val <= 1'b0;
		load_register <= 2'b0;
		the_shift_register <= 48'd0;
		
		iz_y_write <= 1'b1;
		iz_u_write <= 1'b0;
		M3_STATE <= STATE_3_IDLE;
	end
	else begin
		
		clock_cycles <= clock_cycles + 10'd1;
		
		case (M3_STATE) begin
			
			STATE_3_IDLE: begin
				SRAM_write_data <= 16'd0;
				m3_disable <= 1'b0;
				SRAM_we_n <= 1'b1;
				SRAM_address <= 18'd0;
				
				clock_cycles <= 10'd0;
				wait_cycle <= 5'd0;
				
				counter_pixel_write <= 6'd0; // Counter of what segment of what 8x8 block, rolls over
				bitstream_index <= 6'd0; //Counter of which bit within shift register is being next read in
				address_incrementer <= 18'd2; //SRAM address index
				counter_block <= 14'd0;			

				Q_val <= 1'b0;
				load_register <= 2'b0;
				the_shift_register <= 48'd0;			
			
				if(m3_enable) M3_STATE <= S_INIT_00;
				else M3_STATE <= STATE_3_IDLE;			
			end

			S_INIT_00: begin 
				SRAM_we_n <= 1'b1; //Initialize reading from SRAM location 2 (15th bit tells if Q0 or Q1)
				SRAM_address <= address_incrementer + bitstream_SRAM_location; 
				bitstream_SRAM_location <= bitstream_SRAM_location + 6'd2; //Increments from 2 to 4
				
				M3_STATE <= S_INIT_01;
			end
			S_INIT_01: begin
				
				SRAM_address <= address_incrementer + bitstream_SRAM_location; //Instantiate  fill of first register slot SRAM4
				bitstream_SRAM_location <= bitstream_SRAM_location + 6'd1; //Increments from 4 to 5
				
				M3_STATE <= S_INIT_02;
			end
			S_INIT_02: begin
				SRAM_address <= address_incrementer + bitstream_SRAM_location; //Instantiate fill of second register slot SRAM5
				bitstream_SRAM_location <= bitstream_SRAM_location + 6'd1; //Increments from 5 to 6
				
				M3_STATE <= S_INIT_03;
			end
			
			S_INIT_03: begin //Read in value from SRAM location 2 (15th bit tells if Q0 or Q1)
				Q_val <= SRAM_read_data[15]; //If 1, Q1, if 0 Q0
				SRAM_address <= address_incrementer + bitstream_SRAM_location; //Instantiate fill of third register slot SRAM6
				bitstream_SRAM_location <= bitstream_SRAM_location + 6'd1; //Increments from 6 to 7
				
				M3_STATE <= S_INIT_04;
			end			
			
			S_INIT_04: begin //Shift register 0 (loc 15:0) filled with SRAM4 contents
				the_shift_register[47:32] <= SRAM_read_data[15:0];

				M3_STATE <= S_INIT_05;
			end			
			
			S_INIT_05: begin //Shift register 1 (loc 31:16) filled with SRAM5 contents
				the_shift_register[31:16] <= SRAM_read_data[15:0];

				
				M3_STATE <= S_INIT_06;
			end						

			S_INIT_06: begin //Shift register 2 (loc 47:32) filled with SRAM6 contents
				the_shift_register[15:0] <= SRAM_read_data[15:0];
				
				M3_STATE <= S_READ_HEADER;
			end				

			S_READ_HEADER: begin 
				//Header reading state
				if(bitstream_index < 6'd16) begin //When first register has useful bits, continue to read next header
					if(the_shift_register[(6'd47-bitstream_index) -: 3)] == 3'b011) M3_STATE <= S_ZEROS_TO_END;
					if(the_shift_register[(6'd47-bitstream_index) -: 3)] == 3'b010) M3_STATE <= S_ZERO_RUN_LONG;
					if(the_shift_register[(6'd47-bitstream_index) -: 2)] == 2'b00) M3_STATE <= S_ZERO_RUN_SHORT;
					if(the_shift_register[(6'd47-bitstream_index) -: 2)] == 2'b11) M3_STATE <= S_3_BIT;
					if(the_shift_register[(6'd47-bitstream_index) -: 3)] == 3'b101) M3_STATE <= S_5_BIT;
					if(the_shift_register[(6'd47-bitstream_index) -: 3)] == 3'b100) M3_STATE <= S_9_BIT;
				end 
				
				else begin //When first register values are used up, wait clock cycles to allow new SRAM data to be shifted in
					if(wait_cycle == 5'd0) begin
						SRAM_we_n <= 1'b1;
						SRAM_address <= address_incrementer + bitstream_SRAM_location; //Instantiate fill of third register slot SRAM6
						bitstream_SRAM_location <= bitstream_SRAM_location + 6'd1; //Increments from 7 to 8 to ... n	
						wait_cycle <= wait_cycle + 5'd1;
					end
					if(wait_cycle <= 5'd2) wait_cycle <= wait_cycle + 5'd1; //For two clock cycles wait for SRAM read to come in
					if(wait_cycle == 5'd3) begin
						wait_cycle <= 5'd0;
						the_shift_register[47:32] <= the_shift_register[31:16];
						the_shift_register[31:16] <= the_shift_register[15:0];
						the_shift_register[15:0] <= SRAM_read_data[15:0];
						bitstream_index <= bitstream_index - 6'd16; //After shift, index is 8 less than before shift
					end
				end
			end
			
			S_ZEROS_TO_END: begin
				SRAM_we_n <= 1'b0;
				if(counter_pixel_write <= 5'd63) begin
					SRAM_write_data <= 16'd0;
					SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration
					counter_pixel_write <= counter_pixel_write + 6'd1;						
					if(counter_pixel_write == 5'd63) begin
						counter_block <= 14'd1;
					end
				end

			
				M3_STATE <= S_READ_HEADER;
			end
			
			S_ZERO_RUN_LONG: begin
				if(wait_cycle == 5'd0) SRAM_we_n <= 1'b0;

				if(the_shift_register[(47-bitstream_index - 2'd3) -= 4)] == 4'b0000) begin //If 0000 read, 16 zeros outputted
					if(wait_cycle < 5'd16) begin //Iterate 16 times for 16 writes of 0 value
						SRAM_write_data <= 16'd0;
						SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration
						counter_pixel_write <= counter_pixel_write + 6'd1;		
						wait_cycle <= wait_cycle + 5'd1;
						if(wait_cycle == 5'd15) begin
							wait_cycle <= 5'd0;
							bitstream_index <= bitstream_index - 6'd7;
							M3_STATE <= S_READ_HEADER;
						end
					end
				end
				
				else begin //Zeros = shift register 4 bit value
					if(wait_cycle < the_shift_register[(47-bitstream_index - 2'd3) -= 4)]) begin //Iterate for as many times as 4 bit value
						SRAM_write_data <= 16'd0;
						SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration
						counter_pixel_write <= counter_pixel_write + 6'd1;		
						wait_cycle <= wait_cycle + 5'd1;
						if(wait_cycle == (the_shift_register[(47-bitstream_index - 2'd2) -= 2] - 2'b01) begin
							wait_cycle <= 5'd0;
							bitstream_index <= bitstream_index - 6'd7;
							M3_STATE <= S_READ_HEADER;
						end
					end
				end				
			
			
			
				M3_STATE <= S_READ_HEADER;
			end
			
			S_ZERO_RUN_SHORT: begin
				if(wait_cycle == 5'd0) SRAM_we_n <= 1'b0;

				if(the_shift_register[(47-bitstream_index - 2'd2) -= 2)] == 2'b00) begin //If 00 read, 4 zeros outputted
					if(wait_cycle < 5'd4) begin //Iterate 4 times for 4 writes of 0 value
						SRAM_write_data <= 16'd0;
						SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration
						counter_pixel_write <= counter_pixel_write + 6'd1;		
						wait_cycle <= wait_cycle + 5'd1;
						if(wait_cycle == 5'd3) begin
							wait_cycle <= 5'd0;
							bitstream_index <= bitstream_index - 6'd4;

							M3_STATE <= S_READ_HEADER;
						end
					end
				end
				
				else begin //Zeros = shift register 2 bit value
					if(wait_cycle < the_shift_register[(47-bitstream_index - 2'd2) -= 2)]) begin //Iterate for as many times as 2 bit value
						SRAM_write_data <= 16'd0;
						SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration
						counter_pixel_write <= counter_pixel_write + 6'd1;		
						wait_cycle <= wait_cycle + 5'd1;
						if(wait_cycle == (the_shift_register[(47-bitstream_index - 2'd2) -= 2] - 2'b01) begin
							wait_cycle <= 5'd0;
							bitstream_index <= bitstream_index - 6'd4;
							M3_STATE <= S_READ_HEADER;
						end
					end
				end			
			
				M3_STATE <= S_READ_HEADER;
			end

			S_3_BIT: begin
				SRAM_we_n <= 1'b0;
				SRAM_write_data <= the_shift_register[(47-bitstream_index - 2'd2) -= 3];
				SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration
				
				if(counter_pixel_write == 5'd63) counter_block <= counter_block + 14'd1; //pixel counter will roll over in this scenario				
				counter_pixel_write <= counter_pixel_write + 6'd1;
				bitstream_index <= bitstream_index - 6'd5;
				M3_STATE <= S_READ_HEADER;
			end

			S_5_BIT: begin
				SRAM_we_n <= 1'b0;
				SRAM_write_data <= the_shift_register[(47-bitstream_index - 2'd3) -= 5];
				SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration

				if(counter_pixel_write == 5'd63) counter_block <= counter_block + 14'd1; //pixel counter will roll over in this scenario								
				counter_pixel_write <= counter_pixel_write + 6'd1;
				bitstream_index <= bitstream_index - 6'd8;
				M3_STATE <= S_READ_HEADER;
			end

			S_9_BIT: begin
				SRAM_we_n <= 1'b0;
				SRAM_write_data <= the_shift_register[(47-bitstream_index - 2'd3) -= 9];
				SRAM_address <= ultimate_offset_write; //After scanning order take offset into consideration

				if(counter_pixel_write == 5'd63) counter_block <= counter_block + 14'd1; //pixel counter will roll over in this scenario								
				counter_pixel_write <= counter_pixel_write + 6'd1;
				bitstream_index <= bitstream_index - 6'd12;
				M3_STATE <= S_READ_HEADER;
			end		
			
			default: M3_STATE <= STATE_3_IDLE;
			endcase
			
		end
	end	
end

//Consider logic of counter_block and comparison with row write and column write.

always_ff @ (posedge Clock_50 or negedge Resetn) begin //Implement a general counter for keeping track of reading SRAM LOC
	if (Resetn == 1'b0) begin
		counter_pixel_write <= 6'd0;
		counter_row <= 5'd0;
		counter_column <= 6'd0;
		counter_pixel_write <= 5'd0;
		counter_row_write <= 5'd0;
		counter_column_write <= 6'd0;
		
	end
	else begin
		//Offset values related to read
		
		if(counter_pixel_write == 6'd63) begin //Column counter of 8x8 blocks
			if( (iz_y && counter_column_write == 6'd39) || (~iz_y  && counter_column_write == 6'd19) ) counter_column_write <= 6'd0; //Reset for Y at 39 and for UV at 19
			else counter_column_write <= counter_column_write + 6'd1;
		end
	
		if(counter_pixel_write == 6'd63 && ( (iz_y && counter_column_write == 6'd39) || (~iz_y  && counter_column_write == 6'd19) ) ) begin 
			if(counter_row_write == 5'd29) counter_row_write <= 5'd0; //Row counter of 8x8 blocks
			else counter_row_write <= counter_row_write + 5'd1;
		end
	end
end


assign ultimate_offset_write = {9'd0,{counter_column_write,counter_pixel_write[2:0]}} + (iz_y ? 
					  ({2'd0,{counter_row_write,counter_pixel_write[5:3]},8'd0} + {4'd0,{counter_row_write,counter_pixel_write[5:3]},6'd0}) : ({3'd0,{counter_row_write,counter_pixel_write[5:3]},7'd0} + {5'd0,{counter_row_write,counter_pixel_write[5:3]},5'd0}) );
	

/*
always_ff @ (posedge Clock_50 or negedge Resetn) begin //Implement a general counter for keeping track of reading SRAM LOC
	if (Resetn == 1'b0) begin
		counter_pixel_write <= 6'd0;
		counter_row <= 5'd0;
		counter_column <= 6'd0;
		counter_pixel_write <= 5'd0;
		counter_row_write <= 5'd0;
		counter_column_write <= 6'd0;
		
	end
	else begin
		//Offset values related to read
		if(increment_read) counter_pixel_write <= counter_pixel_write + 6'd1; //Pixel Counter in 8x8

		
		if(increment_read && counter_pixel_write == 6'd63) begin //Column counter of 8x8 blocks
			if( (iz_y && counter_column == 6'd39) || (~iz_y  && counter_column == 6'd19) ) counter_column <= 6'd0; //Reset for Y at 39 and for UV at 19
			else counter_column <= counter_column + 6'd1;
		end
	
		if(increment_read && counter_pixel_write == 6'd63 && ( (iz_y && counter_column == 6'd39) || (~iz_y  && counter_column == 6'd19) ) ) begin 
			if(counter_row == 5'd29) counter_row <= 5'd0; //Row counter of 8x8 blocks
			else counter_row <= counter_row + 5'd1;
		end
		
		//Offset values related to WRITE
		if(increment_write) counter_pixel_write <= counter_pixel_write + 5'd1; //Pixel Counter in 8x8

		
		if(increment_write && counter_pixel_write == 5'd31) begin //Column counter of 8x8 blocks
			if( (iz_y_write && counter_column_write == 6'd39) || (~iz_y_write  && counter_column_write == 6'd19) ) counter_column_write <= 6'd0; //Reset for Y at 39 and for UV at 19
			else counter_column_write <= counter_column_write + 6'd1;
		end
	
		if(increment_write && counter_pixel_write == 5'd31 && ( (iz_y_write && counter_column_write == 6'd39) || (~iz_y_write  && counter_column_write == 6'd19) ) ) begin 
			if(counter_row_write == 5'd29) counter_row_write <= 5'd0; //Row counter of 8x8 blocks
			else counter_row_write <= counter_row_write + 5'd1;
		end
		
		
	end
end



assign ultimate_offset_write = {9'd0,{counter_column_write,counter_pixel_write[1:0]}} + (iz_y_write ? 
					  ({3'd0,{counter_row_write,counter_pixel_write[4:2]},7'd0} + {5'd0,{counter_row_write,counter_pixel_write[4:2]},5'd0}) : ({4'd0,{counter_row_write,counter_pixel_write[4:2]},6'd0} + {6'd0,{counter_row_write,counter_pixel_write[4:2]},4'd0}) );

assign ultimate_offset = {9'd0,{counter_column,counter_pixel_write[2:0]}} + (iz_y ? 
					  ({2'd0,{counter_row,counter_pixel_write[5:3]},8'd0} + {4'd0,{counter_row,counter_pixel_write[5:3]},6'd0}) : ({3'd0,{counter_row,counter_pixel_write[5:3]},7'd0} + {5'd0,{counter_row,counter_pixel_write[5:3]},5'd0}) );
	//32 + 128 = 160
*/
endmodule
