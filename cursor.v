module cursor (
    input clock, reset,
    input [4:0] gridWidth, gridHeight,
    input [3:0] KEY,
    output reg [3:0] cursorX, cursorY
);

// WIRES //
// cursor mappings
wire left  = KEY[3];
wire up    = KEY[2];
wire down  = KEY[1];
wire right = KEY[0];

// LOGIC //
always @(posedge clock or posedge reset) begin
    if (reset) begin
        cursorX <= 0;
        cursorY <= 0;
    end else begin
        if (left) cursorX <= cursorX == 0 ? 0 : cursorX - 1;
        if (up) cursorY <= cursorY == gridHeight ? gridHeight : cursorY + 1;
        if (down) cursorY <= cursorY == 0 ? 0 : cursorY - 1;
        if (right) cursorX <= cursorX == gridWidth ? gridWidth : cursorX + 1;
    end
end

endmodule