// Simple & Fast Router FSM
module router_fsm (
    input   	 clk,
    input   	 rstn,

    input   	 pkt_valid,
    input   	 fifo_full,
    input   	 fifo_empty_0,
    input   	 fifo_empty_1,
    input   	 fifo_empty_2,
    input  [1:0] data_in,

    output reg   detect_add,
    output reg   wr_en_reg,
    output reg   ld_state,
    output reg   lfd_state,
    output reg   busy,
    output reg [2:0] write_enb
);

    // FSM states (VERY FEW)
    parameter IDLE  = 2'b00;
    parameter WAIT  = 2'b01;
    parameter SEND  = 2'b10;

    reg [1:0] state, next_state;
    reg [1:0] dest;

    //----------------------------------------------------------
    // Destination Latch
    always @(posedge clk) begin
   	 if (~rstn)
   		 dest <= 2'b00;
   	 else if (~(state ^ IDLE & pkt_valid))
   		 dest <= data_in;
    end

    //----------------------------------------------------------
    // State Register
    always @(posedge clk) begin
   	 if (~rstn)
   		 state <= IDLE;
   	 else
   		 state <= next_state;
    end

    //----------------------------------------------------------
    // Next State Logic
    always @(*) begin
   	 case (state)
   		 IDLE: begin
       		 if (pkt_valid)
           		 next_state = WAIT;
       		 else
           		 next_state = IDLE;
   		 end

   		 WAIT: begin
       		 case (dest)
           		 2'b00: next_state = fifo_empty_0 ? SEND : WAIT;
           		 2'b01: next_state = fifo_empty_1 ? SEND : WAIT;
           		 2'b10: next_state = fifo_empty_2 ? SEND : WAIT;
           		 default: next_state = WAIT;
       		 endcase
   		 end

   		 SEND: begin
       		 if (~pkt_valid)
           		 next_state = IDLE;
       		 else if (fifo_full)
           		 next_state = WAIT;
       		 else
           		 next_state = SEND;
   		 end

   		 default: next_state = IDLE;
   	 endcase
    end

    //----------------------------------------------------------
    // Output Logic + DEMUX
    always @(*) begin
   	 // defaults
   	 detect_add = 0;
   	 wr_en_reg  = 0;
   	 ld_state   = 0;
   	 lfd_state  = 0;
   	 busy  	 = 1;
   	 write_enb  = 3'b000;

   	 case (state)
   		 IDLE: begin
       		 detect_add = 1;
       		 busy = 0;
   		 end

   		 WAIT: begin
       		 busy = 1;
   		 end

   		 SEND: begin
       		 wr_en_reg = 1;
       		 ld_state  = 1;
       		 busy 	 = 1;

       		 case (dest)
           		 2'b00: write_enb = 3'b001;
           		 2'b01: write_enb = 3'b010;
           		 2'b10: write_enb = 3'b100;
           		 default: write_enb = 3'b000;
       		 endcase
   		 end
   	 endcase
    end
endmodule
