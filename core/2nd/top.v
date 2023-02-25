`include "params.vh"
`default_nettype none
module top(
    // CLOCK & RESETN
    input wire CLK100MHZ,
    input wire CPU_RESETN,
    output wire [15:0] LED,

    // UART
    input wire UART_TXD_IN,
    output wire UART_RXD_OUT,

    // DDR2
    output wire [12:0] ddr2_addr,
    output wire [2:0] ddr2_ba,
    output wire ddr2_cas_n,
    output wire [0:0] ddr2_ck_n,
    output wire [0:0] ddr2_ck_p,
    output wire [0:0] ddr2_cke,
    output wire ddr2_ras_n,
    output wire ddr2_we_n,
    inout  wire [15:0] ddr2_dq,
    inout  wire [1:0] ddr2_dqs_n,
    inout  wire [1:0] ddr2_dqs_p,
    output wire [0:0] ddr2_cs_n,
    output wire [1:0] ddr2_dm,
    output wire [0:0] ddr2_odt
);

    wire io_stall, stall, flush, output_busy, mem_busy;
    wire mem_write, is_load, is_in, is_out, is_input;
    wire [17:0] pc;
    wire [31:0] inst;
    wire [31:0] calc_result, write_data;

    wire [31:0] read_data, mem_data, input_data;
    wire data_ready, mem_data_ready, input_data_ready;
    wire [31:0] rdata_buf, inst_rdata_buf, input_rdata_buf; 
    wire rdata_buf_ready, inst_rdata_buf_ready, input_rdata_buf_ready;
    wire [7:0]output_data, sdata;
    wire output_valid, sdata_valid;
    wire [31:0] data_a, data_wd;
    wire data_we;
    wire data_req, input_req;

    assign {data_a, data_wd, data_we} = (is_out) ? {32'b0, 32'b0, 1'b0} : {calc_result, write_data, mem_write};
    assign {output_data, output_valid} = (is_out) ? {write_data[7:0], 1'b1} : {8'b0, 1'b0};

    assign {inst_rdata_buf, inst_rdata_buf_ready} = (is_input) ? {32'b0, 1'b0} : {rdata_buf, rdata_buf_ready};
    assign {input_rdata_buf, input_rdata_buf_ready} = (is_input) ? {rdata_buf, rdata_buf_ready} : {32'b0, 1'b0};

    assign read_data = (is_in) ? input_data : mem_data;
    assign data_ready = (is_in) ? input_data_ready : mem_data_ready;
    assign data_req = (is_in) ? 0 : (is_load || mem_write);
    assign input_req = (is_in) ? 1 : 0;

    assign LED[15:3] = pc;

    // clock
    wire mig_clk;
    wire cpu_clk;
    wire clk, rstn;
    assign clk = cpu_clk;
    assign rstn = CPU_RESETN;
    clk_wiz_0 clk_gen (
        .clk_in1(CLK100MHZ),
        .resetn(CPU_RESETN),
        .clk_out1(mig_clk),
        .clk_out2(cpu_clk)
        //.locked(rstn)
    );

    Core core(
        .clk(clk),
        .rstn(rstn),
        .io_stall(io_stall),
        .inst_stall(stall),
        .flush(flush),
        .pcF(pc),
        .instD(inst),
        .read_dataM(read_data),
        .data_ready(data_ready),
        .calc_resultM(calc_result),
        .write_dataM(write_data),
        .mem_writeM(mem_write),
        .is_loadM(is_load),
        .is_inM(is_in),
        .is_outM(is_out)
    );

    InstMem instmem(
        .clk(clk),
        .rstn(rstn),
        .a(pc),
        .wd(inst_rdata_buf),
        .we(inst_rdata_buf_ready),
        .stall(stall),
        .flush(flush),
        .inst(inst)
    );

    IO_fsm io_fsm (
        .clk(clk),
        .rstn(rstn),
        .rxd(UART_TXD_IN),
        .sdata_buf(sdata),
        .sdata_valid(sdata_valid),
        .txd(UART_RXD_OUT),
        .rdata_buf(rdata_buf),
        .rdata_buf_ready(rdata_buf_ready),
        .is_input(is_input),
        .io_stall(io_stall),
        .output_busy(output_busy),
        .led(LED[2:0])
    );

    InputBuf input_buf(
        .clk(clk),
        .rstn(rstn),
        .req(input_req),
        .wd(input_rdata_buf),
        .we(input_rdata_buf_ready),
        .input_data(input_data),
        .input_data_ready(input_data_ready)
    );

    OutputBuf output_buf(
        .clk(clk),
        .rstn(rstn),
        .output_data(output_data),
        .output_valid(output_valid),
        .output_busy(output_busy),
        .sdata(sdata),
        .sdata_valid(sdata_valid)
    );

    // DataMem datamem (
    //     .clk(clk),
    //     .rstn(rstn),
    //     .a({data_a[29:0], 2'b0}),
    //     .req(data_req),
    //     .wd(data_wd),
    //     .we(data_we),
    //     .rd(mem_data),
    //     .ready(mem_data_ready)
    // );

    memocon memocon(
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
        ddr2_odt,
        // CLOCK & RESETN
        mig_clk,  
        clk,
        rstn,
        // CPU -> cache のrequest
        {data_a[29:0], 2'b0},
        data_wd,
        data_we,  // read: 0, write: 1
        data_req,
        // cache -> CPU のresponse
        mem_data,
        mem_data_ready,
        mem_busy
    );

endmodule
`default_nettype wire