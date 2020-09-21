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
module fundamental_milestone (
		input logic Clock_50,
		input logic Resetn,
		input logic m1_enable,
		
		//SRAM Controller 
		input logic [17:0] SRAM_read_data,
		output logic [15:0] SRAM_write_data,
		output logic SRAM_we_n,
		output logic [17:0] SRAM_address,
		output logic m1_disable
		);
		
parameter OFFSET_U = 18'd38400,
		  OFFSET_V = 18'd57600,
		  OFFSET_RGB = 18'd146944;
		  
logic [17:0] counter_uv;
logic [17:0] counter_y;
logic [17:0] counter_rgb; 
logic [9:0] counter_pixel;
logic [9:0] counter_row;

logic signed [31:0] operator_0a, operator_0b, operator_1a, operator_1b, operator_2a, operator_2b;
logic signed [63:0] product_generator0, product_generator1, product_generator2;
logic signed [31:0] interpolating_sum_compiler;
logic signed [31:0] convertable_red_even_sum_compiler, convertable_green_even_sum_compiler, convertable_blue_even_sum_compiler;
logic signed [31:0] convertable_red_odd_sum_compiler, convertable_green_odd_sum_compiler, convertable_blue_odd_sum_compiler;

		  
//state_type state;
M1_STATE_type M1_STATE;

logic [15:0] YVAL_sram_data[1:0];
logic [15:0] UVAL_sram_data[3:0];
logic [15:0] VVAL_sram_data[3:0];
logic [39:0] Uprimez; //Bits [39:32] are for even U's (original), Bits [31:0] are odd U's (computed)
logic [39:0] Vprimez; //same


logic [63:0] RGB_even_terms[4:0];
logic [7:0] RGB_even_data[2:0];
logic [63:0] RGB_odd_terms[4:0];
logic [7:0] RGB_odd_data[2:0];


