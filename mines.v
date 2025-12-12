module mines (
	input        CLOCK_50,
	input  [3:0] KEY,
	input  [9:0] SW,
	output [9:0] LEDR,

	// Seven Segment Displays
	output [6:0] HEX0,
	output [6:0] HEX1,
	output [6:0] HEX2,
	output [6:0] HEX3,
	output [6:0] HEX4,
	output [6:0] HEX5,

	// VGA Display
	output       VGA_BLANK_N,
	output [7:0] VGA_B,
	output       VGA_CLK,
	output [7:0] VGA_G,
	output       VGA_HS,
	output [7:0] VGA_R,
	output       VGA_SYNC_N,
	output       VGA_VS
);

//// INPUT MAPPING ////
wire clock = CLOCK_50;
assign LEDR = SW;
wire [3:0] setGridSize = SW[9:6];
wire [7:0] setBombCount = SW[9:2];


//// KEY DEBOUNCING ////
wire [3:0] debouncedKeys;
wire [3:0] arrowKeys  = (!SW[0] && !SW[1]) ? debouncedKeys : 4'b0000; // arrow keys
wire [3:0] actionKeys = ( SW[0] &&  SW[1]) ? debouncedKeys : 4'b0000; // action keys
wire primaryKey = actionKeys[3];
wire secondaryKey = actionKeys[2];
wire tertiaryKey = actionKeys[1];
wire reset = actionKeys[0];

keyDebouncer Debouncer (
	.clock(clock),
	.reset(reset),
	.keyIn(~KEY),
	.keyOut(debouncedKeys)
);


//// GAME VARIABLES ////
reg [6:0] grid [255:0];
reg [3:0] gridWidth = 1;
reg [3:0] gridHeight = 1;
reg [7:0] bombCount;
reg [7:0] coveredCells = 0;
reg [2:0] directionToIncrement = 3'b000;
// Common grid element types
localparam BOMB_COVERED = 7'b0000010;
localparam BOMB_EXPLODE = 7'b1111111;
localparam BLANK_COVERED = 7'b0000000;


//// SYSTEM CURSOR ////
reg [3:0] systemCursorX, systemCursorY;
wire [6:0] systemElement = grid[systemCursorX + systemCursorY * (gridWidth + 1)];
wire isUncoveredSystem = systemElement[0];
wire isBombSystem = systemElement[1];
wire isFlagSystem = systemElement[2];
wire [3:0] bombsNearSystem = systemElement[6:3];


//// USER CURSOR ////
wire [3:0] userCursorX, userCursorY;
wire [6:0] userElement = grid[userCursorX + userCursorY * (gridWidth + 1)];
wire isUncovered = userElement[0];
wire isBomb = userElement[1];
wire isFlag = userElement[2];
wire [3:0] bombsNear = userElement[6:3];

cursor UserCursor (
	.clock(clock),
	.reset(reset || !gameInProgress),
	.gridWidth(gridWidth),
	.gridHeight(gridHeight),
	.KEY(arrowKeys),
	.cursorX(userCursorX),
	.cursorY(userCursorY)
);


