`timescale 1ns/1ps


module convTop_tb();

	//parameters
	parameter DELAY = 5;
	parameter PIXEL_WIDTH = 8;
	parameter KERNEL_SIZE = 3;
	parameter WEIGHT_WIDTH = 8;
	parameter MAC_WIDTH = PIXEL_WIDTH + WEIGHT_WIDTH + $clog2(KERNEL_SIZE * KERNEL_SIZE);
	parameter IMAGE_SIZE = 5;
	parameter NUM_IN = IMAGE_SIZE * IMAGE_SIZE;
	parameter NUM_OUT = (IMAGE_SIZE - KERNEL_SIZE + 1)**2;
	parameter WATCHDOG_TIME = 2000;
	
	//signal declarations
	logic [PIXEL_WIDTH - 1:0] pixelIn;
	logic pixel_valid;
	logic rst_n;
	logic signed [MAC_WIDTH - 1:0] macOut;
	logic valid;

	//storage arrays
	logic [PIXEL_WIDTH - 1:0] imageArray [NUM_IN];
	logic signed [MAC_WIDTH - 1:0] goldenArray [NUM_OUT];
	
	//Clock generator
	logic clk = 1'b0;
	always #DELAY clk = ~clk;
	
	//DUT instantiation
	convTop DUT (.clk(clk), .rst_n(rst_n), .pixelIn(pixelIn),.macOut(macOut), .pixel_valid(pixel_valid),
	.valid(valid));
	
	//Activity region
	
	
	//stimulus sequence 
	initial
		begin
			$readmemh("image.hex", imageArray);
			$readmemh("golden.hex", goldenArray);
			
			pixelIn <= 0;
			pixel_valid <= 0;
			rst_n <= 0;
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
			rst_n <= 1;
			@(posedge clk);
			
			pixel_valid <= 1;
			for (int i = 0; i < NUM_IN; i++)
				begin
					pixelIn <= imageArray[i];
					@(posedge clk);
				end
			pixel_valid <= 0;
		end
	
	//capture + scoreboard 
	int outIdx = 0;
	int error = 0;
	
	always_ff @(posedge clk)
		begin
			if(valid)
				begin
					if (macOut !== goldenArray[outIdx])
						begin
							error++;
							$error("[%0t] output %0d: expected: %0d,  got: %0d", $time, outIdx, goldenArray[outIdx], macOut);
						end
						outIdx++;
				end
		end 

	//termination and summary 
	initial
		begin
			wait(outIdx == NUM_OUT);
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
			
			assert (outIdx == NUM_OUT)
				else $error("captured %0d output, expected %0d", outIdx, NUM_OUT);
				
			if (error == 0)
				$display("[%0t] TEST PASSED: %0d/%0d outputs matched", $time, outIdx, NUM_OUT);
			else 
				$display("[%0t] TEST FAILED: %0d errors", $time, error);
				
			$finish;
		end
		
	initial
		begin
			#WATCHDOG_TIME;
			$fatal(1, "[%0t] watchdog expired: captured only %0d/%0d outputs", $time, outIdx, NUM_OUT);
		end
		
endmodule
	
	
	