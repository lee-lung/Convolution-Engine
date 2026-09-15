//

module sva_validity_reset #(parameter COUNT_SIZE = $clog2(25))(input logic clk, inpt logic rst_n, input logic [COUNT_SIZE - 1:0] counter, input logic valid);

	property reset_cleared_on_release
		@(posedge clk) $rose(rst_n) |-> (counter == 0 && valid == 0);
	endproperty
	
	assert property (reset_cleared_on_release)
		else $error("[%0t] reset release check failed: counter=%0d, valid=%0d (expected both 0)", $time, counter, valid);

endmodule

bind validity sva_validity_reset sva_validity_reset_inst (.clk(clk),.rst_n(rst_n),.counter(counter), .valid(valid);


module sva_linebuffer_pixel_valid #(parameter IMAGE_SIZE = 5) (input logic clk, input rst_n, input logic pixel_valid, input logic [7:0] shiftReg [0:IMAGE_SIZE - 1[);
	
	 property pixel_valid_gates_shiftreg;
        @(posedge clk) disable iff (!rst_n) (!pixel_valid) |-> $stable(shiftReg);
    endproperty
    assert property (pixel_valid_gates_shiftreg)
        else $error("[%0t] shiftReg changed while pixel_valid was low", $time);
endmodule

bind lineBuffer sva_linebuffer_pixel_valid #(.IMAGE_SIZE(IMAGE_SIZE)) sva_linebuffer_pixel_valid_inst (
    .clk(clk), .rst_n(rst_n), .pixel_valid(pixel_valid), .shiftReg(shiftReg)
);

module sva_validity_pixel_valid (input logic clk,input logic rst_n,input logic pixel_valid, input logic [4:0] counter);
    property pixel_valid_gates_counter;
        @(posedge clk) disable iff (!rst_n) (!pixel_valid) |-> $stable(counter);
    endproperty
    assert property (pixel_valid_gates_counter)
        else $error("[%0t] counter changed while pixel_valid was low", $time);
endmodule

bind validity sva_validity_pixel_valid sva_validity_pixel_valid_inst (
    .clk(clk), .rst_n(rst_n), .pixel_valid(pixel_valid), .counter(counter)
);