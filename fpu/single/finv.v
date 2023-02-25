`default_nettype none

module Finv(input wire [22:0] x,
           output wire [22:0] y);

    (* ram_style = "BLOCK" *) reg [35:0] ram [1023:0];

    initial begin
        $readmemb("C:/Users/tansei/Desktop/cpu/fpu/single/finv.dat", ram);
    end

    // 傾きaと切片bの取得
    wire [9:0] index;
    wire [12:0] d;
    assign {index, d} = x;

    wire [12:0] a;
    wire [22:0] b;
    assign {a, b} = ram[index];

    // a * d
    wire [25:0] ad1;
    assign ad1 = a * d;

    wire [22:0] ad2;
    assign ad2 = {9'b0, ad1[25:12]};

    // b - a * d
    assign y = b - ad2;

endmodule

`default_nettype wire