`timescale 1ns/1ps

module tb_router_top;

  reg clk;
  reg resetn;
  reg packet_valid;
  reg read_enb_0, read_enb_1, read_enb_2;
  reg [7:0] datain;

  wire vldout_0, vldout_1, vldout_2;
  wire err, busy;
  wire [7:0] data_out_0, data_out_1, data_out_2;
  wire low_packet_valid, write_enb_reg;

  router_top DUT (
    .clk(clk),
    .resetn(resetn),
    .packet_valid(packet_valid),
    .read_enb_0(read_enb_0),
    .read_enb_1(read_enb_1),
    .read_enb_2(read_enb_2),
    .datain(datain),
    .vldout_0(vldout_0),
    .vldout_1(vldout_1),
    .vldout_2(vldout_2),
    .err(err),
    .busy(busy),
    .data_out_0(data_out_0),
    .data_out_1(data_out_1),
    .data_out_2(data_out_2),
    .low_packet_valid(low_packet_valid),
    .write_enb_reg(write_enb_reg)
  );

  initial begin
    clk = 1'b0;
    forever #5 clk = ~clk;
  end

  task send_packet;
    input [1:0] addr;
    input integer payload_len;
    integer i;
    reg [7:0] header;
    reg [7:0] parity;
    reg [7:0] payload;
    begin
      header = {payload_len[5:0], addr};
      parity = header;

      $display("\n[%0t] SENDING PACKET -> ADDR=%b LEN=%0d HEADER=%h", $time, addr, payload_len, header);

      while (busy == 1'b1) @(negedge clk);

      @(negedge clk);
      packet_valid = 1'b1;
      datain = header;

      for (i = 0; i < payload_len; i = i + 1) begin
        @(negedge clk);
        payload = $random;
        datain = payload;
        parity = parity ^ payload;
        $display("[%0t] PAYLOAD[%0d]=%h", $time, i, payload);
      end

      @(negedge clk);
      packet_valid = 1'b0;
      datain = parity;
      $display("[%0t] PARITY=%h", $time, parity);

      @(negedge clk);
      datain = 8'h00;
    end
  endtask

  initial begin
    $dumpfile("router_wave.vcd");
    $dumpvars(0, tb_router_top);

    resetn = 1'b0;
    packet_valid = 1'b0;
    datain = 8'h00;
    read_enb_0 = 1'b0;
    read_enb_1 = 1'b0;
    read_enb_2 = 1'b0;

    $display("==================================================");
    $display("            ROUTER 1x3 TESTBENCH START             ");
    $display("==================================================");

    $monitor("[%0t] clk=%b rstn=%b busy=%b pkt_valid=%b din=%h | v0=%b d0=%h | v1=%b d1=%h | v2=%b d2=%h | err=%b",
              $time, clk, resetn, busy, packet_valid, datain,
              vldout_0, data_out_0,
              vldout_1, data_out_1,
              vldout_2, data_out_2,
              err);

    #20 resetn = 1'b1;
    $display("[%0t] RESET DEASSERTED", $time);

    send_packet(2'b00, 4);
    send_packet(2'b01, 4);
    send_packet(2'b10, 4);

    #30;
    $display("\n[%0t] READING ALL FIFOS", $time);
    read_enb_0 = 1'b1;
    read_enb_1 = 1'b1;
    read_enb_2 = 1'b1;

    #200;
    read_enb_0 = 1'b0;
    read_enb_1 = 1'b0;
    read_enb_2 = 1'b0;

    $display("\n[%0t] TEST FINISHED", $time);
    #50 $finish;
  end

endmodule
