module timer (
    input clock, reset,
    output reg [5:0] seconds, minutes
);

reg [25:0] i = 0;

always @(posedge clock or posedge reset) begin
    if (reset) begin
        i <= 0;
        seconds <= 0;
        minutes <= 0;
    end else begin
        if (i == 49_999_999) begin
            i <= 0;
            if (seconds == 59) begin
                seconds <= 0;
                minutes <= minutes + 1;
            end else seconds <= seconds + 1;
        end else i <= i + 1;
    end
end

endmodule