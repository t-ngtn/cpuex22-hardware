`default_nettype none

(* use_dsp = "yes" *) module Finv (
    input wire [22:0] x,
    output reg [22:0] y,
    input wire clk,
    input wire rstn
);

    (* ram_style = "BLOCK" *) reg [35:0] finv_ram [1023:0];

    initial begin
        $readmemb("C:/Users/tansei/Desktop/cpu/fpu/pipeline/finv.dat", finv_ram);
    end

// stage 1
    // 傾きaと切片bの取得
    wire [9:0] index;
    wire [12:0] d;
    assign {index, d} = x;

// stage 2
    reg [35:0] ab_st2;
    wire [12:0] a_st2;
    wire [22:0] b_st2;
    reg [12:0] d_st2;
    always @(posedge clk) begin
        ab_st2 <= finv_ram[index];
        d_st2 <= d;
    end
    assign {a_st2, b_st2} = ab_st2;

    // a * d
    wire [25:0] ad1;
    assign ad1 = a_st2 * d_st2;

    wire [22:0] ad2;
    assign ad2 = {9'b0, ad1[25:12]};

// stage 3
    // b - a * d
    always @(posedge clk) begin
        y <= b_st2 - ad2;    
    end

endmodule

`default_nettype wire