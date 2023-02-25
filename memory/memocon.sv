module memocon (
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
    output wire [0:0] ddr2_odt,
    // CLOCK & RESETN
    input logic mig_clk,  
    input logic cpu_clk,
    input logic rstn,
    // CPU -> cache のrequest
    input wire [31:0] cpu_req_addr,
    input wire [31:0] cpu_req_data,
    input wire cpu_req_rw,  // read: 0, write: 1
    input wire cpu_req_valid,
    // cache -> CPU のresponse
    output wire [31:0] cpu_res_data,
    output wire cpu_res_ready,

    output wire busy
);

    master_fifo master_fifo ();

    // メモリ -> cache のresponse
    wire [127:0] mem_res_data;
    wire mem_res_ready;

    // cache -> メモリ のrequest
    wire [31:0] mem_req_addr;
    wire [127:0] mem_req_data;
    wire mem_req_rw;  // read: 0; write: 1
    wire mem_req_valid;

    assign master_fifo.clk = cpu_clk;
    assign master_fifo.rsp_rdy = 1'b1;
    assign master_fifo.req.cmd = ~mem_req_rw;
    assign master_fifo.req.addr = {mem_req_addr[26:4], 4'b0};
    assign master_fifo.req.data = mem_req_data;
    assign master_fifo.req_en = mem_req_valid;
    assign mem_res_data = master_fifo.rsp.data;
    assign mem_res_ready = master_fifo.rsp_en;
    
    dram_top dram_top(
        .*
    );

    SACache4_fsm cache_fsm(
        .clk(cpu_clk),
        .rstn(rstn),
        .*
    );

endmodule