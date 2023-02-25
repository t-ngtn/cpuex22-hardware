`default_nettype none

module InputBuf(
    input wire clk,
    input wire rstn,
    input wire req,
    input wire [31:0] wd,
    input wire we,
    output reg [31:0] input_data,
    output reg input_data_ready
    );
    
    (* ram_style = "BLOCK" *) reg [31:0] input_ram [500:0];
    reg [8:0] ok_idx;
    reg [8:0] now_idx;

    always_ff @( posedge clk ) begin
        if (~rstn) begin
            ok_idx <= 0;
            now_idx <= 0;
            input_data_ready <= 0;
        end
        
        if (we) begin
            input_ram[ok_idx] <= wd;
            ok_idx <= ok_idx + 1;
        end

        if (req && (now_idx < ok_idx)) begin 
            input_data <= input_ram[now_idx];
            input_data_ready <= 1;
        end

        if (input_data_ready) begin
            input_data_ready <= 0;
            now_idx <= now_idx + 1;
        end
    end

endmodule // InputBuf
`default_nettype wire