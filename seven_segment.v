module seven_segment(
    input [3:0] digit,
    output reg [6:0] HEX
);
    always @(*) begin
        case (digit)
            4'd0: HEX = 7'b1000000;
            4'd1: HEX = 7'b1111001;
            4'd2: HEX = 7'b0100100;
            4'd3: HEX = 7'b0110000;
            4'd4: HEX = 7'b0011001;
            4'd5: HEX = 7'b0010010;
            4'd6: HEX = 7'b0000010;
            4'd7: HEX = 7'b1111000;
            4'd8: HEX = 7'b0000000;
            4'd9: HEX = 7'b0010000;
            default: HEX = 7'b1111111; // Blank
        endcase
    end
endmodule

// HEX out - rewire DE1
//  ---0---
// |       |
// 5       1
// |       |
//  ---6---
// |       |
// 4       2
// |       |
//  ---3---
