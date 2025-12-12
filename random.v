module random (
    input clock,
    input reset,
    input [4:0] range,
    input [7:0] seed,
    output reg [4:0] out
);

reg [7:0] lfsr = 8'hA5;
wire feedback = lfsr[7] ^ lfsr[5] ^ lfsr[4] ^ lfsr[3];

always @(posedge clock or posedge reset) begin
    lfsr <= reset ? seed : {lfsr[6:0], feedback};
end

always @(*) begin
    out = range == 0 ? 0 : lfsr % (range + 1);
end

endmodule
