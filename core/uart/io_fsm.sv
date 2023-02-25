`include "io_params.vh"
`default_nettype none

module IO_fsm #(CLK_PER_HALF_BIT = _CLK_PER_HALF_BIT) (
    input wire  clk,
    input wire  rstn,
    input wire  rxd,
    input wire [7:0] sdata_buf,
    input wire sdata_valid,
    output wire txd,
    output reg [31:0] rdata_buf,
    output reg rdata_buf_ready,
    output reg is_input,
    output reg io_stall,
    output reg output_busy,
    output wire [2:0] led
);


    logic [31:0] _rdata_buf;
    logic _rdata_buf_ready;

    logic [2:0] status;
    localparam s_ready          = 3'b000;  // 諸々の初期化待ち
    localparam s_rec_prog_start = 3'b001;  // 0x99を送信して受信を開始
    localparam s_rec_prog       = 3'b010;  // プログラムを受信
    localparam s_rec_start      = 3'b011;  // 0xaaを送信して標準入力の受信を開始
    localparam s_rec            = 3'b100;  // 標準入力受信モード
    localparam s_send           = 3'b101;  // 送信モード
    localparam s_wait           = 3'b110;  // 待ち(使う？)

    assign led = status;

    logic is_ready;

    logic [31:0] prog_size;
    logic [31:0] recv_size;

    logic [7:0] sdata;
    logic tx_start;
    logic tx_busy;

    logic t_status;

    always_ff @( posedge clk ) begin : DMA_ctl
        if (tx_start) begin
            tx_start <= 0;
        end

        if (~rstn) begin
            status <= s_ready;
            tx_start <= 0;
            is_ready <= 0;
            t_status <= 0;
            recv_size <= 0;
            io_stall <= 1;
            rdata_buf <= 0;
            rdata_buf_ready <= 0;
            is_input <= 0;
        end else if (status == s_ready) begin
            is_ready <= 1;
            if (is_ready) begin
                status <= s_rec_prog_start;
            end
        end else if (status == s_rec_prog_start) begin
            sdata <= 'h99;
            tx_start <= 1;
            if (_rdata_buf_ready) begin
                prog_size <= _rdata_buf;
                status <= s_rec_prog;
            end
        end else if (status == s_rec_prog) begin
            rdata_buf_ready <= _rdata_buf_ready;
            if (_rdata_buf_ready) begin
                rdata_buf <= _rdata_buf;
                recv_size <= recv_size + 4;
            end
            if (prog_size == recv_size) begin
                status <= s_rec_start;
                io_stall <= 0;
            end
        end else if (status == s_rec_start) begin
            if (~tx_busy) begin
                sdata <= 'haa;
                tx_start <= 1;
                status <= s_rec;
                is_input <= 1;
                output_busy <= 1;
                t_status <= 1;
            end
        end else if (status == s_rec) begin
            rdata_buf_ready <= _rdata_buf_ready;
            if (_rdata_buf_ready) begin
                rdata_buf <= _rdata_buf;
            end
            if (sdata_valid) begin
                status <= s_send;
                sdata <= sdata_buf;
                tx_start <= 1;
                t_status <= 1;
                output_busy <= 1;
            end 

            if (t_status) begin
                t_status <= 0;
            end else begin
                output_busy <= tx_busy;
            end
        end else if (status == s_send) begin
            if (~tx_busy && t_status==0 && sdata_valid) begin
                sdata <= sdata_buf;
                tx_start <= 1;
                t_status <= 1;
                output_busy <= 1;
            end 
            if (t_status) begin
                t_status <= 0;
            end else begin
                output_busy <= tx_busy;
            end

        end 
    end

    uart_buf_rx u_buf_rx(
        _rdata_buf,
        _rdata_buf_ready,
        rxd,
        clk,
        rstn
    );

    uart_tx u_tx(
        sdata,
        tx_start,
        tx_busy,
        txd,
        clk,
        rstn
    );

endmodule
`default_nettype wire