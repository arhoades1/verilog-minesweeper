module keyDebouncer (
    input clock,
    input reset,
    input [3:0] keyIn,
    output reg [3:0] keyOut
);

reg [3:0] previousKey;
wire three = previousKey[3] & keyIn[3];
wire two   = previousKey[2] & keyIn[2];
wire one   = previousKey[1] & keyIn[1];
wire zero  = previousKey[0] & keyIn[0];

always @(posedge clock or posedge reset) begin
    if (reset) begin
        previousKey <= 4'b0000;
    end else begin
        previousKey <= ~keyIn;
        
        keyOut[3] <= three ? 1 : 0;
        keyOut[2] <= two   ? 1 : 0;
        keyOut[1] <= one   ? 1 : 0;
        keyOut[0] <= zero  ? 1 : 0;
    end
end

endmodule