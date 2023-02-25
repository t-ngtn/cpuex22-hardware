`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: t-ngtn
// 
// Create Date: 2022/12/13 16:17:13
// Design Name: 
// Module Name: server
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module server(
    );
    reg clk;
    reg rstn;
    wire [15:0] led;
    
    wire [7:0] rdata;
    wire rdata_ready;
    wire ferr;
    wire rxd;
    
    reg [7:0] sdata;
    reg tx_start;
    wire tx_busy;
    wire txd;
    reg busy_wait;

    reg [7:0] progRAM [50000:0];
    reg [16:0] pidx;
    reg [7:0] dataRAM [10000:0];
    reg [16:0] didx;

    reg [7:0] resRAM [10000:0];
    reg [16:0] ridx;

    uart_rx urx(
        .rdata(rdata),
        .rdata_ready(rdata_ready),    
        .ferr(ferr),
        .rxd(rxd),
        .clk(clk),
        .rstn(rstn)
    );
    
    uart_tx utx(
        .sdata(sdata),
        .tx_start(tx_start),
        .tx_busy(tx_busy),
        .txd(txd),
        .clk(clk),
        .rstn(rstn)
    );
    
    always begin
        clk <= 0;
        # 5;
        clk <= 1;
        # 5;
    end
    
    initial begin
        $readmemb("C:/Users/tansei/Desktop/cpu/core/sim/data/inst.txt", progRAM);        
        $readmemb("C:/Users/tansei/Desktop/cpu/core/sim/data/base.txt", dataRAM);        
        rstn <= 0;
        # 20;
        rstn <= 1;
        # 500000000;
        $finish();
    end


    reg [2:0] status;
    localparam s_wait99 = 3'b000;
    localparam s_prog_send = 3'b001;
    localparam s_data_send = 3'b010;
    localparam s_wait_ppm  = 3'b011;

    always @(posedge clk) begin
        if (~rstn) begin
            tx_start <= 0;
            pidx <= 0;
            didx <= 0;
            ridx <= 0;
            status <= s_wait99;
            busy_wait <= 0;
        end
        if (tx_start) begin
            tx_start <= 0;
        end

        if (status == s_wait99) begin
            if (rdata_ready && rdata == 8'h99) begin
                status <= s_prog_send;
            end
        end else if (status == s_prog_send) begin
            if (~tx_busy && pidx < 4  && ~busy_wait) begin        // program line size here
                sdata <= progRAM[pidx];
                tx_start <= 1;
                pidx <= pidx + 1;
                busy_wait <= 1;
            end
            if (busy_wait) begin
                busy_wait <= 0;
            end
            if (rdata_ready && rdata == 8'haa) begin
                status <= s_data_send;
            end
        end else if (status == s_data_send) begin
            if (~tx_busy && didx < 208 && ~busy_wait) begin         // data line size here
                sdata <= dataRAM[didx];
                tx_start <= 1;
                didx <= didx + 1;
                busy_wait <= 1;
            end
            if (busy_wait) begin
                busy_wait <= 0;
            end
            if (rdata_ready) begin
                resRAM[ridx] <= rdata;
                ridx <= ridx + 1;
                status <= s_wait_ppm;
            end 
        end else if (status == s_wait_ppm) begin
            if (rdata_ready) begin
                resRAM[ridx] <= rdata;
                ridx <= ridx + 1;
            end
        end
    end

    // DDR2 wires
    wire [12:0] ddr2_addr;
    wire [2:0] ddr2_ba;
    wire ddr2_cas_n;
    wire [0:0] ddr2_ck_n;
    wire [0:0] ddr2_ck_p;
    wire [0:0] ddr2_cke;
    wire ddr2_ras_n;
    wire ddr2_we_n;
    wire [15:0] ddr2_dq;
    wire [1:0] ddr2_dqs_n;
    wire [1:0] ddr2_dqs_p;
    wire [0:0] ddr2_cs_n;
    wire [1:0] ddr2_dm;
    wire [0:0] ddr2_odt;

    // DDR2 model
    ddr2 ddr2 (
        .ck(ddr2_ck_p),
        .ck_n(ddr2_ck_n),
        .cke(ddr2_cke),
        .cs_n(ddr2_cs_n),
        .ras_n(ddr2_ras_n),
        .cas_n(ddr2_cas_n),
        .we_n(ddr2_we_n),
        .dm_rdqs(ddr2_dm),
        .ba(ddr2_ba),
        .addr(ddr2_addr),
        .dq(ddr2_dq),
        .dqs(ddr2_dqs_p),
        .dqs_n(ddr2_dqs_n),
        .rdqs_n(),
        .odt(ddr2_odt)
    );
    
    top top(
        clk,
        rstn, 
        led,
        txd, 
        rxd, 
        // DDR2
        ddr2_addr,
        ddr2_ba,
        ddr2_cas_n,
        ddr2_ck_n,
        ddr2_ck_p,
        ddr2_cke,
        ddr2_ras_n,
        ddr2_we_n,
        ddr2_dq,
        ddr2_dqs_n,
        ddr2_dqs_p,
        ddr2_cs_n,
        ddr2_dm,
        ddr2_odt
        );
endmodule