//// RANDOM CURSOR ////
wire [3:0] randomCursorX, randomCursorY;
random RandomCursorX (
    .clock(clock),
    .reset(reset),
    .range(gridWidth),
    .seed(8'hA5),
    .out(randomCursorX)
);

random RandomCursorY (
    .clock(clock),
    .reset(reset),
    .range(gridHeight),
    .seed(8'hB3),
    .out(randomCursorY)
);


//// VGA DISPLAY ////
wire [3:0] displayCursorX;
wire [3:0] displayCursorY;
wire [6:0] displayElement = grid[displayCursorX + displayCursorY * (gridWidth + 1)];
displayController Display (
	.clock(clock),

	// Grid dimensions
	.gridWidth(gridWidth),
	.gridHeight(gridHeight),

	// Display cursor
	.gridCursorX(displayCursorX),
	.gridCursorY(displayCursorY),
	.gridElement(displayElement),

	// User cursor
	.userCursorX(userCursorX),
	.userCursorY(userCursorY),

	// VGA
	.VGA_BLANK_N(VGA_BLANK_N),
	.VGA_B(VGA_B),
	.VGA_CLK(VGA_CLK),
	.VGA_G(VGA_G),
	.VGA_HS(VGA_HS),
	.VGA_R(VGA_R),
	.VGA_SYNC_N(VGA_SYNC_N),
	.VGA_VS(VGA_VS)
);


//// BOMB COUNT ////
reg gameInProgress = 0;
reg [7:0] bombsPlaced = 0;
reg [7:0] flagCount = 0;
two_decimal_vals BombCount (
	.value(flagCount > bombCount ? 0 : (bombCount - flagCount)),
	.HEX0(HEX4),
	.HEX1(HEX5)
);


//// TIMER ////
timer Timer (
	.clock(clock & gameInProgress), // only count when the game is in progress
	.reset(reset || fsmState == CLEAR_BOARD),
	.seconds(timerSeconds),
	.minutes(timerMinutes)
);

wire [5:0] timerSeconds;
two_decimal_vals TimerSeconds (
	.value(timerSeconds),
	.HEX0(HEX0),
	.HEX1(HEX1)
);

wire [5:0] timerMinutes;
two_decimal_vals TimerMinutes (
	.value(timerMinutes),
	.HEX0(HEX2),
	.HEX1(HEX3)
);

//// FSM ////
localparam START = 4'b0000;
localparam SET_WIDTH = 4'b0001;
localparam SET_HEIGHT = 4'b0010;
localparam SET_BOMB_COUNT = 4'b0011;
localparam SET_BOMBS = 4'b0100;
localparam INCREMENT_BOMBS_NEAR = 4'b0101;
localparam IDLE = 4'b0110;
localparam UNCOVER = 4'b0111;
localparam UNCOVER_BLANKS = 4'b1000;
localparam TOGGLE_FLAG = 4'b1001;
localparam GAME_OVER = 4'b1010;
localparam UNCOVER_GRID = 4'b1011;
localparam CLEAR_BOARD = 4'b1100;

reg [3:0] fsmState = START;
always @(posedge clock or posedge reset) begin
	if (reset) begin
		gridWidth <= 15;
		gridHeight <= 15;
		systemCursorX <= 0;
		systemCursorY <= 0;
		flagCount <= 0;
		bombsPlaced <= 0;
		directionToIncrement <= 0;
		gameInProgress <= 0;
		fsmState <= CLEAR_BOARD;
	end else begin
		case (fsmState)
			START: begin
				if (primaryKey) begin // easy
					gridWidth <= 7;
					gridHeight <= 7;
					bombCount <= 10;
					fsmState <= SET_BOMBS;
				end else if (secondaryKey) begin // hard
					gridWidth <= 15;
					gridHeight <= 15;
					bombCount <= 40;
					fsmState <= SET_BOMBS;
				end else if (tertiaryKey) begin // custom
					fsmState <= SET_WIDTH;
				end
			end
			SET_WIDTH: begin
				gridWidth <= setGridSize;
				if (primaryKey) fsmState <= SET_HEIGHT;
				else if (secondaryKey) fsmState <= START;
			end
			SET_HEIGHT: begin
				gridHeight <= setGridSize;
				if (primaryKey) fsmState <= SET_BOMB_COUNT;
				else if (secondaryKey) fsmState <= SET_WIDTH;
			end
			SET_BOMB_COUNT: begin
				bombCount <= setBombCount;
				if (secondaryKey) fsmState <= SET_HEIGHT;
				if (setBombCount < (gridWidth + 1) * (gridHeight + 1)) begin
					bombCount <= setBombCount;
					if (primaryKey) fsmState <= SET_BOMBS;
				end else bombCount <= 0;
			end
			SET_BOMBS: begin
				if (bombsPlaced < bombCount) begin
                    if (grid[randomCursorX + randomCursorY * (gridWidth + 1)][1] == 0) begin // if not bomb already

						// Place bomb at random location
                        grid[randomCursorX + randomCursorY * (gridWidth + 1)] <= BOMB_COVERED;
                        bombsPlaced <= bombsPlaced + 1;

						// increment bombsNear count for adjacent tiles
						systemCursorX <= randomCursorX;
						systemCursorY <= randomCursorY;
						directionToIncrement <= 0;
						fsmState <= INCREMENT_BOMBS_NEAR;
                    end
				end else begin
					coveredCells <= (gridWidth + 1) * (gridHeight + 1);
					fsmState <= IDLE;
				end
			end
			INCREMENT_BOMBS_NEAR: begin
				case (directionToIncrement)
					0: if (systemCursorY < gridHeight) grid[systemCursorX + (systemCursorY + 1) * (gridWidth + 1)][6:3] <= grid[systemCursorX + (systemCursorY + 1) * (gridWidth + 1)][6:3] + 1;
					1: if (systemCursorY > 0) grid[systemCursorX + (systemCursorY - 1) * (gridWidth + 1)][6:3] <= grid[systemCursorX + (systemCursorY - 1) * (gridWidth + 1)][6:3] + 1;
					2: if (systemCursorX < gridWidth) grid[(systemCursorX + 1) + systemCursorY * (gridWidth + 1)][6:3] <= grid[(systemCursorX + 1) + systemCursorY * (gridWidth + 1)][6:3] + 1;
					3: if (systemCursorX > 0) grid[(systemCursorX - 1) + systemCursorY * (gridWidth + 1)][6:3] <= grid[(systemCursorX - 1) + systemCursorY * (gridWidth + 1)][6:3] + 1;
					4: if (systemCursorY < gridHeight && systemCursorX < gridWidth) grid[(systemCursorX + 1) + (systemCursorY + 1) * (gridWidth + 1)][6:3] <= grid[(systemCursorX + 1) + (systemCursorY + 1) * (gridWidth + 1)][6:3] + 1;
					5: if (systemCursorY < gridHeight && systemCursorX > 0) grid[(systemCursorX - 1) + (systemCursorY + 1) * (gridWidth + 1)][6:3] <= grid[(systemCursorX - 1) + (systemCursorY + 1) * (gridWidth + 1)][6:3] + 1;
					6: if (systemCursorY > 0 && systemCursorX < gridWidth) grid[(systemCursorX + 1) + (systemCursorY - 1) * (gridWidth + 1)][6:3] <= grid[(systemCursorX + 1) + (systemCursorY - 1) * (gridWidth + 1)][6:3] + 1;
					7: if (systemCursorY > 0 && systemCursorX > 0) grid[(systemCursorX - 1) + (systemCursorY - 1) * (gridWidth + 1)][6:3] <= grid[(systemCursorX - 1) + (systemCursorY - 1) * (gridWidth + 1)][6:3] + 1;
					default: fsmState <= SET_BOMBS;
				endcase
				if (directionToIncrement == 7) begin
					directionToIncrement <= 0;
					fsmState <= SET_BOMBS;
				end else directionToIncrement <= directionToIncrement + 1;
			end
			IDLE: begin
				systemCursorX <= 0;
				systemCursorY <= 0;
				gameInProgress <= 1;
				if (coveredCells == bombCount) fsmState <= GAME_OVER;
				else if (primaryKey) fsmState <= UNCOVER;
				else if (secondaryKey) fsmState <= TOGGLE_FLAG;
			end
			UNCOVER: begin
				if (!isUncovered) begin
					if (isBomb) begin
						grid[userCursorX + userCursorY * (gridWidth + 1)] <= BOMB_EXPLODE;
						fsmState <= GAME_OVER;
					end else if (bombsNear == 0) begin
						grid[userCursorX + userCursorY * (gridWidth + 1)][0] <= 1;
						coveredCells <= coveredCells - 1;
						directionToIncrement <= 0;
						fsmState <= UNCOVER_BLANKS;
					end else begin
						grid[userCursorX + userCursorY * (gridWidth + 1)][0] <= 1;
						coveredCells <= coveredCells - 1;
						fsmState <= IDLE;
					end
				end else fsmState <= IDLE;
			end
			UNCOVER_BLANKS: begin
				case (directionToIncrement)
					0: begin
						if (userCursorY > 0) begin
							if (grid[userCursorX + (userCursorY - 1) * (gridWidth + 1)][0] == 0) begin
								grid[userCursorX + (userCursorY - 1) * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 1;
					end
					1: begin
						if (userCursorY < gridHeight) begin
							if (grid[userCursorX + (userCursorY + 1) * (gridWidth + 1)][0] == 0) begin
								grid[userCursorX + (userCursorY + 1) * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 2;
					end
					2: begin
						if (userCursorX > 0) begin
							if (grid[(userCursorX - 1) + userCursorY * (gridWidth + 1)][0] == 0) begin
								grid[(userCursorX - 1) + userCursorY * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 3;
					end
					3: begin
						if (userCursorX < gridWidth) begin
							if (grid[(userCursorX + 1) + userCursorY * (gridWidth + 1)][0] == 0) begin
								grid[(userCursorX + 1) + userCursorY * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 4;
					end
					4: begin
						if (userCursorY > 0 && userCursorX > 0) begin
							if (grid[(userCursorX - 1) + (userCursorY - 1) * (gridWidth + 1)][0] == 0) begin
								grid[(userCursorX - 1) + (userCursorY - 1) * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 5;
					end
					5: begin
						if (userCursorY > 0 && userCursorX < gridWidth) begin
							if (grid[(userCursorX + 1) + (userCursorY - 1) * (gridWidth + 1)][0] == 0) begin
								grid[(userCursorX + 1) + (userCursorY - 1) * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 6;
					end
					6: begin
						if (userCursorY < gridHeight && userCursorX > 0) begin
							if (grid[(userCursorX - 1) + (userCursorY + 1) * (gridWidth + 1)][0] == 0) begin
								grid[(userCursorX - 1) + (userCursorY + 1) * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						directionToIncrement <= 7;
					end
					7: begin
						if (userCursorY < gridHeight && userCursorX < gridWidth) begin
							if (grid[(userCursorX + 1) + (userCursorY + 1) * (gridWidth + 1)][0] == 0) begin
								grid[(userCursorX + 1) + (userCursorY + 1) * (gridWidth + 1)][0] <= 1;
								coveredCells <= coveredCells - 1;
							end
						end
						fsmState <= IDLE;
						directionToIncrement <= 0;
					end
				endcase
			end
			TOGGLE_FLAG: begin
				if (!isUncovered) begin
					if (!isFlag) begin
						grid[userCursorX + userCursorY * (gridWidth + 1)][2] <= 1;
						flagCount <= flagCount + 1;
					end else begin
						grid[userCursorX + userCursorY * (gridWidth + 1)][2] <= 0;
						flagCount <= flagCount - 1;
					end
				end
				fsmState <= IDLE;
			end
			GAME_OVER: begin
				systemCursorX <= 0;
				systemCursorY <= 0;
				gameInProgress <= 0;
				if (primaryKey) fsmState <= CLEAR_BOARD;
				else if (secondaryKey) fsmState <= UNCOVER_GRID;
			end
			UNCOVER_GRID: begin
				grid[systemCursorX + systemCursorY * (gridWidth + 1)][0] <= 1;
				if (systemCursorX == gridWidth && systemCursorY == gridHeight) begin
					fsmState <= GAME_OVER;
				end else if (systemCursorY == gridHeight) begin
					systemCursorY <= 0;
					systemCursorX <= systemCursorX + 1;
				end else begin
					systemCursorY <= systemCursorY + 1;
				end
			end
			CLEAR_BOARD: begin
				grid[systemCursorX + systemCursorY * (gridWidth + 1)] <= BLANK_COVERED;
				if (systemCursorX == gridWidth && systemCursorY == gridHeight) begin
					flagCount <= 0;
					bombCount <= 0;
					bombsPlaced <= 0;
					systemCursorX <= 0;
					systemCursorY <= 0;
					gridWidth <= 0;
					gridHeight <= 0;
					fsmState <= START;
					bombsPlaced <= 0;
				end else if (systemCursorY == gridHeight) begin
					systemCursorY <= 0;
					systemCursorX <= systemCursorX + 1;
				end else begin
					systemCursorY <= systemCursorY + 1;
				end
			end
		endcase
	end
end
endmodule