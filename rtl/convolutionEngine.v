//convTop=================================================================================================

module convTop (clk, rst_n, pixelIn, macOut, pixel_valid, valid);

	parameter PIXEL_WIDTH = 8;
	parameter KERNEL_SIZE = 3;
	parameter WEIGHT_WIDTH = 8;
	parameter MAC_WIDTH = PIXEL_WIDTH + WEIGHT_WIDTH + $clog2(KERNEL_SIZE * KERNEL_SIZE);

	input clk;
	input rst_n;
	input wire [PIXEL_WIDTH - 1:0] pixelIn;
	input wire pixel_valid;
	output wire signed [MAC_WIDTH - 1:0] macOut;
		output wire valid;

	
	wire [PIXEL_WIDTH - 1:0] pixelOut0;
	wire [PIXEL_WIDTH - 1:0] pixelOut1;
	wire [KERNEL_SIZE * KERNEL_SIZE * PIXEL_WIDTH - 1:0] windowOut;
	
	lineBuffer lb1 (pixelIn, clk, pixelOut1, pixel_valid, rst_n);
	lineBuffer lb0 (pixelOut1, clk, pixelOut0, pixel_valid, rst_n);
	windowReg r1 (pixelIn, pixelOut1, pixelOut0, clk, windowOut, pixel_valid, rst_n);
	mac m1 (windowOut, macOut);
	validity v1 (clk, valid, pixel_valid, rst_n);
	
endmodule	
//Line buffer=============================================================================================
module lineBuffer (pixelIn, clk, pixelOut, pixel_valid, rst_n);

	//declarations 
	parameter IMAGE_SIZE = 5;
	parameter PIXEL_WIDTH = 8;
	input wire [PIXEL_WIDTH - 1:0] pixelIn;
	input wire clk;
	input wire pixel_valid;
	input wire rst_n;
	output wire [PIXEL_WIDTH - 1:0] pixelOut;

	
	reg [PIXEL_WIDTH - 1:0] shiftReg [0:IMAGE_SIZE - 1];
	integer i;
	
	//shift reg 
	
	always @(posedge clk)
		begin
			if (!rst_n)
				begin
					for (i = 0; i < IMAGE_SIZE; i = i + 1)
						shiftReg[i] <= 0;					
				end
			else 
				begin
					if (pixel_valid)
						begin
							shiftReg[0] <= pixelIn;
							for (i = 1; i < IMAGE_SIZE; i = i+ 1)
								shiftReg[i] <= shiftReg[i - 1];
						end				
				end
		end
	
	assign pixelOut = shiftReg[IMAGE_SIZE - 1];
endmodule
	
//windowRegister==========================================================================================
module windowReg(pixelOutLive, pixelOut1, pixelOut0, clk, windowOut, pixel_valid, rst_n);
		
		//declarations
		parameter PIXEL_WIDTH = 8;
		parameter KERNEL_SIZE = 3;
		
		input wire [PIXEL_WIDTH - 1:0] pixelOutLive, pixelOut1, pixelOut0;
		input wire clk;
		input wire pixel_valid;
		input wire rst_n;
		output wire [KERNEL_SIZE * KERNEL_SIZE * PIXEL_WIDTH - 1:0] windowOut;
		
		reg [PIXEL_WIDTH - 1:0] window [0:KERNEL_SIZE - 1][0:KERNEL_SIZE - 1];
		integer i;
		integer j;
		
		always @(posedge clk)
			begin
				if (!rst_n)
					begin
						for (i = 0; i < KERNEL_SIZE; i = i + 1)
						begin
							for (j = 0; j < KERNEL_SIZE; j = j + 1)
								window [j][i] <= 0;
						end
					end
				else
					begin
						if (pixel_valid)
							begin
								window[0][0] <= pixelOut0;
								window[1][0] <= pixelOut1;
								window[2][0] <= pixelOutLive;
									for (i = 1; i < KERNEL_SIZE; i = i + 1)
										begin
											for (j = 0; j < KERNEL_SIZE; j  = j + 1)
												begin
													window[j][i] <= window[j][i - 1];
												end 
										end
							end					
					end
			end 
			
			assign windowOut = {window[2][2], window[2][1], window[2][0], 
									  window[1][2], window[1][1], window[1][0], 
									  window[0][2], window[0][1], window[0][0]};		
									  
