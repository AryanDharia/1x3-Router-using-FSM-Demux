// Simple Router Register Module (1x3 Router)
module router_reg (
    input   	 clk,
    input   	 rstn, 		 // active-low reset
    input   	 pkt_valid,
    input   	 fifo_full,
    input   	 detect_add,
    input   	 ld_state,
    input   	 laf_state,
    input   	 lfd_state,
    input   	 rst_int_reg,
    input  [7:0] data_in,

    output reg   err,
    output reg   parity_done,
    output reg   low_pkt_valid,
    output reg [7:0] dout
);

    // Internal registers
    reg [7:0] header;
    reg [7:0] saved_data;
    reg [7:0] parity_calc;
    reg [7:0] parity_rx;

    //----------------------------------------------------------
    // Data Path Logic
    always @(posedge clk) begin
   	 if (~rstn) begin
   		 dout  	 <= 8'b0;
   		 header     <= 8'b0;
   		 saved_data <= 8'b0;
   	 end else begin
   		 if (detect_add & pkt_valid)
       		 header <= data_in;

   		 else if (lfd_state)
       		 dout <= header;
   	 else if(ld_state) begin
  	  if(fifo_full) begin
  		  saved_data <= data_in;
  	  end else begin
  		  dout <= data_in;
  	  end
  	 
   		 end else if (laf_state)
       		 dout <= saved_data;
   	 end
    end

    //----------------------------------------------------------
    // Low Packet Valid Flag
    always @(posedge clk) begin
   	 if (~rstn)
   		 low_pkt_valid <= 1'b0;
   	 else if (rst_int_reg)
   		 low_pkt_valid <= 1'b0;
   	 else if (ld_state & pkt_valid)
   		 low_pkt_valid <= 1'b1;
    end

    //----------------------------------------------------------
    // Parity Calculation
    always @(posedge clk) begin
   	 if (~rstn)
   		 parity_calc <= 8'b0;
   	 else if (detect_add)
   		 parity_calc <= 8'b0;
   	 else if (lfd_state & pkt_valid)
   		 parity_calc <= parity_calc ^ header;
   	 else if (ld_state & pkt_valid & ~fifo_full)
   		 parity_calc <= parity_calc ^ data_in;
    end

    //----------------------------------------------------------
    // Capture Received Parity Byte
    always @(posedge clk) begin
   	 if (~rstn)
   		 parity_rx <= 8'b0;
   	 else if (ld_state & ~pkt_valid)
   		 parity_rx <= data_in;
    end

    //----------------------------------------------------------
    // Parity Done Signal
    always @(posedge clk) begin
   	 if (~rstn)
   		 parity_done <= 1'b0;
   	 else if (detect_add)
   		 parity_done <= 1'b0;
   	 else if (ld_state & ~pkt_valid)
   		 parity_done <= 1'b1;
    end

    //----------------------------------------------------------
    // Error Detection
    always @(posedge clk) begin
   	 if (~rstn)
   		 err <= 1'b0;
   	 else if (parity_done) begin
   		 if (~(parity_calc ^ parity_rx))
       		 err <= 1'b0;
   		 else
       		 err <= 1'b1;
   	 end
    end
endmodule
