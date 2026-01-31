// Simple Router Synchronizer Module
module comparator_5bit (
	input  [4:0] a,
	input  [4:0] b,
	output   	eq
);
	wire [4:0] xnor_bits;
	// Bitwise XNOR
	assign xnor_bits[0] = ~(a[0] ^ b[0]);
	assign xnor_bits[1] = ~(a[1] ^ b[1]);
	assign xnor_bits[2] = ~(a[2] ^ b[2]);
	assign xnor_bits[3] = ~(a[3] ^ b[3]);
	assign xnor_bits[4] = ~(a[4] ^ b[4]);
	// Equality = AND of all XNOR results
	assign eq = &xnor_bits;  // cleaner reduction AND
endmodule
module adder_5bit (
	input  [4:0] a,
	input  [4:0] b,
	input    	cin,
	output [4:0] sum,
	output   	cout
);
	wire [4:0] carry;
	// Bit 0
	assign sum[0]   = a[0] ^ b[0] ^ cin;
	assign carry[0] = (a[0] & b[0]) | (a[0] & cin) | (b[0] & cin);
	// Bit 1
	assign sum[1]   = a[1] ^ b[1] ^ carry[0];
	assign carry[1] = (a[1] & b[1]) | (a[1] & carry[0]) | (b[1] & carry[0]);
	// Bit 2
	assign sum[2]   = a[2] ^ b[2] ^ carry[1];
	assign carry[2] = (a[2] & b[2]) | (a[2] & carry[1]) | (b[2] & carry[1]);
	// Bit 3
	assign sum[3]   = a[3] ^ b[3] ^ carry[2];
	assign carry[3] = (a[3] & b[3]) | (a[3] & carry[2]) | (b[3] & carry[2]);
	// Bit 4
	assign sum[4]   = a[4] ^ b[4] ^ carry[3];
	assign carry[4] = (a[4] & b[4]) | (a[4] & carry[3]) | (b[4] & carry[3]);
	assign cout = carry[4];
endmodule

module router_sync (
	input    	clk,
	input    	resetn,
	input    	detect_add,
	input    	write_enb_reg,
	input    	read_enb_0,
	input    	read_enb_1,
	input    	read_enb_2,
	input    	empty_0,
	input    	empty_1,
	input    	empty_2,
	input    	full_0,
	input    	full_1,
	input    	full_2,
	input  [1:0] datain,

	output   	vld_out_0,
	output   	vld_out_1,
	output   	vld_out_2,
	output reg [2:0] write_enb,
	output reg   	fifo_full,
	output reg   	soft_reset_0,
	output reg   	soft_reset_1,
	output reg   	soft_reset_2
);
	// Timeout counters
	reg [4:0] count0, count1, count2;
	//-------------------------------------------------------
	// FIFO Full Selection
	always @(*) begin
    	case (datain)
        	2'b00: fifo_full = full_0;
        	2'b01: fifo_full = full_1;
        	2'b10: fifo_full = full_2;
        	default: fifo_full = 1'b0;
    	endcase
	end
	//-------------------------------------------------------
	// Write Enable Decoder
	always @(*) begin
    	if (write_enb_reg) begin
        	case (datain)
            	2'b00: write_enb = 3'b001;
            	2'b01: write_enb = 3'b010;
            	2'b10: write_enb = 3'b100;
            	default: write_enb = 3'b000;
        	endcase
    	end else
        	write_enb = 3'b000;
	end
	//-------------------------------------------------------
	// Valid Output Signals
	assign vld_out_0 = ~empty_0;
	assign vld_out_1 = ~empty_1;
	assign vld_out_2 = ~empty_2;
	//-------------------------------------------------------
	// FIFO 0 Timeout Logic
	wire eq_flag0;
	wire [4:0] next_count0;
	adder_5bit add_inst0 (.a(count0), .b(5'b00001), .cin(1'b0), .sum(next_count0), .cout());
	comparator_5bit cmp_inst0 (.a(count0), .b(5'd30), .eq(eq_flag0));
	always @(posedge clk) begin
    	if (~resetn) begin
        	count0 <= 5'b0;
        	soft_reset_0 <= 1'b0;
    	end else if (vld_out_0 & ~read_enb_0) begin
        	if (eq_flag0) begin
            	soft_reset_0 <= 1'b1;
            	count0 <= 5'b0;
        	end else begin
            	count0 <= next_count0;
            	soft_reset_0 <= 1'b0;
        	end
    	end else begin
        	count0 <= 5'b0;
        	soft_reset_0 <= 1'b0;
    	end
	end
	//-------------------------------------------------------
	// FIFO 1 Timeout Logic
	wire eq_flag1;
	wire [4:0] next_count1;
	adder_5bit add_inst1 (.a(count1), .b(5'b00001), .cin(1'b0), .sum(next_count1), .cout());
	comparator_5bit cmp_inst1 (.a(count1), .b(5'd30), .eq(eq_flag1));

	always @(posedge clk) begin
    	if (~resetn) begin
        	count1 <= 5'b0;
        	soft_reset_1 <= 1'b0;
    	end else if (vld_out_1 & ~read_enb_1) begin
        	if (eq_flag1) begin
            	soft_reset_1 <= 1'b1;
            	count1 <= 5'b0;
        	end else begin
            	count1 <= next_count1;
            	soft_reset_1 <= 1'b0;
        	end
    	end else begin
        	count1 <= 5'b0;
        	soft_reset_1 <= 1'b0;
    	end
	end

	//-------------------------------------------------------
	// FIFO 2 Timeout Logic
	wire eq_flag2;
	wire [4:0] next_count2;

	adder_5bit add_inst2 (.a(count2), .b(5'b00001), .cin(1'b0), .sum(next_count2), .cout());
	comparator_5bit cmp_inst2 (.a(count2), .b(5'd30), .eq(eq_flag2));

	always @(posedge clk) begin
    	if (~resetn) begin
        	count2 <= 5'b0;
        	soft_reset_2 <= 1'b0;
    	end else if (vld_out_2 & ~read_enb_2) begin
        	if (eq_flag2) begin
            	soft_reset_2 <= 1'b1;
            	count2 <= 5'b0;
        	end else begin
            	count2 <= next_count2;
            	soft_reset_2 <= 1'b0;
        	end
    	end else begin
        	count2 <= 5'b0;
        	soft_reset_2 <= 1'b0;
    	end
	end

endmodule
