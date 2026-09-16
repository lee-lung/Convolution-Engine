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
	parameter NUM_ITERATIONS = 10;
	
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
	
	//Coverage 
	
	//macOut magnitude coverage 
	covergroup cg_macOut @(posedge clk iff valid);
		coverpoint macOut{
				option.auto_bin_max = 10;
		}
	endgroup
	cg_macOut cg_macOut_inst = new();
	
	//pixelValue coverage
	covergroup cg_pixel @(posedge clk iff pixel_valid);
		coverpoint pixelIn {
				bins zero_edge = {0};
				bins low = {[1:63]};
				bins mid = {[64:191]};
				bins high = {[192:254]};
				bins max_edge = {255};
		}
	endgroup
	cg_pixel cg_pixel_inst = new();
	
	int iter;
	int errorAtIterStart;
	time lastProgressTime;
	
	//capture + scoreboard 
	int outIdx = 0;
	int error = 0;
	
	
	//stimulus sequence 
	initial
		begin
			pixelIn <= 0;
			pixel_valid <= 0;
			rst_n <= 0;
			lastProgressTime = 0;
			@(posedge clk);
			@(posedge clk);
			@(posedge clk);
			rst_n <= 1;
			@(posedge clk);
			
			for (iter = 0; iter < NUM_ITERATIONS; iter++)
				begin
					$readmemh($sformatf("image%0d.hex",iter), imageArray);
					$readmemh($sformatf("golden%0d.hex", iter), goldenArray);
					outIdx = 0;
					errorAtIterStart = error;
					
					pixel_valid <= 1;
					for (int i = 0; i < NUM_IN; i++)
						begin
							pixelIn <= imageArray[i];
							@(posedge clk);
						end
					pixel_valid <= 0;
					
					wait(outIdx == NUM_OUT);
					@(posedge clk);
					@(posedge clk);
					@(posedge clk);
					
					if (error == errorAtIterStart)
						$display ("[%0t] iteration %0d PASSED: %0d/%0d outputs matched", $time, iter, outIdx, NUM_OUT);
					else 
						$display ("[%0t] iteration %0d FAILED: %0d errors", $time, iter, error - errorAtIterStart);
				end
				
			$display ("[%0t] ALL ITERATIONS COMPLETE: %0d total errors across %0d iterations", $time, error, NUM_ITERATIONS);
			$display("macOut coverage: %0.2f%%", cg_macOut_inst.get_coverage());
			$display("pixel coverage: %0.2f%%", cg_pixel_inst.get_coverage());
			$finish;
		end
	
	
	always @(posedge clk)
		begin
			if(valid)
				begin
					if (macOut !== goldenArray[outIdx])
						begin
							error++;
							$error("[%0t] output %0d: expected: %0d,  got: %0d", $time, outIdx, goldenArray[outIdx], macOut);
						end
						outIdx++;
					lastProgressTime <= $time;
				end
		end 

	//termination and summary 

		
	initial
		begin
			forever
				begin
					#WATCHDOG_TIME;
					if (($time - lastProgressTime) >= WATCHDOG_TIME)
					$fatal(1, "[%0t] watchdog expired: no output progress for %0d ns (iter %0d, outIdx %0d/%0d)",$time, WATCHDOG_TIME, iter, outIdx, NUM_OUT);
				end
		end
		
endmodule
	
	
	