endmodule
//MAC=====================================================================================================

module mac (windowOut, macOut);
	
	//declarations
	parameter KERNEL_SIZE = 3;
	parameter PIXEL_WIDTH = 8;
	parameter WEIGHT_WIDTH = 8;
	parameter MAC_WIDTH = PIXEL_WIDTH + WEIGHT_WIDTH + $clog2(KERNEL_SIZE * KERNEL_SIZE);

	
	input wire[KERNEL_SIZE * KERNEL_SIZE * PIXEL_WIDTH - 1:0] windowOut;
	output wire signed [MAC_WIDTH - 1:0] macOut;
	reg signed [WEIGHT_WIDTH - 1:0] kernel[0:KERNEL_SIZE * KERNEL_SIZE - 1];
	reg signed [WEIGHT_WIDTH - 1:0] kernelTemp[0:KERNEL_SIZE * KERNEL_SIZE - 1];

	
	initial
		begin
			kernelTemp[0] = 5;
			kernelTemp[1] = 6;
			kernelTemp[2] = 8;
			kernelTemp[3] = 3;
			kernelTemp[4] = 4;
			kernelTemp[5] = 1;
			kernelTemp[6] = 9;
			kernelTemp[7] = 1;
			kernelTemp[8] = 12;
			
			kernel[0] = kernelTemp[2];
			kernel[1] = kernelTemp[1];
			kernel[2] = kernelTemp[0];
			kernel[3] = kernelTemp[5];
			kernel[4] = kernelTemp[4];
			kernel[5] = kernelTemp[3];
			kernel[6] = kernelTemp[8];
			kernel[7] = kernelTemp[7];
			kernel[8] = kernelTemp[6];
		end
	
	integer i;
	reg signed[MAC_WIDTH - 1:0] sum;
	always @(*)
		begin
		sum = 0;
			for (i = 0; i < KERNEL_SIZE * KERNEL_SIZE; i = i + 1)
				sum = sum + $signed({1'b0, windowOut[i*PIXEL_WIDTH +: PIXEL_WIDTH]}) * kernel[i];
		end
		
	assign macOut = sum;
	
endmodule	
//FSM=====================================================================================================

module validity (clk, valid, pixel_valid, rst_n);

	parameter IMAGE_SIZE = 5;
	parameter COUNT_SIZE = $clog2(IMAGE_SIZE * IMAGE_SIZE);
	parameter COL_SIZE = $clog2(IMAGE_SIZE);
	parameter KERNEL_SIZE = 3;
	
	input wire clk;
	input wire pixel_valid;
	input wire rst_n;
	output reg valid;
	
	reg [COUNT_SIZE - 1:0] counter;
	wire [COL_SIZE - 1:0] column;
	wire [COL_SIZE -1:0] row;
	wire isValid;

	
	initial
		begin
			counter = 0;
			valid = 0;
		end
		
	assign column = counter % IMAGE_SIZE;
	assign row = counter  / IMAGE_SIZE;	
	assign isValid = (column >= KERNEL_SIZE - 1) && (row >= KERNEL_SIZE - 1);
	
	always @(posedge clk)
		begin
			if (!rst_n)
				begin
					counter <= 0;
					valid <= 0;
				end
			else
				begin
					if (pixel_valid)
						begin					
							if (counter == IMAGE_SIZE * IMAGE_SIZE - 1)
								counter <= 0;
								
							else
								counter <= counter + 1;
						end
						valid <= isValid;
				end
		end 		
endmodule

//=========================================================================================================
		
	

	
	
		
	