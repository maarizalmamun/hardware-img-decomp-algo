/*
Copyright by Saaijith Vigneswaran, Maariz Almamun, and Nicola Nicolici (The Squad)
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
module  the_cosine_milestone (
		input logic Clock_50,
		input logic Resetn,
		input logic m2_enable,
		
		//SRAM Controller 
		input logic [17:0] SRAM_read_data,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,
		output logic [17:0] SRAM_address,
		output logic m2_disable
		);
		
		
parameter OFFSET_preY = 18'd76800,
		  OFFSET_preU = 18'd153600,
		  OFFSET_preV = 18'd192000,
		  OFFSET_postU = 18'd38400,
		  OFFSET_postV = 18'd57600,
		  OFFSET_DRAM_C = 8'd64;
		  
		  
logic [5:0] counter_pixel; //Counter of what segment of 8x8 block
logic [4:0] counter_pixel_write;
logic [4:0] counter_row; //counter of what block # within a row
logic [5:0] counter_column; 
logic [4:0] counter_row_write; //counter of what block # within a row
logic [5:0] counter_column_write; 
logic [4:0] counter_store_Sprime; //counter of where to store S in DRAM


logic [4:0] counter_read_S_values;
logic [7:0] counter_DRAM_read; //counts what index reading C values and indirectly S' values
logic [5:0] counter_DRAM_write; //counts what index writing T values to DRAM
logic [5:0] counter_fetch_state; //State counter within fetch blocks
logic [7:0] counter_common_state; //State counter within common states
logic [7:0] buffy_S[1:0]; //Stores 2 S values as buffer  

logic increment_read;
logic increment_write;
logic iz_y;
logic iz_y_write;
logic iz_u;
logic iz_u_write;
logic flag_complete;
logic flag_complete2;
logic [17:0] ultimate_offset;
logic [17:0] ultimate_offset_write;

//state_type state;
M2_STATE_type M2_STATE;

logic [15:0] Sprimez;
//Pixel Row: concatanation of {counter_row[2:0],counter_pixel[2:0]}
//Pixel column: concatenation of {counter_column[2:0],counter_pixel[5:3]}

logic signed [31:0] operator_0a, operator_0b, operator_1a, operator_1b;
logic signed [63:0] product_generator0, product_generator1;
logic signed [31:0] sum_compiler0;
logic signed [31:0] sum_compiler1;
logic [7:0] S_is_life[1:0];

logic [6:0]  DRAM_address_a[1:0]; //   address_a[0] = DRAM0, address_a[1] = DRAM1		
logic [6:0]  DRAM_address_b[1:0]; //   address_b[0] = DRAM0, address_b[1] = DRAM1		
logic [31:0]  DRAM_write_data_a[1:0];//data_a[0] = DRAM0, data_b[1] = DRAM1		
logic [31:0]  DRAM_write_data_b[1:0];		
logic DRAM_we_n_a[1:0]; // a 1 represents a write, a 0 represents a read		
logic DRAM_we_n_b[1:0];		
logic [31:0]  DRAM_read_data_a[1:0];		
logic [31:0]  DRAM_read_data_b[1:0];
		
dual_port_RAM0 dual_port_RAM_inst0 (		
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
dual_port_RAM1 dual_port_RAM_inst1 (		
	.address_a ( DRAM_address_a[1] ),		
	.address_b ( DRAM_address_b[1] ),		
	.clock ( Clock_50 ),		
	.data_a ( DRAM_write_data_a[1]),		
	.data_b ( DRAM_write_data_b[1]),		
	.wren_a ( DRAM_we_n_a[1] ),		
	.wren_b ( DRAM_we_n_b[1] ),		
	.q_a ( DRAM_read_data_a[1] ),		
	.q_b ( DRAM_read_data_b[1] )		
	);		


always_ff @ (posedge Clock_50 or negedge Resetn) begin //Implement a general counter for keeping track of reading SRAM LOC
	if (Resetn == 1'b0) begin
		counter_read_S_values <= 5'd0;
		SRAM_write_data <= 16'd0;
		increment_read <= 1'b0;
		m2_disable <= 1'b0;
		iz_y <= 1'b1; //Are we working with the Y's or the U's and the V's?
		iz_u <= 1'b0;
		iz_y_write <= 1'b1;		
		iz_u_write <= 1'b0;
		increment_write <= 1'b0;
		flag_complete <= 1'b0; //indicates all values of YUV have been fetched
		flag_complete2 <= 1'b0;
		SRAM_we_n <= 1'b1;
		SRAM_address <= 18'd0;
		counter_DRAM_read <= 8'd0;
		counter_DRAM_write <= 6'd0;
		counter_fetch_state <= 6'd0;
		counter_common_state <= 8'd0;
		counter_store_Sprime <= 5'd0;
		Sprimez <= 16'd0;
		sum_compiler0 <= 32'd0;
		sum_compiler1 <= 32'd0;
		buffy_S[0] <= 8'd0;
		buffy_S[1] <= 8'd0;
		M2_STATE <= STATE_2_IDLE;
	end
	else begin
	
		 case (M2_STATE)
		STATE_2_IDLE: begin
			increment_read <= 1'b0;
			m2_disable <= 1'b0;
			SRAM_write_data <= 16'd0;
			counter_read_S_values <= 5'd0;
			iz_y <= 1'b1; //Are we working with the Y's or the U's and the V's?
			iz_u <= 1'b0;
			iz_y_write <= 1'b1;		
			iz_u_write <= 1'b0;
			increment_write <= 1'b0;
			flag_complete <= 1'b0;
			flag_complete2 <= 1'b0;
			SRAM_we_n <= 1'b1;
			SRAM_address <= 18'd0;
			counter_DRAM_read <= 8'd0;
			counter_DRAM_write <= 6'd0;
			counter_fetch_state <= 6'd0;
			counter_common_state <= 8'd0;
			counter_store_Sprime <= 5'd0;
			sum_compiler0 <= 32'd0;
			sum_compiler1 <= 32'd0;
			buffy_S[0] <= 8'd0;
			buffy_S[1] <= 8'd0;
			
			//sum_compiler
			Sprimez <= 16'd0;
			counter_store_Sprime <= 5'd0;
				//START MILESTONE 2 CODE
				if(m2_enable) begin
					M2_STATE <= S_INIT_00;
					increment_read <= 1'b1; //pixel = 0 at end of clock cycle					
				end
			end




		S_INIT_00: begin //Call for read of S0, PC = 1 at end of clock cycle
			SRAM_we_n <= 1'b1; //Initialize reading
			SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S0

			
			M2_STATE <= S_INIT_01;
		end
		S_INIT_01: begin //Call for read of S1, counter_pixel = 2 at end of clock cycle		
			
			SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S1
			
			M2_STATE <= S_INIT_02;
		end
		S_INIT_02: begin //Call for read of S2 P.C. = 3 at end
			SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S2
			
			M2_STATE <= S_FETCH_S;
			//Call for Read of C0 simulateously
			//Setup location tracker for reading from DRAM >> algorithm for C


		end		
		
		//Values beginning appearing in SRAM_read_data and DRAM_read_data
		//THIS STATE ITERATES FOR 64 CLOCK CYCLES
		S_FETCH_S: begin //Call for read of S3, pull read data for S0 Pixel Counter = 3 > 4

			//State Monitor
			counter_fetch_state <= counter_fetch_state + 6'd1; //Counter to determine which S value is being read in


			//These states are associated with calling for reads for S3 through S63
			SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S3 through till S63
			//THIS BLOCK WILL STOP counter_pixel ONCE IT ROLLS OVER (stop ultimate_offset and pixel counter from increment_reading further)
			if(counter_pixel == 6'd63) begin
				increment_read <= 1'b0;
			end


			//THIS BLOCK. READS AND STORES S' DATA FROM SRAM TO DRAM. IT STORES EVEN VALUES IN A BUFFER AND CONCATENATES INTO DRAM WHEN ODD VALUES APPEAR
			if( counter_fetch_state[0] == 1'b0) begin //First iteration goes here, when counter_fetch_state[0] == 0 and S'0 comes from SRAM, through until S62
				Sprimez <= SRAM_read_data[15:0];
			end			
			else begin //Second iteration goes here, when counter_fetch_state[0] = b1 and S'1 comes from SRAM through until S63
				DRAM_we_n_b[0] <= 1'b1; //Enable writing to DRAM0
				DRAM_address_b[0] <= counter_store_Sprime;//Store S0 in  AND DRAM0 memory location 0
				DRAM_write_data_b[0] <= {Sprimez,SRAM_read_data[15:0]};		
				counter_store_Sprime <= counter_store_Sprime + 5'd1;
			end

			
			//These call for reads from DRAM of S0S1 and C0C1, S2S3 C2C3 (3rd onwards), until counter_DRAM_read == 255
			//After entering this condition, counter_DRAM goes from 0 to 1
			if ( counter_fetch_state == 6'd62)begin //Recieve S'62 at this clock cycle
				DRAM_we_n_a[0] <= 1'b0; //enable reading from DRAM0 (S0S1 value)
				DRAM_we_n_a[1] <= 1'b0; //enable reading from DRAM1 (C0C1 value)

				DRAM_address_a[0] <=  {counter_DRAM_read[7:5],counter_DRAM_read[1:0]}; //Call for read of S0S1
				DRAM_address_a[1] <=  {counter_DRAM_read[4:2],counter_DRAM_read[1:0]}; //Call for read of C0C1
				counter_DRAM_read <= counter_DRAM_read + 5'd1; //counter_DRAM_read = 0

				//call for reads 
			end 
			//After entering this condition, counter_DRAM_read goes from 1 to 2
				DRAM_address_a[0] <=  {counter_DRAM_read[7:5],counter_DRAM_read[1:0]}; //Call for read of S2S3
			if (counter_fetch_state == 6'd63) begin 
				DRAM_address_a[1] <=  counter_DRAM_read[4:0]; //Call for read of C2C3
				counter_DRAM_read <= counter_DRAM_read + 5'd1; //counter_DRAM_read = 1
				
				//counter_fetch_state <= 6'd0;
				
				DRAM_we_n_b[0] <= 1'b1; //Enable writing for T terms into DRAM0				
				M2_STATE <= S_COMPUTE_T;
			end 
			else begin
				M2_STATE <= S_FETCH_S;
			end
			//Begin computation of S0 * C0 at next state
			//increment_read = 0 by end of state; counter_store_Sprime rolls over, counter_fetch_state rolls over			
		end
		
		
		
		
		//When entered, begin calling for 3rd S's and C's (S4S5/C4C5) and reading in S0S1/C0C1 until 255, don't care about calls after this point
		//Reset counter_DRAM_read at end of state
		S_COMPUTE_T: begin 
			//Entering here, counter_DRAM_read goes from 2 to 3, At this time, we get the first terms for S and C
			//When counter_DRAM_read is 255 > 0 (256), we get the last terms of S and C

			counter_common_state <= counter_common_state + 8'd1; //Iterates from compute State 000 to 255
			if(counter_common_state == 8'd0) DRAM_we_n_b[0] <= 1'b1;
			//if(counter_DRAM_read >= 8'd2) begin
			//When state = 254, counter_DRAM_read rolls over to 0
			
			//BLOCK CALLS READS FOR ALL S AND C VALUES FROM DRAM0 AND DRAM1
			if(counter_common_state < 8'd254) begin
				DRAM_address_a[0] <= {counter_DRAM_read[7:5],counter_DRAM_read[1:0]}; //Call for read of S' values
				DRAM_address_a[1] <= counter_DRAM_read[4:0]; //Call for read of C values
				counter_DRAM_read <= counter_DRAM_read + 5'd1; //counter_DRAM_read = 2|10|20|26
			end
			
			
			//BLOCK WRITES T VALUES TO DRAM0 IN SUBSTATES 0 AND 4
			//in Substate 0 >> counter_DRAM_read = 2|10|18|26.. >> bits [2:0] == 3'b010
			//in Substate 4 >> counter_DRAM_read = 6|14|22|30.. >> bits [2:0] == 3'b110
			//counter_DRAM_write starts at 0, enters this block, and increment_reads up until 63, where it rolls over and program should terminate			
			if(counter_DRAM_read[2:0] == 3'b110 || (counter_DRAM_read[2:0] == 3'b010 && counter_DRAM_read != 8'd2) ) begin //Performs all but LAST T write
				DRAM_address_b[0] <= 7'd64 + counter_DRAM_write; //Write T to address counter_DRAM_write
				DRAM_write_data_b[0] <= sum_compiler0;
				counter_DRAM_write <= counter_DRAM_write + 6'd1; //first time increment_read from 0 to 1		
				
				sum_compiler0 <= product_generator0[31:0] + product_generator1[31:0];
			end			
			else begin
				sum_compiler0 <= sum_compiler0 + product_generator0[31:0] + product_generator1[31:0]; //compile S'2*C2 + S'3*C3
				//M2_STATE <= S_COMPUTE_T;
			end


				
			//counter_DRAM_read == 8'd0
			if(counter_common_state == 8'd254) begin //2nd last state, begin calling terms needed for compute Cs state
				DRAM_we_n_a[0] <= 1'b0; //Initialize both a port of DRAM0 to read T value
				DRAM_we_n_a[1] <= 1'b0; //Initialize DRAM1 to read C values (not C transpose values)
				
				DRAM_address_a[0] <= 7'd64 + {counter_DRAM_read[2:0],counter_DRAM_read[7:6],counter_DRAM_read[3]}; //Location of T0 in DRAM0
				DRAM_address_a[1] <= 7'd32 + {counter_DRAM_read[2:0],counter_DRAM_read[5:4]}; //Location of C0C1 in DRAM1			
				counter_DRAM_read <= counter_DRAM_read + 8'd1;
				
			end


			//TERMINATING CONDITION: When counter_DRAM_write == 6'd63 and enters this condition, the last write has been completed (T63)
			//Move to next state when final write complete (counter_DRAM_write = 63)
			if(counter_common_state == 8'd255) begin //last state, call second terms needed to compute Cs state
				
				//counter_DRAM_read == 8'd1 at this final state
				DRAM_address_a[0] <= 7'd64 + {counter_DRAM_read[2:0],counter_DRAM_read[7:6],counter_DRAM_read[3]}; //Location of T8 in DRAM0
				DRAM_address_a[1] <= 7'd32 + {counter_DRAM_read[2:0],counter_DRAM_read[5:4]}; //Location of C8C9 in DRAM1
				counter_DRAM_read <= counter_DRAM_read + 8'd1;
				
				M2_STATE <= S_COMMON_1; 
			end			
		end
		
		
		//Entering here, counter_DRAM_read goes from 2 to 3, At this time, we get the first terms for S and C
		//When counter_DRAM_read is 255 > 0 (256), we get the second last terms of S and C		
		S_COMMON_1: begin

			counter_common_state <= counter_common_state + 8'd1; //Iterates from compute State 000 to 255

			//FINAL WRITE FOR T values
			if(counter_common_state == 8'd0) begin
				DRAM_we_n_b[1] <= 1'b1;
				DRAM_address_b[0] <= 7'd64 + counter_DRAM_write; //Write to address counter_DRAM_write
				DRAM_write_data_b[0] <= sum_compiler0; //Final t value in 8v8 matrix
				counter_DRAM_write <= counter_DRAM_write + 6'd1; //first time increment_read from 0 to 1					
				//counter_DRAM_write rolls over to 0 at this point
			end

			//BLOCK CALLS READS FOR ALL T AND C VALUES FROM DRAM0 AND DRAM1	
			//These will call for values from 3rd read until termination (past 63 will not be used)			
			if(counter_common_state < 8'd254) begin
				DRAM_address_a[0] <= 7'd64 + {counter_DRAM_read[2:0],counter_DRAM_read[7:6],counter_DRAM_read[3]}; //Location of T16 in DRAM0 and onwards
				DRAM_address_a[1] <= 7'd32 + {counter_DRAM_read[2:0],counter_DRAM_read[5:4]}; //Location of C16C17 in DRAM1	and onwards
				counter_DRAM_read <= counter_DRAM_read + 8'd1;		
			end


			//BLOCK WRITES T VALUES TO DRAM0 IN SUBSTATES 0
			//in Substate 0 >> counter_DRAM_read = 2|10|18|26.. >> bits [2:0] == 3'b010
			//counter_DRAM_write starts at 0, enters this block, and increment_reads up until 31, where it rolls over and program should terminate	
			

			if(counter_common_state[2:0] == 3'b000 & counter_common_state != 8'd0) begin 
			//if STATES 0|8|16|24|32|40|48|56
			//if STATE 8|24|40|56 >> STORE IN BUFFER (bit 3 is 8's, bit 4 is 16's)
			//if STATES 16|32|48|64 >> Take buffer values and store appropriately
				
				//BUFFER STORAGE STATE
				if(counter_common_state[3] == 1'b1) begin //If bit 3 is 1 then buffer state (States 8,24,40,56,etc.)
					buffy_S[0] <= S_is_life[0]; //Stores the two computed S values into buffers
					buffy_S[1] <= S_is_life[1];				
				end
				//INITIATE 2 STATE WRITE BURST STATE
				else begin //Bit 3 = 0 (State is multiple of 16 (ie. 16|32|48|64...)
					DRAM_address_b[1] <= 7'd64 + {counter_DRAM_write[3:1],counter_DRAM_write[5:4]}; //Write to address counter_DRAM_write
					DRAM_write_data_b[1] <= {buffy_S[0],S_is_life[0]};
					counter_DRAM_write <= counter_DRAM_write + 6'd2; //increment_read by 2 so it becomes a 32 bit counter rather than 64					
					
					buffy_S[0] <= buffy_S[1]; //Transfer buffer 1 value to 0 so buffer1 can be filled with sum_compiler1 value
					buffy_S[1] <= S_is_life[1];
					//{buffy_S[0],S_is_life[0]} is stored first
					//{buffy_S[1],S_is_life[1]} is stored second	
				end				
				
				sum_compiler0 <= product_generator0[31:0];
				sum_compiler1 <= product_generator1[31:0];
			end			
			else begin
				//STATES 17|33|49|57 (16n+1), complete writing of the other pair of S values
				if(counter_common_state[3:0]== 4'b0001 & counter_common_state != 8'd1) begin
					DRAM_address_b[1] <= 7'd64 + {counter_DRAM_write[3:1],counter_DRAM_write[5:4]}; //Write to address counter_DRAM_write
					DRAM_write_data_b[1] <= {buffy_S[0],buffy_S[1]};
					counter_DRAM_write <= counter_DRAM_write + 6'd2; //increment_read by 2 so it becomes a 32 bit counter rather than 64							
				end
				if(counter_common_state == 8'd0) begin
					sum_compiler0 <= product_generator0[31:0];
					sum_compiler1 <= product_generator1[31:0];
				end
				else begin
					sum_compiler0 <= sum_compiler0 + product_generator0[31:0]; //compile S'2*C2 + S'3*C3
					sum_compiler1 <= sum_compiler1 + product_generator1[31:0];
				end
			end
			
			
			//counter_DRAM_read == 8'd0			
			if(counter_common_state == 8'd254) begin //2nd last state, begin calling terms needed for compute Ct state
			//Need to update this block
				DRAM_we_n_a[0] <= 1'b0; //enable reading from DRAM0 (S'0S'1 value)
				DRAM_we_n_a[1] <= 1'b0; //enable reading from DRAM1 (C0C1 transposed value)
				//DRAM_we_n_b[1] <= 1'b0; //enable reading from DRAM1 S0S1 (for writing to SRAM)


				DRAM_address_a[0] <=  {counter_DRAM_read[7:5],counter_DRAM_read[1:0]}; //Call for read of S0S1 prime
				DRAM_address_a[1] <=  {counter_DRAM_read[4:2],counter_DRAM_read[1:0]}; //Call for read of C0C1

				//DRAM_address_b[1] <=  8'd64 + counter_DRAM_read; //Call for read of S0S1
				counter_DRAM_read <= counter_DRAM_read + 5'd1; //counter_DRAM_read = 0
				
			end 

			if(counter_common_state == 8'd255) begin //last state, call second terms needed to compute Cs state
				//counter_DRAM_read == 8'd1 at this final state
				DRAM_address_a[0] <=  {counter_DRAM_read[7:5],counter_DRAM_read[1:0]}; //Call for read of S0S1 prime
				DRAM_address_a[1] <=  {counter_DRAM_read[4:2],counter_DRAM_read[1:0]}; //Call for read of C0C1

				counter_DRAM_read <= counter_DRAM_read + 5'd1; //counter_DRAM_read = 0
				
				//State: Transition from reading y mode to u mode to v mode
				if(counter_column == 6'd00 && counter_row == 5'd00) begin
					if(iz_y == 1'b1 && iz_u == 1'b0) begin //transition from y to u
						iz_y <= 1'b0;
						iz_u <= 1'b1;
					end
					if(iz_y == 1'b0 && iz_u == 1'b1) iz_u <= 1'b0; //transition from u to v	
					if(iz_y == 1'b0 && iz_u == 1'b0) flag_complete <= 1'b1; //transition from v to done
				end
				
				
				M2_STATE <= S_COMMON_2; 
			end
			else M2_STATE <= S_COMMON_1;
			
			
			//FETCH STATE: Same structure as lead in Fetch state, utilizing fetch_common_state signal as termination case
			//Module instantiated near end of Common block 1 however not at the very edge of it
			if(counter_common_state == 8'd176) begin
				increment_read <= 1'b1; //pixel = 0 at end of clock cycle					
			end

			if(counter_common_state == 8'd177) begin //Call for read of S0, PC = 1 at end of clock cycle
				SRAM_we_n <= 1'b1; //Initialize reading
				SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S0
			end
			if(counter_common_state == 8'd178) begin //Call for read of S1, counter_pixel = 2 at end of clock cycle		
				SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S1			
			end
			if(counter_common_state == 8'd179) begin //Call for read of S2 P.C. = 3 at end
				SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S2
				//Call for Read of C0 simulateously
			end		
			//Values beginning appearing in SRAM_read_data and DRAM_read_data
			
			//THIS STATE ITERATES FOR 64 CLOCK CYCLES
			if( (counter_common_state == 8'd180 && counter_fetch_state == 6'd0) || (counter_common_state > 8'd180 && counter_fetch_state != 6'd0) )begin //Call for read of S3, pull read data for S0 Pixel Counter = 3 > 4

				//State Monitor
				counter_fetch_state <= counter_fetch_state + 6'd1; //Counter to determine which S value is being read in


				//These states are associated with calling for reads for S3 through S63
				SRAM_address <= ultimate_offset + (iz_y ? OFFSET_preY : iz_u ? OFFSET_preU : OFFSET_preV); //Call for read S3 through till S63
				//THIS BLOCK WILL STOP counter_pixel ONCE IT ROLLS OVER (stop ultimate_offset and pixel counter from increment_reading further)
				if(counter_pixel == 6'd63) begin
					increment_read <= 1'b0;
				end


				//THIS BLOCK. READS AND STORES S' DATA FROM SRAM TO DRAM. IT STORES EVEN VALUES IN A BUFFER AND CONCATENATES INTO DRAM WHEN ODD VALUES APPEAR
				if( counter_fetch_state[0] == 1'b0) begin //First iteration goes here, when counter_fetch_state[0] == 0 and S'0 comes from SRAM, through until S62
					Sprimez <= SRAM_read_data[15:0];
				end			
				else begin //Second iteration goes here, when counter_fetch_state[0] = b1 and S'1 comes from SRAM through until S63
					DRAM_we_n_b[0] <= 1'b1; //Enable writing to DRAM0
					DRAM_address_b[0] <= counter_store_Sprime;//Store S0 in  AND DRAM0 memory location 0
					DRAM_write_data_b[0] <= {Sprimez,SRAM_read_data[15:0]};		
					counter_store_Sprime <= counter_store_Sprime + 5'd1;
				end
			end					
		end			
			//Beginning Fetching State here
		
		S_COMMON_2: begin 
			//Entering here, counter_DRAM_read goes from 2 to 3, At this time, we get the first terms for S' and C
			//When counter_DRAM_read is 255 > 0 (256), we get the last terms of S' and C

			counter_common_state <= counter_common_state + 8'd1; //Iterates from compute State 000 to 255
			
			if(counter_common_state == 8'd0) begin
				DRAM_we_n_b[0] <= 1'b1;
				DRAM_address_b[1] <= 7'd91; //Write to address counter_DRAM_write 2nd last is exactly location 91
				DRAM_write_data_b[1] <= {buffy_S[0],S_is_life[0]};
				counter_DRAM_write <= counter_DRAM_write + 6'd2; //increment_read by 2 so it becomes a 32 bit counter rather than 64					
				
				buffy_S[0] <= buffy_S[1]; //Transfer buffer 1 value to 0 so buffer1 can be filled with sum_compiler1 value
				buffy_S[1] <= S_is_life[1];
			end
			
			if(counter_common_state == 8'd1) begin
				DRAM_address_b[1] <= 7'd95; //Write to address counter_DRAM_write,last is exactly location 95
				DRAM_write_data_b[1] <= {buffy_S[0],buffy_S[1]};
				counter_DRAM_write <= counter_DRAM_write + 6'd2; //increment_read by 2 so it becomes a 32 bit counter rather than 64				
			end
			
			//if(counter_DRAM_read >= 8'd2) begin
			//When state = 254, counter_DRAM_read rolls over to 0
			
			//BLOCK CALLS READS FOR ALL S AND C VALUES FROM DRAM0 AND DRAM1
			if(counter_common_state < 8'd254) begin
				DRAM_address_a[0] <= {counter_DRAM_read[7:5],counter_DRAM_read[1:0]}; //Call for read of S' values
				DRAM_address_a[1] <= counter_DRAM_read[4:0]; //Call for read of C values
				counter_DRAM_read <= counter_DRAM_read + 5'd1; //counter_DRAM_read = 2|10|20|26
			end
			
			
			//BLOCK WRITES T VALUES TO DRAM0 IN SUBSTATES 0 AND 4
			//in Substate 0 >> counter_DRAM_read = 2|10|18|26.. >> bits [2:0] == 3'b010
			//in Substate 4 >> counter_DRAM_read = 6|14|22|30.. >> bits [2:0] == 3'b110
			//counter_DRAM_write starts at 0, enters this block, and increment_reads up until 63, where it rolls over and program should terminate			
			if(counter_common_state[1:0] == 2'b00 && counter_common_state != 8'd0) begin //Performs all but LAST T write
				DRAM_address_b[0] <= 7'd64 + counter_DRAM_write; //Write to address counter_DRAM_write
				DRAM_write_data_b[0] <= sum_compiler0;
				counter_DRAM_write <= counter_DRAM_write + 6'd1; //first time increment_read from 0 to 1		
				
				sum_compiler0 <= product_generator0[31:0] + product_generator1[31:0];
			end			
			else begin
				if(counter_common_state == 8'd0) sum_compiler0 <= product_generator0[31:0] + product_generator1[31:0];
				else sum_compiler0 <= sum_compiler0 + product_generator0[31:0] + product_generator1[31:0]; //compile S'2*C2 + S'3*C3
				//M2_STATE <= S_COMPUTE_T;
			end
			
			//counter_DRAM_read == 8'd0
			if(counter_common_state == 8'd254) begin //2nd last state, begin calling terms needed for compute Cs state
				DRAM_we_n_a[0] <= 1'b0; //Initialize both a port of DRAM0 to read T value
				DRAM_we_n_a[1] <= 1'b0; //Initialize DRAM1 to read C values (not C transpose values)
				
				DRAM_address_a[0] <= 7'd64 + {counter_DRAM_read[2:0],counter_DRAM_read[7:6],counter_DRAM_read[3]}; //Location of T0 in DRAM0
				DRAM_address_a[1] <= 7'd32 + {counter_DRAM_read[2:0],counter_DRAM_read[5:4]}; //Location of C0C1 in DRAM1			
				counter_DRAM_read <= counter_DRAM_read + 8'd1;
				
			end
			
			if(counter_common_state == 8'd35) increment_write <= 1'b0;
			if(counter_common_state == 8'd36) SRAM_we_n <= 1'b1;
			
			
			//TERMINATING CONDITION: When counter_DRAM_write == 6'd63 and enters this condition, the last write has been completed (T63)
			//Move to next state when final write complete (counter_DRAM_write = 63)
			if(counter_common_state == 8'd255) begin //last state, call second terms needed to compute Cs state
				
				//counter_DRAM_read == 8'd1 at this final state
				DRAM_address_a[0] <= 7'd64 + {counter_DRAM_read[2:0],counter_DRAM_read[7:6],counter_DRAM_read[3]}; //Location of T8 in DRAM0
				DRAM_address_a[1] <= 7'd32 + {counter_DRAM_read[2:0],counter_DRAM_read[4:3]}; //Location of C8C9 in DRAM1
				counter_DRAM_read <= counter_DRAM_read + 8'd1;
				
				//Increment what to write to next depending on roll over
				if(counter_column_write == 6'd00 && counter_row_write == 5'd00) begin
					if(iz_y_write == 1'b1 && iz_u_write == 1'b0) begin //transition from y to u
						iz_y_write <= 1'b0;
						iz_u_write <= 1'b1;
					end
					if(iz_y_write == 1'b0 && iz_u_write == 1'b1) iz_u_write <= 1'b0; //transition from u to v	
				end
				
				//CONDITION: LAST WRITE HAS OCCURED > RETURN TO IDLE
				if(flag_complete2 == 1'b1) begin 
					m2_disable <= 1'b1;
					M2_STATE <= STATE_2_IDLE;
				end
				
				//SECOND LAST WRITE COMPLETED, ITERATE THROUGH COMMON 1 AND 2 ONE MORE TIME
				else begin
					if(flag_complete == 1'b1) flag_complete2 <= 1'b1;
					M2_STATE <= S_COMMON_1;
				end  				
				
				
			end
			else M2_STATE <= S_COMMON_2;
			
			//WRITING BLOCK - S VALUES TO SRAM
			
			if(counter_common_state >= 8'd2) begin //Begin initializing reads of S from DRAM to write to SRAM
				DRAM_we_n_b[1] <= 1'b0; //enable reading from DRAM1 S0S1 (for writing to SRAM)
				if(counter_common_state == 8'd3) increment_write <= 1'b1;
				if(counter_common_state < 8'd34) begin
					DRAM_address_b[1] <=  7'd64 + counter_read_S_values;
					counter_read_S_values <= counter_read_S_values + 5'd1; //counter_read_S_values = 0
				end								
			end
		
			
			if(counter_common_state >= 8'd4 && counter_common_state < 8'd36) begin
				SRAM_we_n <= 1'b0; //Enable writes to SRAM
				
				//Conditional blocks determining SRAM_address

				SRAM_address <= iz_y_write ? ultimate_offset_write : iz_u_write ? ultimate_offset_write + OFFSET_postU : ultimate_offset_write + OFFSET_postV;
				//DRAM_address_b[1] <=  7'd64 + counter_read_S_values; //Call for read of S0S1
				//counter_read_S_values <= counter_read_S_values + 5'd1; //counter_read_S_values = 0
				SRAM_write_data <= DRAM_read_data_b[1];
				//DRAM_read_data_b[1]
				//Calls for reads of S values for writing to SRAM

			end

		end

		
		default: M2_STATE <= STATE_2_IDLE;
		endcase
		
	end
end




always_comb begin
	if((M2_STATE == S_COMPUTE_T) || (M2_STATE == S_COMMON_2)) begin
	//Q's .. $signed? do we need to sign extend and pad to 32 bits?
		operator_0a = $signed (DRAM_read_data_a[0][31:16]); //(S'even) ie. 0,2,4,6
		operator_0b = $signed (DRAM_read_data_a[1][31:16]); //(Ceven) ie. 0,2,4,6
		operator_1a = $signed (DRAM_read_data_a[0][15:0]); //(S'odd) ie. 1,3,5,7
		operator_1b = $signed (DRAM_read_data_a[1][15:0]); //(Codd) ie. 1,3,4,7	
	end 
	else begin
			if(M2_STATE == S_COMMON_1 || M2_STATE == S_COMPUTE_S) begin
				operator_0a = $signed (DRAM_read_data_a[1][31:16]);//Ceven
				operator_0b = ($signed (DRAM_read_data_a[0][31:0])) >>> 8;//T
				operator_1a = $signed (DRAM_read_data_a[1][15:0]);//Codd
				operator_1b = ($signed (DRAM_read_data_a[0][31:0])) >>> 8;//Same ol' T 
			end
			else begin
				operator_0a = 32'd0;
				operator_0b = 32'd0;
				operator_1a = 32'd0;
				operator_1b = 32'd0;
			end
	end
	//Block to determine operator0a,1a,0b,1b
end


assign product_generator0 = operator_0a * operator_0b;
assign product_generator1 = operator_1a * operator_1b;

assign S_is_life[0] = sum_compiler0[31] == 1'b1 ? 8'd0 : |sum_compiler0[30:24] ? 8'd255 : sum_compiler0[23:16];
assign S_is_life[1] = sum_compiler1[31] == 1'b1 ? 8'd0 : |sum_compiler1[30:24] ? 8'd255 : sum_compiler1[23:16];

always_ff @ (posedge Clock_50 or negedge Resetn) begin //Implement a general counter for keeping track of reading SRAM LOC
	if (Resetn == 1'b0) begin
		counter_pixel <= 6'd0;
		counter_row <= 5'd0;
		counter_column <= 6'd0;
		counter_pixel_write <= 5'd0;
		counter_row_write <= 5'd0;
		counter_column_write <= 6'd0;
	end
	else begin
	if(M2_STATE <= STATE_2_IDLE) begin
		counter_pixel <= 6'd0;
		counter_row <= 5'd0;
		counter_column <= 6'd0;
		counter_pixel_write <= 5'd0;
		counter_row_write <= 5'd0;
		counter_column_write <= 6'd0;	
	end
	
		//Offset values related to read
		if(increment_read) counter_pixel <= counter_pixel + 6'd1; //Pixel Counter in 8x8

		
		if(increment_read && counter_pixel == 6'd63) begin //Column counter of 8x8 blocks
			if( (iz_y && counter_column == 6'd39) || (~iz_y  && counter_column == 6'd19) ) counter_column <= 6'd0; //Reset for Y at 39 and for UV at 19
			else counter_column <= counter_column + 6'd1;
		end
	
		if(increment_read && counter_pixel == 6'd63 && ( (iz_y && counter_column == 6'd39) || (~iz_y  && counter_column == 6'd19) ) ) begin 
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

assign ultimate_offset = {9'd0,{counter_column,counter_pixel[2:0]}} + (iz_y ? 
					  ({2'd0,{counter_row,counter_pixel[5:3]},8'd0} + {4'd0,{counter_row,counter_pixel[5:3]},6'd0}) : ({3'd0,{counter_row,counter_pixel[5:3]},7'd0} + {5'd0,{counter_row,counter_pixel[5:3]},5'd0}) );
	//32 + 128 = 160

endmodule
