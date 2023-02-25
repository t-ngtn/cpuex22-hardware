`include "params.vh"

`default_nettype none
module InstMem(
    input wire [11:0] addr,
    output wire [31:0] inst
    );

    (* ram_style = "BLOCK" *) reg [7:0] ram [4095:0];

    initial begin
        $readmemb("C:/Users/tansei/Desktop/cpu/core/fibcore/inst.dat", ram);
    end

    assign inst = {ram[addr], ram[addr+1], ram[addr+2], ram[addr+3]};

endmodule // InstMem
`default_nettype wire