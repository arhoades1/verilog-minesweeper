module two_decimal_vals (
    input  [7:0] value,
    output [6:0] HEX0,
    output [6:0] HEX1
);

    reg [3:0] digit0, digit1;

    always @(*) begin
        digit0 = value % 10;
        digit1 = (value / 10) % 10;
    end

    seven_segment u0 (.digit(digit0), .HEX(HEX0));
    seven_segment u1 (.digit(digit1), .HEX(HEX1));
	 
endmodule