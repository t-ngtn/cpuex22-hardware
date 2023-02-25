`default_nettype none

module SACache4_data #(
    parameter TAG   = 16,
    parameter INDEX = 12,
    parameter LINE  = 4096  // 2 ** INDEX
)(
    input wire clk,

    // request
    input wire [INDEX-1:0] index,
    input wire we,

    // キャッシュへの書き出し
    input wire [127:0] data_w,

    // キャッシュからの読み出し
    output reg [127:0] data_r
);

    (* ram_style = "BLOCK" *) reg [127:0] data_mem [LINE-1:0];
    integer i;

    initial begin
        for (i=0; i<LINE; i = i+1) begin
            data_mem[i] = 0;
        end
    end

    always_ff @(posedge clk) begin : data
        if (we) begin
            data_mem[index] <= data_w;
            data_r <= data_w;
        end
        else begin
            data_r <= data_mem[index];
        end
    end

endmodule // SACache4_data

module SACache4_tag #(
    parameter TAG   = 16,
    parameter INDEX = 12,
    parameter LINE  = 4096  // 2 ** INDEX
)(
    input wire clk,
    input wire rstn,
    
    // request
    input wire [INDEX-1:0] index,
    input wire we,

    // タグの書き出し
    input wire accessed_w,
    input wire valid_w,
    input wire dirty_w,
    input wire [TAG-1:0] tag_w,

    // タグの読み出し
    output wire accessed_r,
    output wire valid_r,
    output wire dirty_r,
    output wire [TAG-1:0] tag_r
);

    (* ram_style = "BLOCK" *) reg [TAG+2:0] tag_mem [LINE-1:0];
    integer i;

    initial begin
        for (i=0; i<LINE; i = i+1) begin
            tag_mem[i] = 0;
        end
    end

    wire [TAG+2:0] tag_info_w;
    reg [TAG+2:0] tag_info_r;
    assign tag_info_w = {accessed_w, valid_w, dirty_w, tag_w};
    assign {accessed_r, valid_r, dirty_r, tag_r} = tag_info_r;
    
    always_ff @( posedge clk ) begin : tag
        if (~rstn) begin
            tag_info_r <= 0;
        end 
        else if (we) begin
            tag_mem[index] <= tag_info_w;
            tag_info_r <= tag_info_w;
        end
        else begin
            tag_info_r <= tag_mem[index];
        end
    end

endmodule // SACache4_tag

module SACache4_fsm #(
    parameter TAG   = 16,
    parameter INDEX = 12
)(
    input wire clk,
    input wire rstn,

    // CPU -> cache のrequest
    input wire [31:0] cpu_req_addr,
    input wire [31:0] cpu_req_data,
    input wire cpu_req_rw,  // read: 0, write: 1
    input wire cpu_req_valid, 

    // メモリ -> cache のresponse
    input wire [127:0] mem_res_data,
    input wire mem_res_ready,

    // cache -> メモリ のrequest
    output wire [31:0] mem_req_addr,
    output wire [127:0] mem_req_data,
    output wire mem_req_rw,  // read: 0, write: 1
    output wire mem_req_valid,

    // cache -> CPU のresponse
    output wire [31:0] cpu_res_data,
    output wire cpu_res_ready,

    // busy bit
    output wire busy
);
    localparam idle        = 3'b000;
    localparam compare_tag = 3'b001;
    localparam allocate    = 3'b010;
    localparam write_back  = 3'b011;
    localparam wait_read   = 3'b100;

    logic [2:0] vstate;
    logic [2:0] rstate = idle;


    // タグ関連のinput/output
    // request
    logic [INDEX-1:0] tag_index;
    logic tag_we0, tag_we1, tag_we2, tag_we3;
    // タグの書き出し
    logic accessed_w0, accessed_w1, accessed_w2, accessed_w3;
    logic valid_w0, valid_w1, valid_w2, valid_w3;
    logic dirty_w0, dirty_w1, dirty_w2, dirty_w3;
    logic [TAG-1:0] tag_w0, tag_w1, tag_w2, tag_w3;

    // タグの読み出し
    logic accessed_r0, accessed_r1, accessed_r2, accessed_r3;
    logic valid_r0, valid_r1, valid_r2, valid_r3;
    logic dirty_r0, dirty_r1, dirty_r2, dirty_r3;
    logic [TAG-1:0] tag_r0, tag_r1, tag_r2, tag_r3;

    SACache4_tag sacache_tag0 (clk, rstn, tag_index, tag_we0, accessed_w0, valid_w0, dirty_w0, tag_w0, accessed_r0, valid_r0, dirty_r0, tag_r0);
    SACache4_tag sacache_tag1 (clk, rstn, tag_index, tag_we1, accessed_w1, valid_w1, dirty_w1, tag_w1, accessed_r1, valid_r1, dirty_r1, tag_r1);
    SACache4_tag sacache_tag2 (clk, rstn, tag_index, tag_we2, accessed_w2, valid_w2, dirty_w2, tag_w2, accessed_r2, valid_r2, dirty_r2, tag_r2);
    SACache4_tag sacache_tag3 (clk, rstn, tag_index, tag_we3, accessed_w3, valid_w3, dirty_w3, tag_w3, accessed_r3, valid_r3, dirty_r3, tag_r3);

    // cache data関連のinput/output
    // request
    logic [INDEX-1:0] data_index;  
    logic data_we0, data_we1, data_we2, data_we3;

    // キャッシュへの書き出し
    logic [127:0] data_w0, data_w1, data_w2, data_w3;

    // キャッシュからの読み出し
    logic [127:0] data_r0, data_r1, data_r2, data_r3;

    SACache4_data sacache_data0 (clk, data_index, data_we0, data_w0, data_r0);
    SACache4_data sacache_data1 (clk, data_index, data_we1, data_w1, data_r1);
    SACache4_data sacache_data2 (clk, data_index, data_we2, data_w2, data_r2);
    SACache4_data sacache_data3 (clk, data_index, data_we3, data_w3, data_r3);

    // CPUへのresponseの一時変数
    logic [31:0] v_cpu_res_data;
    logic v_cpu_res_ready;
    assign cpu_res_data = v_cpu_res_data;
    assign cpu_res_ready = v_cpu_res_ready;

    // memoryへのrequestの一時変数
    logic [31:0] v_mem_req_addr;
    logic [127:0] v_mem_req_data;
    logic v_mem_req_rw;  // read: 0; write: 1
    logic v_mem_req_valid;
    assign mem_req_addr = v_mem_req_addr;
    assign mem_req_data = v_mem_req_data;
    assign mem_req_rw = v_mem_req_rw;
    assign mem_req_valid = v_mem_req_valid;

    logic v_busy;
    assign busy = v_busy;

    logic [1:0] use_table_num;

    logic r_wait, v_wait;

    always_comb begin
        // defaultの値設定
        v_wait = 0;
        v_busy = 0;
        vstate = rstate;
        v_cpu_res_data = 0;
        v_cpu_res_ready = 0;
        accessed_w0 = 1'b0; accessed_w1 = 1'b0; accessed_w2 = 1'b0; accessed_w3 = 1'b0;
        valid_w0 = 1'b0; valid_w1 = 1'b0; valid_w2 = 1'b0; valid_w3 = 1'b0;
        dirty_w0 = 1'b0; dirty_w1 = 1'b0; dirty_w2 = 1'b0; dirty_w3 = 1'b0;
        tag_w0 = 0; tag_w1 = 0; tag_w2 = 0; tag_w3 = 0;

        tag_index = cpu_req_addr[4+INDEX-1:4];
        tag_we0 = 0; tag_we1 = 0; tag_we2 = 0; tag_we3 = 0;

        data_index = cpu_req_addr[4+INDEX-1:4];
        data_we0 = 0; data_we1 = 0; data_we2 = 0; data_we3 = 0;

        data_w0 = data_r0; data_w1 = data_r1; data_w2 = data_r2; data_w3 = data_r3;

        case (cpu_req_addr[3:2])
            2'b00: 
                begin
                    data_w0[31:0]   = cpu_req_data;
                    data_w1[31:0]   = cpu_req_data;
                    data_w2[31:0]   = cpu_req_data;
                    data_w3[31:0]   = cpu_req_data;
                end
            2'b01: 
                begin
                    data_w0[63:32]  = cpu_req_data;
                    data_w1[63:32]  = cpu_req_data;
                    data_w2[63:32]  = cpu_req_data;
                    data_w3[63:32]  = cpu_req_data;
                end
            2'b10: 
                begin
                    data_w0[95:64]  = cpu_req_data;
                    data_w1[95:64]  = cpu_req_data;
                    data_w2[95:64]  = cpu_req_data;
                    data_w3[95:64]  = cpu_req_data;
                end
            2'b11: 
                begin
                    data_w0[127:96] = cpu_req_data;
                    data_w1[127:96] = cpu_req_data;
                    data_w2[127:96] = cpu_req_data;
                    data_w3[127:96] = cpu_req_data;
                end
        endcase

        case (cpu_req_addr[3:2])
            2'b00: 
                case (use_table_num)
                    2'b00: v_cpu_res_data = data_r0[31:0];
                    2'b01: v_cpu_res_data = data_r1[31:0];
                    2'b10: v_cpu_res_data = data_r2[31:0];
                    2'b11: v_cpu_res_data = data_r3[31:0];
                endcase 
            2'b01: 
                case (use_table_num)
                    2'b00: v_cpu_res_data = data_r0[63:32];
                    2'b01: v_cpu_res_data = data_r1[63:32];
                    2'b10: v_cpu_res_data = data_r2[63:32];
                    2'b11: v_cpu_res_data = data_r3[63:32];
                endcase 
            2'b10:
                case (use_table_num)
                    2'b00: v_cpu_res_data = data_r0[95:64];
                    2'b01: v_cpu_res_data = data_r1[95:64];
                    2'b10: v_cpu_res_data = data_r2[95:64];
                    2'b11: v_cpu_res_data = data_r3[95:64];
                endcase 
            2'b11: 
                case (use_table_num)
                    2'b00: v_cpu_res_data = data_r0[127:96];
                    2'b01: v_cpu_res_data = data_r1[127:96];
                    2'b10: v_cpu_res_data = data_r2[127:96];
                    2'b11: v_cpu_res_data = data_r3[127:96];
                endcase 
        endcase

        v_mem_req_addr = cpu_req_addr;
        case (use_table_num)
            2'b00: v_mem_req_data = data_r0;
            2'b01: v_mem_req_data = data_r1;
            2'b10: v_mem_req_data = data_r2;
            2'b11: v_mem_req_data = data_r3;
        endcase
        v_mem_req_rw = 0;
        v_mem_req_valid = 0;

        case (rstate)
            // 待ち状態
            idle: begin
                if (cpu_req_valid) begin
                    vstate = compare_tag;
                    v_busy = 1;
                end
            end

            // タグの比較
            compare_tag: begin
                // Hit
                if (cpu_req_addr[31:32-TAG] == tag_r0 && valid_r0) begin
                    if (cpu_req_rw) begin
                        tag_we0 = 1; data_we0 = 1; tag_w0 = tag_r0;
                        accessed_w0 = 1; valid_w0 = 1; dirty_w0 = 1;
                    end
                    accessed_w0 = 1;
                    use_table_num = 0;
                    vstate = wait_read; 
                end
                else if (cpu_req_addr[31:32-TAG] == tag_r1 && valid_r1 ) begin
                    if (cpu_req_rw) begin
                        tag_we1 = 1; data_we1 = 1; tag_w1 = tag_r1;
                        accessed_w1 = 1; valid_w1 = 1; dirty_w1 = 1;
                    end
                    accessed_w1 = 1;
                    use_table_num = 1;
                    vstate = wait_read;     
                end
                else if (cpu_req_addr[31:32-TAG] == tag_r2 && valid_r2 ) begin
                    if (cpu_req_rw) begin
                        tag_we2 = 1; data_we2 = 1; tag_w2 = tag_r2;
                        accessed_w2 = 1; valid_w2 = 1; dirty_w2 = 1;
                    end
                    accessed_w2 = 1;
                    use_table_num = 2;
                    vstate = wait_read;     
                end 
                else if (cpu_req_addr[31:32-TAG] == tag_r3 && valid_r3 ) begin
                    if (cpu_req_rw) begin
                        tag_we3 = 1; data_we3 = 1; tag_w3 = tag_r3;
                        accessed_w3 = 1; valid_w3 = 1; dirty_w3 = 1;
                    end
                    accessed_w3 = 1;
                    use_table_num = 3;
                    vstate = wait_read;     
                end
                // Miss
                else begin
                    if (~accessed_r0) begin
                        use_table_num = 0;
                        // 新しいタグの生成
                        tag_we0 = 1; accessed_w0 = 1; valid_w0 = 1;
                        dirty_w0 = cpu_req_rw; tag_w0 = cpu_req_addr[31:32-TAG];
                        // メモリへのrequest生成
                        v_mem_req_valid = 1; v_busy = 1;
                        if (valid_r0 == 1'b0 || dirty_r0 == 1'b0) begin
                            vstate = allocate;
                        end else begin
                            v_mem_req_addr = {tag_r0, cpu_req_addr[4+INDEX-1:0]};
                            v_mem_req_data = data_r0;
                            v_mem_req_rw = 1; vstate = write_back;
                        end
                    end 
                    else if (~accessed_r1) begin
                        use_table_num = 1;
                        // 新しいタグの生成
                        tag_we1 = 1; accessed_w1 = 1; valid_w1 = 1;
                        dirty_w1 = cpu_req_rw; tag_w1 = cpu_req_addr[31:32-TAG];
                        // メモリへのrequest生成
                        v_mem_req_valid = 1; v_busy = 1;
                        if (valid_r1 == 1'b0 || dirty_r1 == 1'b0) begin
                            vstate = allocate;
                        end else begin
                            v_mem_req_addr = {tag_r1, cpu_req_addr[4+INDEX-1:0]};
                            v_mem_req_data = data_r1;
                            v_mem_req_rw = 1; vstate = write_back;
                        end
                    end 
                    else if (~accessed_r2) begin
                        use_table_num = 2;
                        // 新しいタグの生成
                        tag_we2 = 1; accessed_w2 = 1; valid_w2 = 1;
                        dirty_w2 = cpu_req_rw; tag_w2 = cpu_req_addr[31:32-TAG];
                        // メモリへのrequest生成
                        v_mem_req_valid = 1; v_busy = 1;
                        if (valid_r2 == 1'b0 || dirty_r2 == 1'b0) begin
                            vstate = allocate;
                        end else begin
                            v_mem_req_addr = {tag_r2, cpu_req_addr[4+INDEX-1:0]};
                            v_mem_req_data = data_r2;
                            v_mem_req_rw = 1; vstate = write_back;
                        end
                    end 
                    else if (~accessed_r3) begin
                        use_table_num = 3;
                        // 新しいタグの生成
                        tag_we3 = 1; accessed_w3 = 1; valid_w3 = 1;
                        dirty_w3 = cpu_req_rw; tag_w3 = cpu_req_addr[31:32-TAG];
                        // メモリへのrequest生成
                        v_mem_req_valid = 1; v_busy = 1;
                        if (valid_r3 == 1'b0 || dirty_r3 == 1'b0) begin
                            vstate = allocate;
                        end else begin
                            v_mem_req_addr = {tag_r3, cpu_req_addr[4+INDEX-1:0]};
                            v_mem_req_data = data_r3;
                            v_mem_req_rw = 1; vstate = write_back;
                        end
                    end
                end
            end 

            // 新しいキャッシュラインの生成を待つ
            allocate: begin
                v_busy = 1;
                if (mem_res_ready) begin
                    vstate = compare_tag;
                    data_w0 = mem_res_data;
                    data_w1 = mem_res_data;
                    data_w2 = mem_res_data;
                    data_w3 = mem_res_data;
                    case (use_table_num)
                        2'b00: data_we0 = 1;
                        2'b01: data_we1 = 1;
                        2'b10: data_we2 = 1;
                        2'b11: data_we3 = 1;
                    endcase
                end
            end

            // dirtyなキャッシュラインの書き戻しを待つ
            write_back: begin
                v_busy = 1;
                v_mem_req_valid = 1;   
                v_mem_req_rw = 0;
                vstate = allocate;
            end

            // BRAMの遅延待ち & ここでaccessedがすべて1なら0にする作業をする
            wait_read: begin
                if (accessed_r0 && accessed_r1 && accessed_r2 && accessed_r3) begin
                    accessed_w0 = 0; accessed_w1 = 0; accessed_w2 = 0; accessed_w3 = 0;
                    valid_w0 = valid_r0; valid_w1 = valid_r1; valid_w2 = valid_r2; valid_w3 = valid_r3;
                    dirty_w0 = dirty_r0; dirty_w1 = dirty_r1; dirty_w2 = dirty_r2; dirty_w3 = dirty_r3;
                    tag_w0 = tag_r0; tag_w1 = tag_r1; tag_w2 = tag_r2; tag_w3 = tag_r3;
                    tag_we0 = 1; tag_we1 = 1; tag_we2 = 1; tag_we3 = 1;
                end
                v_cpu_res_ready = 1;
                vstate = idle;
                v_busy = 0;
            end
        endcase
    end

    always_ff @( posedge clk ) begin
        if (~rstn) begin
            rstate <= idle;
        end else begin
            rstate <= vstate;
        end        
    end

endmodule
`default_nettype wire 