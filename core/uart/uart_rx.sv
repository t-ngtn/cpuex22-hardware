`include "io_params.vh"
`default_nettype none

module uart_rx #(CLK_PER_HALF_BIT = _CLK_PER_HALF_BIT) (
               output logic [7:0] rdata,
               output logic       rdata_ready,
               output logic       ferr,
               input wire         rxd,
               input wire         clk,
               input wire         rstn);
               
   localparam CLK_PER_BIT = CLK_PER_HALF_BIT * 2 - 1;
   
   logic [3:0] status;
   localparam s_idle = 4'd0;
   localparam s_start_bit = 4'd1;
   localparam s_bit_0 = 4'd2;
   localparam s_bit_1 = 4'd3;
   localparam s_bit_2 = 4'd4;
   localparam s_bit_3 = 4'd5;
   localparam s_bit_4 = 4'd6;
   localparam s_bit_5 = 4'd7;
   localparam s_bit_6 = 4'd8;
   localparam s_bit_7 = 4'd9;
   localparam s_stop_bit = 4'd10;
   
   logic [31:0] cnt;
   logic [7:0] rxbuf;
   logic [6:0] rxbuf_shift;

   assign rxbuf_shift = rxbuf >> 1;

   always @(posedge clk) begin
      if (~rstn) begin
         status <= s_idle;
         ferr <= 1'b0;
         rdata <= 8'b0;
         rxbuf <= 8'b0;
      end else begin
         if (rdata_ready)begin
            rdata_ready <= 1'b0;
         end

         if (status == s_idle) begin
            if (~rxd) begin
               status <= s_start_bit;
               rxbuf <= 8'b0;
               cnt <= 0;
            end
         end else if (status == s_start_bit) begin
            cnt <= cnt + 1;
            if (cnt == CLK_PER_HALF_BIT - 2) begin
               if (rxd) begin 
                  ferr <= 1'b1;
               end
               status <= status + 1;
               cnt <= 0;
            end
         end else if (status == s_stop_bit) begin
            cnt <= cnt + 1;
            if (cnt == CLK_PER_BIT) begin
               if (~rxd) begin
                  ferr <= 1'b1;
               end
               status <= s_idle;
               rdata <= rxbuf;
               rdata_ready <= 1'b1;
               cnt <= 0;
            end
         end else begin 
            cnt <= cnt + 1;
            if (cnt == CLK_PER_BIT) begin
               rxbuf <= {rxd, rxbuf_shift};
               status <= status + 1'b1;
               cnt <= 0;
            end
         end
      end
   end
   
endmodule
`default_nettype wire