# FPGA Minesweeper

A hardware implementation of the classic Minesweeper game built in Verilog for the DE1-SoC FPGA development board, featuring VGA display output and physical button controls.

![4EED106B-460C-4D57-9FAA-ECA5E9F58F2E_1_105_c](https://github.com/user-attachments/assets/e693ff1a-0bd9-4217-89ed-c8bccdb53540)

## Overview

This project implements a fully functional Minesweeper game on an FPGA, complete with VGA graphics rendering, seven-segment displays for game statistics, and intuitive button-based controls. The game logic is implemented entirely in hardware using Verilog HDL.

## Hardware Requirements

- DE1-SoC FPGA Development Board (or compatible Altera Cyclone V)
- VGA monitor and cable
- Physical push buttons (KEY[3:0])
- Switches (SW[9:0])
- Seven-segment displays (HEX0-HEX5)

## Features

### Game Modes

- **Easy Mode (8×8 grid)**: 10 bombs - perfect for beginners
- **Hard Mode (16×16 grid)**: 40 bombs - a challenging experience
- **Custom Mode**: Create your own difficulty with configurable grid size and bomb count
  - Grid dimensions: 1×1 up to 16×16
  - Bomb count: 1 to 255 (limited by grid size)

### Gameplay Features

- **Random Bomb Placement**: Uses linear feedback shift register (LFSR) for pseudo-random bomb generation
- **Smart Uncovering**: Automatically reveals adjacent cells when clicking on a cell with zero nearby bombs
- **Flag System**: Mark suspected bomb locations to track your progress
- **Number Indicators**: Color-coded numbers (1-8) show how many bombs are adjacent to each cell
- **Cursor Navigation**: Red-outlined cursor for easy cell selection
- **Game Timer**: Tracks elapsed time in minutes and seconds
- **Bomb Counter**: Displays remaining bombs (total bombs minus flags placed)

### Visual Design

- **VGA Display**: 640×480 resolution with smooth graphics
- **Color-Coded Numbers**: Each number (1-8) has a distinct color for quick recognition
  - 1: Cyan
  - 2: Green  
  - 3: Blue
  - 4: Red
  - 5: Purple
  - 6: Yellow
  - 7: Orange
  - 8: Pink
- **Bomb Graphics**: Visual bomb indicators on uncovered bomb cells
- **Flag Graphics**: Gray flag markers for suspected bomb locations
- **Exploded Bomb**: Red background highlights the bomb that ended the game

![2089E9E9-0EFB-4729-8C8F-E28CABB6DC60_1_102_o](https://github.com/user-attachments/assets/409d5772-0487-4fc8-94db-50765d1250b6)

*Photo of some higher bomb counts*

## How to Play

### Starting a New Game

1. **Power on the FPGA** and connect to a VGA monitor
2. **Select your difficulty** by setting SW[0]=1 and SW[1]=1 to enter Action Mode:
   - Press KEY[3] for **Easy Mode** (8×8 grid, 10 bombs)
   - Press KEY[2] for **Hard Mode** (16×16 grid, 40 bombs)
   - Press KEY[1] for **Custom Mode** (configure your own settings)

### Custom Mode Configuration

If you selected Custom Mode, follow these steps:

1. **Set Grid Width**:
   - Use SW[9:6] to select width (0-15, displayed as 1-16)
   - Press KEY[3] in Action Mode to confirm
   - Press KEY[2] to go back

2. **Set Grid Height**:
   - Use SW[9:6] to select height (0-15, displayed as 1-16)
   - Press KEY[3] to confirm
   - Press KEY[2] to go back

3. **Set Bomb Count**:
   - Use SW[9:2] to select bomb count (must be less than total grid cells)
   - Press KEY[3] to start the game
   - Press KEY[2] to go back

![E76A3B83-6E55-4A9B-8A64-785D5FC42821_4_5005_c](https://github.com/user-attachments/assets/83b0161f-a590-4536-a2ea-48e60e1a9e37)

*Photo of Custom 3x9 Grid Size*

### Playing the Game

Once the game starts, the grid appears with covered cells (gray) and a red cursor outline.

**Monitoring Progress**:
- **HEX5-HEX4**: Shows remaining bombs (Total bombs - Flags placed)
- **HEX3-HEX2**: Timer minutes
- **HEX1-HEX0**: Timer seconds

![IMG_5078](https://github.com/user-attachments/assets/29d1af0b-54b6-4e9d-98ab-4c99e4f074a1)

*Photo of the DE1-SoC with Hex Display Outputs*

**Moving the Cursor**:
1. Set SW[0]=0 and SW[1]=0 (Arrow Mode)
2. Use the KEY buttons to navigate:
   - KEY[3]: Move left
   - KEY[2]: Move up
   - KEY[1]: Move down
   - KEY[0]: Move right

**Placing Flags**:
1. Position the cursor over a suspected bomb location
2. Switch to Action Mode (SW[0]=1, SW[1]=1)
3. Press KEY[2] to place a flag (red/gray flag appears)
4. Press KEY[2] again to remove the flag
5. You cannot uncover flagged cells

**Uncovering Cells**:
1. Position the cursor over a cell
2. Switch to Action Mode (SW[0]=1, SW[1]=1)
3. Press KEY[3] to uncover the cell
4. **If it's a bomb** → Game Over! The bomb explodes (red background)
5. **If it's safe** → The cell reveals a number (or stays white if 0)
   - Numbers indicate how many bombs are in the 8 surrounding cells
   - If the number is 0, adjacent cells automatically uncover

### Game Over

If you hit a bomb:
1. The bomb explodes with a red background
2. The timer stops
3. Options:
   - Press KEY[3] (Action Mode) to **restart** with a new board
   - Press KEY[2] (Action Mode) to **reveal** the entire board and see where all bombs were located

![D846D325-ED38-45EB-99E8-0DDFF096D945_1_105_c](https://github.com/user-attachments/assets/931ca30f-67a8-493b-9ac5-04500a6b67f7)

*Photo of an exploded bomb and revealed map*

### Winning the Game

You win when all non-bomb cells are uncovered! The remaining cells will be covered bombs and/or flagged locations.

![4EED106B-460C-4D57-9FAA-ECA5E9F58F2E_1_105_c](https://github.com/user-attachments/assets/ebd219cd-97d4-4667-9a5a-c35a2cc65759)

*Photo of a Successfully Won Game*

### Tips for Success

- Start by clicking cells in areas with more coverage
- Numbers help you deduce bomb locations logically
- When you're certain a cell has a bomb, flag it to avoid misclicks
- If a cell shows "1" and has one covered neighbor, that neighbor is likely a bomb
- Empty cells (0) are your friend - they reveal large safe areas automatically

## Controls Reference

### Button Mapping

The control scheme switches between two modes using SW[0] and SW[1]:
  - **Note**: Both SW[1] and SW[0] must be set together to resolve button flickering issues. Use either both OFF (Arrow Mode) or both ON (Action Mode).

**Arrow Mode** (SW[0]=0, SW[1]=0):
- KEY[3]: Move cursor left
- KEY[2]: Move cursor up
- KEY[1]: Move cursor down
- KEY[0]: Move cursor right

**Action Mode** (SW[0]=1, SW[1]=1):
- KEY[3]: Primary action
- KEY[2]: Secondary action
- KEY[1]: Tertiary action
- KEY[0]: Reset

### Switch Configuration

- **SW[9:6]**: Set grid size (Custom mode)
- **SW[9:2]**: Set bomb count (Custom mode)
- **SW[1:0]**: Control mode selector

## Module Architecture

- `mines.v`: Main game controller with FSM logic
- `cursor.v`: User cursor navigation
- `displayController.v`: VGA graphics rendering
- `keyDebouncer.v`: Button debouncing for clean input
- `random.v`: LFSR-based random number generation
- `timer.v`: Game timer implementation
- `seven_segment.v`: Seven-segment display decoder
- `two_decimal_vals.v`: Two-digit decimal display driver
- `vga_driver.v`: VGA signal timing generator (Created by Dr. Peter Jamieson)

## Technical Highlights

- **Finite State Machine**: Robust game state management with 13 distinct states
- **Grid Storage**: Efficient 7-bit encoding per cell stores bomb status, uncover state, flag state, and adjacent bomb count
- **Neighbor Calculation**: Automatic computation of adjacent bomb counts in all 8 directions
- **Flood Fill Algorithm**: Hardware implementation for revealing connected empty cells
- **Efficient Display Scaling**: Graphics within each cell use display scaling to significantly reduce register count.

## Installation

1. Load the project files into Intel Quartus Prime
2. Set `mines.v` as the top-level entity
3. Assign pin mappings according to your DE1-SoC board configuration
4. Compile the project
5. Program the FPGA using the generated `.sof` file

**Enjoy playing Minesweeper!**
This project was developed for Miami University's Digital Systems Design Course (ECE 287) Taught by Dr. Peter Jamieson.