always_ff @ (posedge Clock_50 or negedge Resetn) begin
    if (Resetn == 1'b0) begin
        M1_STATE <= STATE_IDLE;
		counter_uv <= 18'd0;
		counter_y <= 18'd0;
		counter_rgb <= 18'd0;
		counter_pixel <= 10'd0;
		counter_row <= 10'd0;
		
		SRAM_address <= 18'd0;
		SRAM_we_n <= 1'b1;
		SRAM_write_data <= 16'd0;
		m1_disable <= 1'b0;
		
		YVAL_sram_data[1] <= 16'd0;
		YVAL_sram_data[0] <= 16'd0;	
		UVAL_sram_data[3] <= 16'd0;
		UVAL_sram_data[2] <= 16'd0;
		UVAL_sram_data[1] <= 16'd0;
		UVAL_sram_data[0] <= 16'd0;
		VVAL_sram_data[3] <= 16'd0;
		VVAL_sram_data[2] <= 16'd0;
		VVAL_sram_data[1] <= 16'd0;
		VVAL_sram_data[0] <= 16'd0;
		Uprimez <= 40'd0;
		Vprimez <= 40'd0;

		RGB_even_terms[4] <= 64'd0;
		RGB_even_terms[3] <= 64'd0;
		RGB_even_terms[2] <= 64'd0;
		RGB_even_terms[1] <= 64'd0;
		RGB_even_terms[0] <= 64'd0;
		
		RGB_odd_terms[4] <= 64'd0;
		RGB_odd_terms[3] <= 64'd0;
		RGB_odd_terms[2] <= 64'd0;
		RGB_odd_terms[1] <= 64'd0;
		RGB_odd_terms[0] <= 64'd0;
		

    end else begin
        case (M1_STATE)
			STATE_IDLE: begin
			counter_uv <= 18'd0;
			counter_y <= 18'd0;
			counter_rgb <= 18'd0;
			counter_pixel <= 10'd0;
			counter_row <= 10'd0;
		
			SRAM_address <= 18'd0;
			SRAM_we_n <= 1'b1;
			SRAM_write_data <= 16'd0;
			m1_disable <= 1'b0;
		
			YVAL_sram_data[1] <= 16'd0;
			YVAL_sram_data[0] <= 16'd0;	
			UVAL_sram_data[3] <= 16'd0;
			UVAL_sram_data[2] <= 16'd0;
			UVAL_sram_data[1] <= 16'd0;
			UVAL_sram_data[0] <= 16'd0;
			VVAL_sram_data[3] <= 16'd0;
			VVAL_sram_data[2] <= 16'd0;
			VVAL_sram_data[1] <= 16'd0;
			VVAL_sram_data[0] <= 16'd0;
			Uprimez <= 40'd0;
			Vprimez <= 40'd0;

			RGB_even_terms[4] <= 64'd0;
			RGB_even_terms[3] <= 64'd0;
			RGB_even_terms[2] <= 64'd0;
			RGB_even_terms[1] <= 64'd0;
			RGB_even_terms[0] <= 64'd0;
		
			
			RGB_odd_terms[4] <= 64'd0;
			RGB_odd_terms[3] <= 64'd0;
			RGB_odd_terms[2] <= 64'd0;
			RGB_odd_terms[1] <= 64'd0;
			RGB_odd_terms[0] <= 64'd0;
		

               if (m1_enable == 1'b1) begin
					M1_STATE  <= STATE_00;
					m1_disable <= 1'b0;
					counter_row <= 10'd0;
				end //Begin festivities
			end
			
            STATE_00: begin
				SRAM_we_n <= 1'b1; //Initialize reading
				
				//Call for read values u0u1
                SRAM_address <= OFFSET_U + counter_uv; //Location 0 of U
				counter_pixel <= 10'd0;
				
                M1_STATE <= STATE_01; 
            end
			
            STATE_01: begin
				//Call for read values u2u3
                SRAM_address <= OFFSET_U + counter_uv +  18'd1 ; //Location 1 of U

				M1_STATE <= STATE_02; 
            end
			
            STATE_02: begin
				//Call for read values v0v1
                SRAM_address <= OFFSET_V + counter_uv; //Location 0 of V
				counter_uv <= counter_uv + 18'd1; //increment uv to value 1
				
				M1_STATE <= STATE_03; 
            end
			
            STATE_03: begin
				//Call for read values v2v3
                SRAM_address <= OFFSET_V + counter_uv; //Location 1 of V
				counter_uv <= counter_uv + 18'd1; //increment uv to value 2
				
				//SRAM_read_data holds u0u1 
				UVAL_sram_data[3] <= {SRAM_read_data[15:8], SRAM_read_data[15:8]}; //Fills slot with u0u0
				UVAL_sram_data[2] <= SRAM_read_data; //Fills slot with u0u1
				Uprimez[39:32] <= SRAM_read_data[15:8]; //First half of Uprimez stores u0 as u'0
				
				M1_STATE <= STATE_04;
            end
			
            STATE_04: begin
				//Call for read values y0y1
                SRAM_address <= counter_y; //Location 0 of Y
				counter_y <= counter_y + 18'd1; //increment count_y to value 1
				
				//SRAM_read_data holds u2u3
				UVAL_sram_data[1] <= SRAM_read_data; //Fills slot with u2u3
				
				//MULTIPLICATION BEGINS HERE FOR U'1 (STATE 4)
				//STORE RESULT FOR U'1 IN Uprimez
				Uprimez[31:0] <= interpolating_sum_compiler[31:0] >>> 8; 
				
				M1_STATE <= STATE_05;
            end
			
            STATE_05: begin
				//Call for read values u4u5
                SRAM_address <= OFFSET_U + counter_uv; //Location 2 of U
				
				//SRAM_read_data holds v0v1
				VVAL_sram_data[3] <= {SRAM_read_data[15:8], SRAM_read_data[15:8]}; //Fills slot with v0v0
				VVAL_sram_data[2] <= SRAM_read_data; //Fills slot with v0v1
				Vprimez[39:32] <= SRAM_read_data[15:8]; //First half of Vprimez stores v0 as v'0
				
				
				M1_STATE <= STATE_06;
            end
			
            STATE_06: begin
				//Call for read values v4v5
                SRAM_address <= OFFSET_V + counter_uv; //Location 2 of V
				counter_uv <= counter_uv + 18'd1; //increment counter_uv to value 3
				
				//SRAM_read_data holds v2v3
				VVAL_sram_data[1] <= SRAM_read_data; //Fills slot with v2v3
				
				//MULTIPLICATION BEGINS HERE FOR V'1 (M1_STATE 6)
				//STORE RESULT FOR V'1 IN Vprimez
				Vprimez[31:0] <= interpolating_sum_compiler[31:0] >>> 8; 
				
				M1_STATE <= STATE_07;
				
            end
			
            STATE_07: begin
				//No read in this state
				
				//SRAM_read_data holds y0y1
				YVAL_sram_data[0] <= SRAM_read_data; //Fills slot with y0y1
				
				//MULTIPLICATION OCCURS HERE FOR RGB EVENS (Results 0-2) (STATE 7)
				//STORE RESULT FOR RGB E's IN RGB_even_terms
				RGB_even_terms[0] <= product_generator0;
				RGB_even_terms[1] <= product_generator1;
				RGB_even_terms[2] <= product_generator2;				
				
				
				M1_STATE <= STATE_08;
            end
			
            STATE_08: begin
				//Call for read values y2y3
                SRAM_address <= counter_y; //Location 1 of Y
				counter_y <= counter_y + 18'd1; //increment counter_y to value 2

				//SRAM_read_data holds u4u5
				UVAL_sram_data[0] <= SRAM_read_data; //Fills slot with u4u5

				//MULTIPLICATION OCCURS HERE FOR RGB EVENS (Results 3-4) (STATE 8)
				//STORE RESULT FOR RGB E's IN RGB_even_terms
				RGB_even_terms[3] <= product_generator0;
				RGB_even_terms[4] <= product_generator1;
				
				M1_STATE <= STATE_09;
            end
            STATE_09: begin
				
				//SRAM_read_data holds v4v5
				VVAL_sram_data[0] <= SRAM_read_data; //Fills slot with v4v5							
				
				//MULTIPLICATION OCCURS HERE FOR RGB ODDS (Results 0-2) (M1_STATE 9)
				//STORE RESULT FOR RGB O's IN RGB_odd_terms
				RGB_odd_terms[0] <= product_generator0;
				RGB_odd_terms[1] <= product_generator1;
				RGB_odd_terms[2] <= product_generator2;	

				//RGB0 now prepared in RGB_even_data[2:0] (live combinational values)

				M1_STATE <= STATE_10;

            end
            STATE_10: begin
				
				//MULTIPLICATION OCCURS HERE FOR RGB ODDS (Results 3-4) (STATE 10)
				//STORE RESULT FOR RGB O's IN RGB_even_terms
				RGB_odd_terms[3] <= product_generator0;
				RGB_odd_terms[4] <= product_generator1;

				M1_STATE <= STATE_11;
            end
			
            STATE_11: begin //COMMON BLOCK BEGINS

				//SRAM_read_data holds y2y3
				YVAL_sram_data[1] <= YVAL_sram_data[0]; //Shift register previous y values	
				YVAL_sram_data[0] <= SRAM_read_data; //Fills slot with y2y3	

				//Call for Writing of R0G0
				SRAM_we_n <= 1'b0; //Initialize Writing
                SRAM_address <= OFFSET_RGB + counter_rgb; //Location 0 of RGB
				counter_rgb <= counter_rgb + 18'd1; //increment counter_rgb to value 1
				SRAM_write_data <= {RGB_even_data[0],RGB_even_data[1]};	
				counter_pixel <= counter_pixel+ 10'd1; //1
				
				//MULTIPLICATION SHOULD BEGIN HERE FOR U'3 (STATE 11)
				//STORE RESULT FOR U'3 IN Uprimez
				Uprimez <= {UVAL_sram_data[2][7:0], (interpolating_sum_compiler[31:0] >>> 8)}; //Stores u1 as u'2 and calculated u'3 into Uprimez
				
				//RGB1 now prepared in RGB_odd_data[2:0] (live combinational values)

				M1_STATE <= STATE_12;
            end
			
            STATE_12: begin
				//Call for Writing of B0R1
                SRAM_address <= OFFSET_RGB + counter_rgb; //Location 1 of RGB
				counter_rgb <= counter_rgb + 18'd1; //increment counter_rgb to value 2
				SRAM_write_data <= {RGB_even_data[2],RGB_odd_data[0]};						
	
				//MULTIPLICATION SHOULD BEGIN HERE FOR V'3 (STATE 12)
				//STORE RESULT FOR V'3 IN Vprimez
				Vprimez <= {VVAL_sram_data[2][7:0], (interpolating_sum_compiler[31:0] >>> 8)}; //Stores v1 as v'2 and calculated v'3 into Vprimez

				M1_STATE <= STATE_13;
            end
			
            STATE_13: begin
				//Call for Writing of G1B1
				//SRAM_we_n <= 1'b1; //Initialize Reading for next clock cycle

                SRAM_address <= OFFSET_RGB + counter_rgb; //Location 2 of RGB
				counter_rgb <= counter_rgb + 18'd1; //increment counter_rgb to value 3
				SRAM_write_data <= {RGB_odd_data[1],RGB_odd_data[2]};	

				counter_pixel <= counter_pixel+ 10'd1;	//2			
						
			
				//MULTIPLICATION OCCURS HERE FOR RGB EVENS (Results 0-2) (STATE 13)
				//STORE RESULT FOR RGB E's IN RGB_even_terms
				RGB_even_terms[0] <= product_generator0;
				RGB_even_terms[1] <= product_generator1;
				RGB_even_terms[2] <= product_generator2;					
				M1_STATE <= STATE_14;
            end
			
            STATE_14: begin
				
				SRAM_we_n <= 1'b1; //Initialize Reading
				//Call reading for y4y5 and onwards
				SRAM_address <= counter_y; //Location 2 of Y
				if ( counter_pixel < 10'd316) counter_y <= counter_y + 18'd1; //increment counter_y to value 3				

				//MULTIPLICATION OCCURS HERE FOR RGB EVENS (Results 3-4) (STATE 14)
				//STORE RESULT FOR RGB E's IN RGB_even_terms
				RGB_even_terms[3] <= product_generator0;
				RGB_even_terms[4] <= product_generator1;
				
				M1_STATE <= STATE_15;
            end
			
            STATE_15: begin
				//Call for read values u6u7
                SRAM_address <= OFFSET_U + counter_uv; //Location 3 of U						
				
				//MULTIPLICATION OCCURS HERE FOR RGB ODDS (Results 0-2) (STATE 15)
				//STORE RESULT FOR RGB O's IN RGB_odd_terms
				RGB_odd_terms[0] <= product_generator0;
				RGB_odd_terms[1] <= product_generator1;
				RGB_odd_terms[2] <= product_generator2;		

				//RGB2 now prepared in RGB_even_data[2:0] (live combinational values)

				M1_STATE <= STATE_16;
            end
			
            STATE_16: begin
				//Call for read values v6v7
                SRAM_address <= OFFSET_V + counter_uv; //Location 3 of V
				
				if(counter_pixel < 10'd308) counter_uv <= counter_uv + 18'd1; //increment counter_uv to value 4

				//MULTIPLICATION OCCURS HERE FOR RGB ODDS (Results 3-4) (STATE 16)
				//STORE RESULT FOR RGB O's IN RGB_even_terms
				RGB_odd_terms[3] <= product_generator0;
				RGB_odd_terms[4] <= product_generator1;

				M1_STATE <= STATE_17;
            end
            STATE_17: begin
				//SRAM_read_data holds y4y5
				if (counter_pixel >= 10'd318) begin
					YVAL_sram_data[1] <= YVAL_sram_data[0]; //Shift register
				end
				else begin
					YVAL_sram_data[1] <= YVAL_sram_data[0]; //Shift register
					YVAL_sram_data[0] <= SRAM_read_data; //Fills slot with y4y5
				end
				//Call for Writing of R2G2
				SRAM_we_n <= 1'b0; //Initialize Writing
                SRAM_address <= OFFSET_RGB + counter_rgb; //Location 3 of RGB
				counter_rgb <= counter_rgb + 18'd1; //increment counter_rgb to value 4
				SRAM_write_data <= {RGB_even_data[0],RGB_even_data[1]};
				
				counter_pixel <= counter_pixel+ 10'd1;
				
				//MULTIPLICATION SHOULD BEGIN HERE FOR U'5 (STATE 17)
				//STORE RESULT FOR U'5 IN Uprimez
				Uprimez <= {UVAL_sram_data[1][15:8], (interpolating_sum_compiler[31:0] >>> 8)}; //Stores u2 as u'4 and calculated u'5 into Uprimez
				//RGB3 now prepared in RGB_odd_data[2:0] (live combinational values)

				M1_STATE <= STATE_18;
			end
				
            STATE_18: begin
				if (counter_pixel >= 10'd308) begin
					UVAL_sram_data[3] <= UVAL_sram_data[2]; //Shift register
					UVAL_sram_data[2] <= UVAL_sram_data[1];
					UVAL_sram_data[1] <= UVAL_sram_data[0];
					UVAL_sram_data[0] <= {UVAL_sram_data[0][7:0],UVAL_sram_data[0][7:0]};					
				end else begin 
					//SRAM_read_data holds u6u7
					UVAL_sram_data[3] <= UVAL_sram_data[2]; //Shift register
					UVAL_sram_data[2] <= UVAL_sram_data[1];
					UVAL_sram_data[1] <= UVAL_sram_data[0];
					UVAL_sram_data[0] <= SRAM_read_data; //Fills slot with u6u7	
				end 

				//Call for Writing of B2R3
                SRAM_address <= OFFSET_RGB + counter_rgb; //Location 4 of RGB 
				counter_rgb <= counter_rgb + 18'd1; //increment counter_rgb to value 5 
				SRAM_write_data <= {RGB_even_data[2],RGB_odd_data[0]};
			
				//MULTIPLICATION SHOULD BEGIN HERE FOR V'5 (STATE 18)
				//STORE RESULT FOR V'5 IN Vprimez
				Vprimez <= {VVAL_sram_data[1][15:8], (interpolating_sum_compiler[31:0]>>> 8)}; //Stores v2 as v'4 and calculated v'5 into Vprimez

				M1_STATE <= STATE_19;
            end
            STATE_19: begin
				if (counter_pixel >= 10'd308) begin
					VVAL_sram_data[3] <= VVAL_sram_data[2]; //Shift register
					VVAL_sram_data[2] <= VVAL_sram_data[1];
					VVAL_sram_data[1] <= VVAL_sram_data[0];
					VVAL_sram_data[0] <= {VVAL_sram_data[0][7:0],VVAL_sram_data[0][7:0]};	
				end else begin 
					//SRAM_read_data holds v6v7
					VVAL_sram_data[3] <= VVAL_sram_data[2];
					VVAL_sram_data[2] <= VVAL_sram_data[1];
					VVAL_sram_data[1] <= VVAL_sram_data[0];
					VVAL_sram_data[0] <= SRAM_read_data; //Fills slot with v6v7	
				end 
				//SRAM_we_n <= 1'b1; //Initialize Read for next clock cycle

				//Call for Writing of G3B3
                SRAM_address <= OFFSET_RGB + counter_rgb; //Location 5 of RGB
				counter_rgb <= counter_rgb + 18'd1; //increment counter_rgb to value 6 				
				SRAM_write_data <= {RGB_odd_data[1],RGB_odd_data[2]};
				
				counter_pixel <= counter_pixel+ 10'd1;
				
				//MULTIPLICATION OCCURS HERE FOR RGB EVENS (Results 0-2) (STATE 1)
				//STORE RESULT FOR RGB E's IN RGB_even_terms	
				RGB_even_terms[0] <= product_generator0;
				RGB_even_terms[1] <= product_generator1;
				RGB_even_terms[2] <= product_generator2;
				
				M1_STATE <= STATE_20;
            end
			
			STATE_20: begin
			
				SRAM_we_n <= 1'b1; //Initialize Read                
				SRAM_address <= counter_y; //Location 3 of Y
				if ( counter_pixel < 10'd318) counter_y <= counter_y + 18'd1; //increment counter_y to value 4				

				//MULTIPLICATION OCCURS HERE FOR RGB EVENS (Results 3-4) (STATE 14)
				//STORE RESULT FOR RGB E's IN RGB_even_terms
				RGB_even_terms[3] <= product_generator0;
				RGB_even_terms[4] <= product_generator1;
				
				M1_STATE <= STATE_21;
            end
			
            STATE_21: begin
				
				//MULTIPLICATION OCCURS HERE FOR RGB ODDS (Results 0-2) (STATE 21)
				//STORE RESULT FOR RGB O's IN RGB_odd_terms
				RGB_odd_terms[0] <= product_generator0;
				RGB_odd_terms[1] <= product_generator1;
				RGB_odd_terms[2] <= product_generator2;		

				//RGB4 now prepared in RGB_even_data[2:0] (live combinational values)

				M1_STATE <= STATE_22;
            end
			
            STATE_22: begin
			
				//MULTIPLICATION OCCURS HERE FOR RGB ODDS (Results 3-4) (STATE 10)
				//STORE RESULT FOR RGB O's IN RGB_even_terms
				RGB_odd_terms[3] <= product_generator0;
				RGB_odd_terms[4] <= product_generator1;

				//FEED R2G2 to SRAM_write_data for NEXT clock cycle
				//SRAM_write_data <= RGB_even_data[2:1];
				if(counter_pixel == 10'd320) begin
					if(counter_row == 10'd239)  begin
						m1_disable <= 1'b1;
						M1_STATE <= STATE_IDLE;					
					end
					else begin
						M1_STATE <= STATE_00;
						counter_row <=  counter_row + 10'd1;
					end
				end 
				else M1_STATE <= STATE_11; //Row not yet completed
			end
			default: M1_STATE <= STATE_IDLE;
			endcase
		end
	end
	
always_comb begin
	if	(M1_STATE == STATE_14 || M1_STATE == STATE_20 || M1_STATE == STATE_16 || M1_STATE == STATE_22) begin //Last 2 values of YUV to RGB conversion
		operator_0a = 32'd104595;
		operator_1a = 32'd53281;
		operator_2a = 32'd0; //Feed third multiplier zeros for days
		operator_2b = 32'd0;	
		if(M1_STATE == STATE_14 || M1_STATE == STATE_20) begin //Even conversion block, same exact inputs
			operator_0b = {24'd0,Vprimez[39:32]} - 32'd128; //V'2 - 128
			operator_1b = {24'd0,Vprimez[39:32]} - 32'd128; //V'2 - 128
		end else begin		
			operator_0b = Vprimez[31:0] - 32'd128; //V'1 - 128
			operator_1b = Vprimez[31:0] - 32'd128; //V'1 - 128
		end
	
	end else begin	
		if (M1_STATE == STATE_13 || M1_STATE == STATE_19 || M1_STATE == STATE_15 || M1_STATE == STATE_21) begin //First 3 values of YUV to RGB conversion
			operator_0a = 32'd76284;
			operator_1a = 32'd25624;
			operator_2a = 32'd132251;	
			if(M1_STATE == STATE_13 || M1_STATE == STATE_19) begin //Even conversion block, same exact inputs
				operator_0b =  {24'd0,YVAL_sram_data[0][15:8]} - 32'd16  ; //Y'2 and onwards - 16
				operator_1b =  {24'd0,Uprimez[39:32]} - 32'd128; //U'2 and onwards - 128
				operator_2b =  {24'd0,Uprimez[39:32]} - 32'd128; //U'2 and onwards - 128
			end else begin //Odd computation block
				operator_0b =  {24'd0,YVAL_sram_data[0][7:0]} - 32'd16  ; //Y'3 and onwards - 16
				operator_1b =  Uprimez[31:0] - 32'd128; //U'3 and onwards - 128
				operator_2b =  Uprimez[31:0] - 32'd128; //U'3 and onwards - 128		
			end
		end 
		else begin
			if (M1_STATE == STATE_11 || M1_STATE == STATE_17 || M1_STATE == STATE_12 || M1_STATE == STATE_18) begin //Computation of U and V values within common block
				operator_0a = 32'd21;
				operator_1a = 32'd52;
				operator_2a = 32'd159;
				if(M1_STATE == STATE_11 || M1_STATE == STATE_17) begin //Computation of U values within common block
				operator_0b = M1_STATE == STATE_11 ? {24'd0,UVAL_sram_data[3][7:0]}  + {24'd0,UVAL_sram_data[0][15:8]} : {24'd0,UVAL_sram_data[2][15:8]} + {24'd0,UVAL_sram_data[0][7:0]};
				operator_1b = M1_STATE == STATE_11 ? {24'd0,UVAL_sram_data[2][15:8]} + {24'd0,UVAL_sram_data[1][7:0]}  : {24'd0,UVAL_sram_data[2][7:0]}  + {24'd0,UVAL_sram_data[0][15:8]};
				operator_2b = M1_STATE == STATE_11 ? {24'd0,UVAL_sram_data[2][7:0]}  + {24'd0,UVAL_sram_data[1][15:8]} : {24'd0,UVAL_sram_data[1][15:8]} + {24'd0,UVAL_sram_data[1][7:0]};
				end else begin //Computation of V values within common block
				operator_0b = M1_STATE == STATE_12 ? {24'd0,VVAL_sram_data[3][7:0]}  + {24'd0,VVAL_sram_data[0][15:8]} : {24'd0,VVAL_sram_data[2][15:8]} + {24'd0,VVAL_sram_data[0][7:0]};
				operator_1b = M1_STATE == STATE_12 ? {24'd0,VVAL_sram_data[2][15:8]} + {24'd0,VVAL_sram_data[1][7:0]}  : {24'd0,VVAL_sram_data[2][7:0]}  + {24'd0,VVAL_sram_data[0][15:8]};
				operator_2b = M1_STATE == STATE_12 ? {24'd0,VVAL_sram_data[2][7:0]}  + {24'd0,VVAL_sram_data[1][15:8]} : {24'd0,VVAL_sram_data[1][15:8]} + {24'd0,VVAL_sram_data[1][7:0]};		
				end
			end
			else begin
				if(M1_STATE == STATE_10) begin //For last 2 ODD0 ONLY
					operator_0a = Vprimez[31:0] - 32'd128; //V'1 - 128
					operator_0b = 32'd104595;
					operator_1a = Vprimez[31:0] - 32'd128; //V'1 - 128
					operator_1b = 32'd53281;
					operator_2a = 32'd0; //Feed third multiplier zeros for days
					operator_2b = 32'd0;			
				end else begin
					if(M1_STATE == STATE_09) begin //For First 3  ODD0 ONLY
						operator_0a = {24'd0,YVAL_sram_data[0][7:0]} - 32'd16; //Y'1 - 16
						operator_0b = 32'd76284;
						operator_1a = Uprimez[31:0] - 32'd128; //U'1 - 128
						operator_1b = 32'd25624;
						operator_2a = Uprimez[31:0] - 32'd128; //V'1 - 128
						operator_2b = 32'd132251;	
					end
					else begin
						if (M1_STATE == STATE_08) begin //For last 2 EVEN0 ONLY
							operator_0a = {24'd0,Vprimez[39:32]} - 32'd128; //V'0 - 128
							operator_0b = 32'd104595;
							operator_1a = {24'd0,Vprimez[39:32]} - 32'd128; //V'0 - 128
							operator_1b = 32'd53281;
							operator_2a = 32'd0; //Feed third multiplier zeros for days
							operator_2b = 32'd0;
						end
						else begin
							if (M1_STATE == STATE_07) begin //For first 3 EVEN0 ONLY
								operator_0a = {24'd0,SRAM_read_data[15:8]} - 32'd16; //Y'0 - 16
								operator_0b = 32'd76284;
								operator_1a = {24'd0,Uprimez[39:32]} - 32'd128; //U'0 - 128
								operator_1b = 32'd25624;
								operator_2a = {24'd0,Uprimez[39:32]} - 32'd128; //U'0 - 128
								operator_2b = 32'd132251;
							end
							else begin 
								if (M1_STATE == STATE_06) begin //For V'1 multiplication ONLY
									operator_0a = 32'd21;
									operator_1a = 32'd52;
									operator_2a = 32'd159;
									operator_0b = {24'd0,SRAM_read_data[7:0]} + {24'd0,VVAL_sram_data[3][7:0]};
									operator_1b = {24'd0,SRAM_read_data[15:8]} + {24'd0,VVAL_sram_data[3][7:0]};
									operator_2b = {24'd0,VVAL_sram_data[3][7:0]} + {24'd0,VVAL_sram_data[2][7:0]};		
								end else begin
									if (M1_STATE == STATE_04) begin //For U'1 multiplication ONLY
										operator_0a = 32'd21;
										operator_1a = 32'd52;
										operator_2a = 32'd159;
										operator_0b = {24'd0,SRAM_read_data[7:0]} + {24'd0,UVAL_sram_data[3][7:0]};
										operator_1b = {24'd0,SRAM_read_data[15:8]} + {24'd0,UVAL_sram_data[3][7:0]};
										operator_2b = {24'd0,UVAL_sram_data[3][7:0]} + {24'd0,UVAL_sram_data[2][7:0]};
									end
									else begin
										operator_0a = 32'd0;
										operator_1a = 32'd0;
										operator_2a = 32'd0;
										operator_0b = 32'd0;
										operator_1b = 32'd0;
										operator_2b = 32'd0;						
									end
								end
							end
						end
					end	
						
				end
			end
		end
	end
	
end
	
assign product_generator0 = operator_0a * operator_0b;
assign product_generator1 = operator_1a * operator_1b;
assign product_generator2 = operator_2a * operator_2b;

assign interpolating_sum_compiler = 32'd128 + product_generator0[31:0] - product_generator1[31:0] + product_generator2[31:0];
//compilers generate 64 bit results from R G B compilation
assign convertable_red_even_sum_compiler = RGB_even_terms[0] + RGB_even_terms[3]; //RGB_odd_terms[0] + RGB_odd_terms[3]; //Handles ALL even pixel conversion for red
assign convertable_green_even_sum_compiler = RGB_even_terms[0] - RGB_even_terms[1] - RGB_even_terms[4]; //RGB_odd_terms[0] + RGB_odd_terms[1] - RGB_odd_terms[4];
assign convertable_blue_even_sum_compiler = RGB_even_terms[0] + RGB_even_terms[2]; //: RGB_odd_terms[0] + RGB_odd_terms[3];

assign convertable_red_odd_sum_compiler = RGB_odd_terms[0] + RGB_odd_terms[3];
assign convertable_green_odd_sum_compiler = RGB_odd_terms[0] - RGB_odd_terms[1] - RGB_odd_terms[4];
assign convertable_blue_odd_sum_compiler = RGB_odd_terms[0] + RGB_odd_terms[2];

//Reduction to 8 bits of R G B values

assign RGB_even_data[0] = convertable_red_even_sum_compiler[31] == 1'b1 ? 8'd0 : |convertable_red_even_sum_compiler[30:24] ? 8'd255 : convertable_red_even_sum_compiler[23:16]; //8 bit R
assign RGB_even_data[1] = convertable_green_even_sum_compiler[31] == 1'b1 ? 8'd0 : |convertable_green_even_sum_compiler[30:24] ? 8'd255 : convertable_green_even_sum_compiler[23:16]; //8 bit G
assign RGB_even_data[2] = convertable_blue_even_sum_compiler[31] == 1'b1 ? 8'd0 : |convertable_blue_even_sum_compiler[30:24] ? 8'd255 : convertable_blue_even_sum_compiler[23:16]; //8 bit B

assign RGB_odd_data[0] = convertable_red_odd_sum_compiler[31] == 1'b1 ? 8'd0 : |convertable_red_odd_sum_compiler[30:24] ? 8'd255 : convertable_red_odd_sum_compiler[23:16]; //8 bit R
assign RGB_odd_data[1] = convertable_green_odd_sum_compiler[31] == 1'b1 ? 8'd0 : |convertable_green_odd_sum_compiler[30:24] ? 8'd255 : convertable_green_odd_sum_compiler[23:16]; //8 bit G
assign RGB_odd_data[2] = convertable_blue_odd_sum_compiler[31] == 1'b1 ? 8'd0 : |convertable_blue_odd_sum_compiler[30:24] ? 8'd255 : convertable_blue_odd_sum_compiler[23:16]; //8 bit B

endmodule