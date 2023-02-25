`default_nettype none

(* use_dsp = "yes" *) module Mul23(input wire [22:0] m1,
             input wire [22:0] m2,
            output wire [25:0] my,
            input wire clk,
            input wire rstn);

// stage 1
    // m1とm2を上位12bitと下位11bitに分ける
    wire [11:0] m1h;
    wire [10:0] m1l;
    assign {m1h, m1l} = m1;

    wire [11:0] m2h;
    wire [10:0] m2l;
    assign {m2h, m2l} = m2;

    // 3つの積を計算する
    wire [25:0] hh;
    assign hh = {1'b1, m1h} * {1'b1, m2h};

    wire [23:0] hl;
    assign hl = {1'b1, m1h} * m2l;

    wire [23:0] lh;
    assign lh = m1l * {1'b1, m2h};

// stage 2
    reg [25:0] hh_st2;
    reg [23:0] hl_st2;
    reg [23:0] lh_st2;
    always @(posedge clk) begin
        hh_st2 <= hh;
        hl_st2 <= hl;
        lh_st2 <= lh;
    end

    // 3つの積を足し合わせる
    assign my = hh_st2 + {13'b0, hl_st2[23:11]} + {13'b0, lh_st2[23:11]} + 26'd1;

endmodule

`default_nettype wire