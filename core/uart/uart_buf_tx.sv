`include "io_params.vh"
`default_nettype none

module uart_buf_tx #(CLK_PER_HALF_BIT = _CLK_PER_HALF_BIT) (
    input wire [31:0] sdata,
    input wire is_b,
    input wire tx_buf_start,
    output logic tx_buf_busy,
    output logic txd,
    input wire clk,
    input wire rstn
);
    reg [31:0] sdata_buf;
    reg [7:0] data;
    reg tx_start;
    wire tx_busy;
    uart_tx #(CLK_PER_HALF_BIT) u_tx(data, tx_start, tx_busy, txd, clk, rstn);

    reg [2:0] status;
    localparam s_idle   = 3'b000;
    localparam s_byte_1 = 3'b001;
    localparam s_byte_2 = 3'b010;
    localparam s_byte_3 = 3'b011;
    localparam s_byte_4 = 3'b100;
    reg busy_wait;

    always_ff @( posedge clk ) begin : buf_tx
        if (~rstn) begin 
            status <= s_idle;
            busy_wait <= 0;
            tx_buf_busy <= 0;
            tx_start <= 0;
            data <= 0;
        end

        if (tx_start) begin
            tx_start <= 0;
        end

        if (status == s_idle) begin
            if (tx_buf_start) begin
                sdata_buf <= sdata;
                tx_buf_busy <= 1;
                status <= s_byte_1;
            end
        end else if (status == s_byte_1) begin
            if (~tx_busy && ~busy_wait) begin
                data <= sdata_buf[7:0];
                tx_start <= 1;
                busy_wait <= 1;
            end
            if (busy_wait) begin
                busy_wait <= 0;
                status <= s_byte_2;
            end
        end else if (status == s_byte_2) begin
            if (~tx_busy && ~busy_wait) begin
                data <= sdata_buf[15:8];
                tx_start <= 1;
                busy_wait <= 1;
            end
            if (busy_wait) begin
                busy_wait <= 0;
                status <= s_byte_3;
            end
        end else if (status == s_byte_3) begin
            if (~tx_busy && ~busy_wait) begin
                data <= sdata_buf[23:16];
                tx_start <= 1;
                busy_wait <= 1;
            end
            if (busy_wait) begin
                busy_wait <= 0;
                status <= s_byte_4;
            end
        end else if (status == s_byte_4) begin
            if (~tx_busy && ~busy_wait) begin
                data <= sdata_buf[31:24];
                tx_start <= 1;
                busy_wait <= 1;
            end
            if (busy_wait) begin
                busy_wait <= 0;
                status <= s_idle;
                tx_buf_busy <= 0;
            end
        end
    end



endmodule
`default_nettype wire