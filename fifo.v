//=========================================================
// Generic Equality Comparator (Truth Table Based)
module eq_cmp #(parameter WIDTH = 5) (
	input  [WIDTH-1:0] a,
	input  [WIDTH-1:0] b,
	output         	eq
);
	// Bitwise XNOR gives 1 if bits are equal
	wire [WIDTH-1:0] bit_equal;
	assign bit_equal = ~(a ^ b);
	// Reduce AND across all bits to check full equality
	assign eq = &bit_equal;
endmodule

//=========================================================
// Generic adder
//=========================================================
module add #(parameter WIDTH = 5) (
	input  [WIDTH-1:0] a,
	input  [WIDTH-1:0] b,
	output [WIDTH-1:0] sum
);
	assign sum = a + b;
endmodule

//=========================================================
// Generic subtractor
//=========================================================
module sub #(parameter WIDTH = 5) (
	input  [WIDTH-1:0] a,
	input  [WIDTH-1:0] b,
	output [WIDTH-1:0] diff
);
	assign diff = a - b;
endmodule

//=========================================================
// Simple 8-bit FIFO using comparator, adder, and subtractor
//=========================================================
module router_fifo (
	input    	clk,
	input    	resetn,  	// active-low reset
	input    	soft_reset,  // synchronous reset
	input    	write_enb,
	input    	read_enb,
	input  [7:0] datain,

	output reg   full,
	output reg   empty,
	output reg [7:0] dataout
);

	// FIFO memory
	reg [7:0] mem [15:0];

	// Pointers and counter
	reg [3:0] wptr;
	reg [3:0] rptr;
	reg [4:0] count;

	//-------------------------------------------------------
	// Equality comparators for full/empty
	wire eq_full;
	wire eq_empty;

	eq_cmp #(5) cmp_full  (.a(count), .b(5'd16), .eq(eq_full));
	eq_cmp #(5) cmp_empty (.a(count), .b(5'd0),  .eq(eq_empty));

	//-------------------------------------------------------
	// Arithmetic modules for count updates
	wire [4:0] count_plus1;
	wire [4:0] count_minus1;

	add #(5) add_count (.a(count), .b(5'd1), .sum(count_plus1));
	sub #(5) sub_count (.a(count), .b(5'd1), .diff(count_minus1));

	//-------------------------------------------------------
	// Write Operation
	always @(posedge clk) begin
    	if (~resetn | soft_reset) begin
        	wptr <= 4'b0000;
    	end else if (write_enb & ~full) begin
        	mem[wptr] <= datain;
        	wptr <= wptr + 4'd1;  // FIXED: use 4'd1 instead of 1'b1
    	end
	end

	//-------------------------------------------------------
	// Read Operation
	always @(posedge clk) begin
    	if (~resetn | soft_reset) begin
        	rptr <= 4'b0000;
        	dataout <= 8'b0;
    	end else if (read_enb & ~empty) begin
        	dataout <= mem[rptr];
        	rptr <= rptr + 4'd1;  // FIXED: use 4'd1 instead of 1'b1
    	end
	end

	//-------------------------------------------------------
	// Count Logic
	always @(posedge clk) begin
    	if (~resetn | soft_reset)
        	count <= 5'b00000;
    	else begin
        	if (write_enb & ~full & ~(read_enb & ~empty))
            	count <= count_plus1;   // use adder module
        	else if (read_enb & ~empty & ~(write_enb & ~full))
            	count <= count_minus1;  // use subtractor module
    	end
	end

	//-------------------------------------------------------
	// Full and Empty Flags
	always @(posedge clk) begin
    	if (~resetn | soft_reset) begin
        	full  <= 1'b0;
        	empty <= 1'b1;
    	end else begin
        	full  <= eq_full;
        	empty <= eq_empty;
    	end
	end
endmodule
