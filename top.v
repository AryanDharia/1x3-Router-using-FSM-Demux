//======================================================
// Top-level Router Module (1x3 Router)
module router_top (
    input   	 clk,
    input   	 resetn,
    input   	 packet_valid,
    input   	 read_enb_0,
    input   	 read_enb_1,
    input   	 read_enb_2,
    input  [7:0] datain,

    output  	 vldout_0,
    output  	 vldout_1,
    output  	 vldout_2,
    output  	 err,
    output  	 busy,
    output [7:0] data_out_0,
    output [7:0] data_out_1,
    output [7:0] data_out_2,
    output  	 low_packet_valid,
    output  	 write_enb_reg
);
    //=========================================
    // Internal Signals
    wire [2:0] write_enb;
    wire [2:0] soft_reset;
    wire [2:0] read_enb;
    wire [2:0] empty;
    wire [2:0] full;

    wire [7:0] dout;
    wire  	 fifo_full;
    wire  	 detect_add;
    wire  	 ld_state;
    wire  	 laf_state;
    wire  	 full_state;
    wire  	 rst_int_reg;
    wire  	 parity_done;

    wire [7:0] fifo_data_0;
    wire [7:0] fifo_data_1;
    wire [7:0] fifo_data_2;

    //=========================================
    // Read Enable Mapping
    assign read_enb[0] = read_enb_0;
    assign read_enb[1] = read_enb_1;
    assign read_enb[2] = read_enb_2;

    //=========================================
    // FIFO Instances
    router_fifo fifo0 (
   	 .clk   	 (clk),
   	 .resetn     (resetn),
   	 .soft_reset (soft_reset[0]),
   	 .write_enb  (write_enb[0]),
   	 .read_enb   (read_enb[0]),
   	 .datain     (dout),
   	 .full  	 (full[0]),
   	 .empty 	 (empty[0]),
   	 .dataout    (fifo_data_0)
    );
    router_fifo fifo1 (
   	 .clk   	 (clk),
   	 .resetn     (resetn),
   	 .soft_reset (soft_reset[1]),
   	 .write_enb  (write_enb[1]),
   	 .read_enb   (read_enb[1]),
   	 .datain     (dout),
   	 .full  	 (full[1]),
   	 .empty 	 (empty[1]),
   	 .dataout    (fifo_data_1)
    );
    router_fifo fifo2 (
   	 .clk   	 (clk),
   	 .resetn     (resetn),
   	 .soft_reset (soft_reset[2]),
   	 .write_enb  (write_enb[2]),
   	 .read_enb   (read_enb[2]),
   	 .datain     (dout),
   	 .full  	 (full[2]),
   	 .empty 	 (empty[2]),
   	 .dataout    (fifo_data_2)
    );

    //=========================================
    // Router Register Block
    router_reg reg_inst (
   	 .clk  		 (clk),
   	 .rstn 		 (resetn),
   	 .pkt_valid     (packet_valid),
   	 .data_in  	 (datain),
   	 .fifo_full     (fifo_full),
   	 .detect_add    (detect_add),
   	 .ld_state 	 (ld_state),
   	 //.laf_state     (laf_state),
   	 //.full_state    (full_state),
   	 .rst_int_reg   (rst_int_reg),
   	 .dout 		 (dout),
   	 .err  		 (err),
   	 .parity_done   (parity_done),
   	 .low_pkt_valid (low_packet_valid)
    );
    //=========================================
    // FSM (Routing Control)
    router_fsm fsm_inst (
   	 .clk  		 (clk),
   	 .rstn 		 (resetn),
   	 .pkt_valid     (packet_valid),
   	 .data_in  	 (datain[1:0]),
   	 .fifo_full     (fifo_full),
   	 .fifo_empty_0  (empty[0]),
   	 .fifo_empty_1  (empty[1]),
   	 .fifo_empty_2  (empty[2]),

   	 .busy 		 (busy),
   	 .detect_add    (detect_add),
   	 .ld_state 	 (ld_state),
   	 //.laf_state     (laf_state),
   	 .wr_en_reg     (write_enb_reg),
   	 .write_enb     (write_enb)
    );
    //=========================================
    // Synchronizer + Address Decoder
    router_sync sync_inst (
   	 .clk   		 (clk),
   	 .resetn		 (resetn),
   	 .datain		 (datain[1:0]),
   	 .write_enb_reg  (write_enb_reg),
   	 .read_enb_0     (read_enb[0]),
   	 .read_enb_1     (read_enb[1]),
   	 .read_enb_2     (read_enb[2]),
   	 .empty_0   	 (empty[0]),
   	 .empty_1   	 (empty[1]),
   	 .empty_2   	 (empty[2]),
   	 .full_0		 (full[0]),
   	 .full_1		 (full[1]),
   	 .full_2		 (full[2]),
   	 .fifo_full 	 (fifo_full),
   	 .vld_out_0 	 (vldout_0),
   	 .vld_out_1 	 (vldout_1),
   	 .vld_out_2 	 (vldout_2),
   	 .soft_reset_0   (soft_reset[0]),
   	 .soft_reset_1   (soft_reset[1]),
   	 .soft_reset_2   (soft_reset[2]),
   	 .write_enb 	 (write_enb)
    );
    //=========================================
    // Output Assignments
    assign data_out_0 = fifo_data_0;
    assign data_out_1 = fifo_data_1;
    assign data_out_2 = fifo_data_2;

endmodule
