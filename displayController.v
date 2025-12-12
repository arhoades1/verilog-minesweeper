module displayController (
  	input clock,
	input [3:0] gridWidth,
	input [3:0] gridHeight,
	input [6:0] gridElement,
	input [3:0] userCursorX,
	input [3:0] userCursorY,
	output wire [3:0] gridCursorX,
	output wire [3:0] gridCursorY,

	output VGA_BLANK_N,
	output reg [7:0] VGA_B,
	output VGA_CLK,
	output reg [7:0] VGA_G,
	output VGA_HS,
	output reg [7:0] VGA_R,
	output VGA_SYNC_N,
	output VGA_VS
);

wire active_pixels; // is on when we're in the active draw space
wire [9:0] x; // current x
wire [9:0] flippedY; // upside down y value from VGA Driver
wire [9:0] y = SCREEN_HEIGHT - flippedY - 1; // current y

vga_driver the_vga(
	.clk(clock),
	.rst(1'b1),
	.vga_clk(VGA_CLK),
	.hsync(VGA_HS),
	.vsync(VGA_VS),
	.active_pixels(active_pixels),
	.xPixel(x),
	.yPixel(flippedY),
	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_SYNC_N(VGA_SYNC_N)
);

always @(*) begin
	{VGA_R, VGA_G, VGA_B} = vga_color;
end

reg [23:0] vga_color;


localparam GRID_PIXEL_SIZE = 30;
localparam SCREEN_WIDTH = 640;
localparam SCREEN_HEIGHT = 480;
localparam CELL_OUTLINE_COLOR = 24'h000000; // black
localparam CELL_CURSOR_COLOR = 24'hFF0000; // red
localparam GRID_BACKGROUND_COLOR = 24'hFFFFFF; // white
localparam BACKGROUND_COLOR = 24'h24718B; // DevOps blue

// Colors
localparam BLACK = 24'h000000;
localparam RED = 24'hff2600;
localparam ORANGE = 24'hff9300;
localparam YELLOW = 24'hfffb00;
localparam GREEN = 24'h00f900;
localparam CYAN = 24'h00fdff;
localparam BLUE = 24'h0433ff;
localparam PURPLE = 24'h942192;
localparam PINK = 24'hff40ff;
localparam WHITE = 24'hffffff;
localparam GREY = 24'h808080;

// Numbers
localparam ONE   = 15'b110010010010111;
localparam TWO   = 15'b111001111100111;
localparam THREE = 15'b111001111001111;
localparam FOUR  = 15'b101101111001001;
localparam FIVE  = 15'b111100111001111;
localparam SIX   = 15'b111100111101111;
localparam SEVEN = 15'b111001001001001;
localparam EIGHT = 15'b111101111101111;
localparam NINE  = 15'b111101111001111;
// 00 - 01 - 02
// |    |    |
// 03 - 04 - 05
// |    |    |
// 06 - 07 - 08
// |    |    |
// 09 - 10 - 11
// |    |    |
// 12 - 13 - 14

// Center the grid on the screen
wire [8:0] gridPixelWidth = (gridWidth + 1) * GRID_PIXEL_SIZE;
wire [8:0] gridPixelHeight = (gridHeight + 1) * GRID_PIXEL_SIZE;
wire [8:0] gridStartX = (SCREEN_WIDTH - gridPixelWidth) / 2;
wire [8:0] gridStartY = (SCREEN_HEIGHT - gridPixelHeight) / 2;
wire isGridRegion = (x >= gridStartX && x < gridStartX + gridPixelWidth && y >= gridStartY && y < gridStartY + gridPixelHeight);

// Calculate grid cursor
assign gridCursorX = (x - gridStartX) / GRID_PIXEL_SIZE;
assign gridCursorY = (y - gridStartY) / GRID_PIXEL_SIZE;

// Calculate cell cursor
wire [5:0] cellCursorX = (x - gridStartX) % GRID_PIXEL_SIZE;
wire [5:0] cellCursorY = (y - gridStartY) % GRID_PIXEL_SIZE;
wire [3:0] halfScaleCursorX = (cellCursorX + 1) / 2;
wire [3:0] halfScaleCursorY = (cellCursorY + 1) / 2;
wire [2:0] quarterScaleCursorX = (cellCursorX + 2) / 4;
wire [2:0] quarterScaleCursorY = (cellCursorY + 2) / 4;
wire [1:0] digitCursorX = 5 - quarterScaleCursorX;
wire [2:0] digitCursorY = quarterScaleCursorY - 2;
wire [3:0] digitCursor = digitCursorY * 3 + digitCursorX;

// Calculate cell outline
wire isOutline = (isGridRegion && ((cellCursorX == 0 || cellCursorX == GRID_PIXEL_SIZE - 1) || (cellCursorY == 0 || cellCursorY == GRID_PIXEL_SIZE - 1)));

// Calculate cursor outline
wire isCursorOutline = (isOutline && (userCursorX == gridCursorX && userCursorY == gridCursorY));

// handle gridElement
wire isUncovered = gridElement[0];
wire isBomb = gridElement[1];
wire isFlagged = gridElement[2];
wire [3:0] bombsNear = gridElement[6:3];
wire isExploded = (gridElement == 7'b1111111);

always @(*) begin
    if (!active_pixels) vga_color = BLACK; // black during blanking
    else begin
		if (isCursorOutline) vga_color = CELL_CURSOR_COLOR;
		else if (isOutline) vga_color = CELL_OUTLINE_COLOR;
		else if (isGridRegion) begin
			if (isUncovered) begin
				if (isBomb) begin
					if (   (halfScaleCursorX > 2 && halfScaleCursorX < 13 && halfScaleCursorY > 6 && halfScaleCursorY <  9)
						|| (halfScaleCursorX > 3 && halfScaleCursorX < 12 && halfScaleCursorY > 5 && halfScaleCursorY < 10)
						|| (halfScaleCursorX > 4 && halfScaleCursorX < 11 && halfScaleCursorY > 4 && halfScaleCursorY < 11)
						|| (halfScaleCursorX > 5 && halfScaleCursorX < 10 && halfScaleCursorY > 3 && halfScaleCursorY < 12)
						|| (halfScaleCursorX > 6 && halfScaleCursorX <  9 && halfScaleCursorY > 2 && halfScaleCursorY < 13)
					) vga_color = BLACK;
					else vga_color = isExploded ? RED : GRID_BACKGROUND_COLOR;
				end else begin
					if (quarterScaleCursorY > 1 && quarterScaleCursorY < 7 && quarterScaleCursorX > 2 && quarterScaleCursorX < 6) begin
						case (bombsNear)
							0: vga_color =                              GRID_BACKGROUND_COLOR;
							1: vga_color = ONE   [digitCursor] ? CYAN : GRID_BACKGROUND_COLOR;
							2: vga_color = TWO   [digitCursor] ? GREEN : GRID_BACKGROUND_COLOR;
							3: vga_color = THREE [digitCursor] ? BLUE : GRID_BACKGROUND_COLOR;
							4: vga_color = FOUR  [digitCursor] ? RED : GRID_BACKGROUND_COLOR;
							5: vga_color = FIVE  [digitCursor] ? PURPLE : GRID_BACKGROUND_COLOR;
							6: vga_color = SIX   [digitCursor] ? YELLOW : GRID_BACKGROUND_COLOR;
							7: vga_color = SEVEN [digitCursor] ? ORANGE : GRID_BACKGROUND_COLOR;
							8: vga_color = EIGHT [digitCursor] ? PINK : GRID_BACKGROUND_COLOR;
						endcase
					end else vga_color = GRID_BACKGROUND_COLOR;
				end
			end else begin
				if (isFlagged) begin
					if (halfScaleCursorY > 2 && halfScaleCursorY < 13 && halfScaleCursorX > 4 && halfScaleCursorX < 11) begin
						if (halfScaleCursorX == 5) vga_color = BLACK;
						if (halfScaleCursorX > 5 && halfScaleCursorY > 7) vga_color = RED;
						if (halfScaleCursorX > 5 && halfScaleCursorY < 8) vga_color = GREY;
					end else vga_color = GREY;
				end else begin
					vga_color = GREY;
				end
			end
		end else vga_color = BACKGROUND_COLOR;
    end
end

endmodule