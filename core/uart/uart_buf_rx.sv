`include "io_params.vh"
`default_nettype none

module uart_buf_rx #(CLK_PER_HALF_BIT = _CLK_PER_HALF_BIT) (
    output logic [31:0] rdata_buf,
    output logic rdata_buf_ready,
    input wire rxd,
    input wire clk,
    input wire rstn
);

    reg data_valid;
    wire [7:0] rdata;
    wire rx_ready;
    wire ferr;
    uart_rx #(CLK_PER_HALF_BIT) u_rx(rdata, rx_ready, ferr, rxd, clk, rstn);
    reg [1:0] status;

    localparam s_byte_1 = 2'b00;
    localparam s_byte_2 = 2'b01;
    localparam s_byte_3 = 2'b10;
    localparam s_byte_4 = 2'b11;

    always_ff @( posedge clk ) begin : buf_rx
        if (~rstn) begin 
            status <= s_byte_1;
            rdata_buf_ready <= 0;
            rdata_buf <= 0;
        end 

        if (rdata_buf_ready) begin 
            rdata_buf_ready <= 1'b0;
        end

        if (rx_ready) begin
            if(status == s_byte_1) begin
                rdata_buf[7:0] <= rdata;
                status <= s_byte_2;
            end else if (status == s_byte_2) begin
                rdata_buf[15:8] <= rdata;
                status <= s_byte_3;
            end else if (status == s_byte_3) begin
                rdata_buf[23:16] <= rdata;
                status <= s_byte_4;
            end else if (status == s_byte_4) begin
                rdata_buf[31:24] <= rdata;
                status <= s_byte_1;
                rdata_buf_ready <= 1'b1;
            end
        end

    end


endmodule
`default_nettype wire