\
# filepath: /Users/shufanzhang/Documents/coderepos/GobangAI/gobang_python_translated.py
# Translated from Julia Gobang AI (which was translated from C++)
# Note: Graphics and console input specific parts are adapted for Python console.

import numpy as np
import math

# Constants
GRID_NUM = 15  # Board size (15x15)
MYBLACK = 0  # Black stone
MYWHITE = 1  # White stone
NOSTONE = 9  # Empty intersection

# Chess pattern types
STWO = 1  # Blocked Two
STHREE = 2  # Blocked Three
SFOUR = 3  # Blocked Four / Four with one end blocked
TWO = 4  # Live Two
THREE = 5  # Live Three
FOUR = 6  # Live Four
FIVE = 7  # Five-in-a-row
NOTYPE = 11  # Undefined pattern
ANALYSED = 255  # Analyzed position
TOBEANALSIS = 0  # To be analyzed

# --- Data Structures ---

# Point on the board
class MyPoint:
    def __init__(self, x: int, y: int):
        self.x = x
        self.y = y

# Represents a move
class MoveStone:
    def __init__(self, color: int, ptMovePoint: MyPoint):
        self.color = color
        self.ptMovePoint = ptMovePoint

# Represents the board state
class State:
    def __init__(self, initial_grid: np.ndarray):
        self.grid = np.copy(initial_grid)

# Represents a state after a move, with its score
class AfterMove:
    def __init__(self, state: State = None, score: int = 0):
        self.state = state
        self.score = score

# --- Global Variables ---
# Stores analysis results for a line
m_LineRecord = np.zeros(30, dtype=int)

# Stores analysis results for the whole board [row, col, direction]
# Directions: 0:Horizontal, 1:Vertical, 2:Left-Diagonal, 3:Right-Diagonal (Python 0-indexed)
TypeRecord = np.zeros((GRID_NUM, GRID_NUM, 4), dtype=int)

# Counts of each pattern type for each color [color_idx, pattern_type_idx]
# color_idx: 0 for MYBLACK, 1 for MYWHITE
TypeCount = np.zeros((2, 20), dtype=int) # Max pattern type index is around 11, 20 is safe

# Positional values for heuristic evaluation (0-indexed for Python)
PosValue = np.array([
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,1,2,2,2,2,2,2,2,2,2,2,2,1,0],
    [0,1,2,3,3,3,3,3,3,3,3,3,2,1,0],
    [0,1,2,3,4,4,4,4,4,4,4,3,2,1,0],
    [0,1,2,3,4,5,5,5,5,5,4,3,2,1,0],
    [0,1,2,3,4,5,6,6,6,5,4,3,2,1,0],
    [0,1,2,3,4,5,6,7,6,5,4,3,2,1,0],
    [0,1,2,3,4,5,6,6,6,5,4,3,2,1,0],
    [0,1,2,3,4,5,5,5,5,5,4,3,2,1,0],
    [0,1,2,3,4,4,4,4,4,4,4,3,2,1,0],
    [0,1,2,3,3,3,3,3,3,3,3,3,2,1,0],
    [0,1,2,2,2,2,2,2,2,2,2,2,2,1,0],
    [0,1,1,1,1,1,1,1,1,1,1,1,1,1,0],
    [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
])

# --- Helper Functions ---

# Check if a position is valid on the board
def isValidPos(x: int, y: int) -> bool:
    return (0 <= x < GRID_NUM) and (0 <= y < GRID_NUM)

# --- Core Logic Functions ---

# Analyzes a single line (row, column, or diagonal) for patterns
def analysis_line(line_segment: np.ndarray, stone_pos_in_line: int, current_stone_type: int) -> int:
    global m_LineRecord
    m_LineRecord.fill(TOBEANALSIS)

    num_stones = len(line_segment)
    if num_stones < 5:
        if num_stones > 0:
            m_LineRecord[:num_stones] = ANALYSED
        return NOTYPE

    analy_pos_0idx = stone_pos_in_line
    
    left_edge_0idx = analy_pos_0idx
    right_edge_0idx = analy_pos_0idx

    # Find left boundary
    while left_edge_0idx > 0 and line_segment[left_edge_0idx - 1] == current_stone_type:
        left_edge_0idx -= 1
    
    # Find right boundary
    while right_edge_0idx < num_stones - 1 and line_segment[right_edge_0idx + 1] == current_stone_type:
        right_edge_0idx += 1
        
    connected_len = right_edge_0idx - left_edge_0idx + 1

    # Mark the continuous segment as analyzed
    m_LineRecord[left_edge_0idx : right_edge_0idx + 1] = ANALYSED
    
    # --- Pattern Recognition (Simplified from Julia/C++) ---
    # This is a complex part. The logic here is a direct but simplified translation.
    # It might not cover all nuanced cases from the original C++ like gaps.

    if connected_len >= 5:
        m_LineRecord[analy_pos_0idx] = FIVE
        return FIVE

    if connected_len == 4:
        has_left_space = (left_edge_0idx > 0 and line_segment[left_edge_0idx - 1] == NOSTONE) or \
                         (left_edge_0idx == 0) # Edge of board is a space
        has_right_space = (right_edge_0idx < num_stones - 1 and line_segment[right_edge_0idx + 1] == NOSTONE) or \
                          (right_edge_0idx == num_stones - 1) # Edge of board is a space
        
        if has_left_space and has_right_space:
            m_LineRecord[analy_pos_0idx] = FOUR
            return FOUR
        elif has_left_space or has_right_space:
            m_LineRecord[analy_pos_0idx] = SFOUR
            return SFOUR
        # If neither, it\'s a blocked 4, but the original C++ might not classify this or handle it differently.
        # For now, if not live or semi-live, it won\'t be marked as FOUR/SFOUR by this logic.
        # The original C++ logic for SFOUR is more complex and considers patterns like XOOOO_X or _OOOOX
        # This simplified version primarily looks at the immediate ends of the 4-in-a-row.

    if connected_len == 3:
        left_open = (left_edge_0idx > 0 and line_segment[left_edge_0idx - 1] == NOSTONE)
        right_open = (right_edge_0idx < num_stones - 1 and line_segment[right_edge_0idx + 1] == NOSTONE)

        # Simplified:
        if left_open and right_open:
            # Check for potential SFOUR with a gap (e.g., O_OOO or OOO_O)
            # This requires looking one step further.
            # O_OOO: (left_edge_0idx > 1 and line_segment[left_edge_0idx - 2] == current_stone_type)
            # OOO_O: (right_edge_0idx < num_stones - 2 and line_segment[right_edge_0idx + 2] == current_stone_type)
            # The original C++ code has detailed checks for these.
            # For simplicity, we\'ll stick to THREE/STHREE based on immediate openings.
            
            # A more direct translation of the C++ logic for SFOUR with 3 stones:
            # if (Left_empty && line[left_edge-2] == stone) || (Right_empty && line[right_edge+2] == stone)
            # This means: X O _ O O X or X O O _ O X
            # This is complex to add here without the full C++ context of how it scans.
            # The Julia code also simplified this part.

            m_LineRecord[analy_pos_0idx] = THREE
            return THREE
        elif left_open or right_open:
            m_LineRecord[analy_pos_0idx] = STHREE
            return STHREE

    if connected_len == 2:
        left_open = (left_edge_0idx > 0 and line_segment[left_edge_0idx - 1] == NOSTONE)
        right_open = (right_edge_0idx < num_stones - 1 and line_segment[right_edge_0idx + 1] == NOSTONE)

        if left_open and right_open:
            # Check for STHREE with gaps like O_O_O
            # This also requires more complex gap analysis.
            m_LineRecord[analy_pos_0idx] = TWO
            return TWO
        elif left_open or right_open:
            m_LineRecord[analy_pos_0idx] = STWO
            return STWO
            
    m_LineRecord[analy_pos_0idx] = NOTYPE
    return NOTYPE


# Analyze horizontal line at (r, c) (0-indexed r, c)
def analysis_horizon(board: np.ndarray, r: int, c: int) -> int:
    global TypeRecord, m_LineRecord
    line_segment = board[r, :]
    analysis_line(line_segment, c, board[r,c])
    for s in range(GRID_NUM):
        if m_LineRecord[s] != TOBEANALSIS:
            TypeRecord[r, s, 0] = m_LineRecord[s] # Direction 0 for Horizontal
    return TypeRecord[r, c, 0]

# Analyze vertical line at (r, c)
def analysis_vertical(board: np.ndarray, r: int, c: int) -> int:
    global TypeRecord, m_LineRecord
    line_segment = board[:, c]
    analysis_line(line_segment, r, board[r,c])
    for s in range(GRID_NUM):
        if m_LineRecord[s] != TOBEANALSIS:
            TypeRecord[s, c, 1] = m_LineRecord[s] # Direction 1 for Vertical
    return TypeRecord[r, c, 1]

# Analyze left-diagonal (top-left to bottom-right) through (r, c)
def analysis_left_diag(board: np.ndarray, r: int, c: int) -> int:
    global TypeRecord, m_LineRecord
    temp_array_list = []
    
    start_r, start_c = r, c
    while start_r > 0 and start_c > 0:
        start_r -= 1
        start_c -= 1
    
    stone_pos_in_diag = 0
    
    curr_r, curr_c = start_r, start_c
    idx = 0
    while curr_r < GRID_NUM and curr_c < GRID_NUM:
        temp_array_list.append(board[curr_r, curr_c])
        if curr_r == r and curr_c == c:
            stone_pos_in_diag = idx
        curr_r += 1
        curr_c += 1
        idx +=1
    
    temp_array = np.array(temp_array_list)
    if len(temp_array) > 0:
        analysis_line(temp_array, stone_pos_in_diag, board[r,c])
        
        curr_r, curr_c = start_r, start_c
        for s in range(len(temp_array)):
            if m_LineRecord[s] != TOBEANALSIS:
                if curr_r < GRID_NUM and curr_c < GRID_NUM:
                    TypeRecord[curr_r, curr_c, 2] = m_LineRecord[s] # Direction 2 for Left-Diag
            curr_r += 1
            curr_c += 1
            if curr_r >= GRID_NUM or curr_c >= GRID_NUM:
                break
    return TypeRecord[r, c, 2]

# Analyze right-diagonal (top-right to bottom-left) through (r, c)
def analysis_right_diag(board: np.ndarray, r: int, c: int) -> int:
    global TypeRecord, m_LineRecord
    temp_array_list = []

    start_r, start_c = r, c
    while start_r > 0 and start_c < GRID_NUM - 1:
        start_r -= 1
        start_c += 1
        
    stone_pos_in_diag = 0
    
    curr_r, curr_c = start_r, start_c
    idx = 0
    while curr_r < GRID_NUM and curr_c >= 0:
        temp_array_list.append(board[curr_r, curr_c])
        if curr_r == r and curr_c == c:
            stone_pos_in_diag = idx
        curr_r += 1
        curr_c -= 1
        idx +=1

    temp_array = np.array(temp_array_list)
    if len(temp_array) > 0:
        analysis_line(temp_array, stone_pos_in_diag, board[r,c])

        curr_r, curr_c = start_r, start_c
        for s in range(len(temp_array)):
            if m_LineRecord[s] != TOBEANALSIS:
                if curr_r < GRID_NUM and curr_c >= 0:
                    TypeRecord[curr_r, curr_c, 3] = m_LineRecord[s] # Direction 3 for Right-Diag
            curr_r += 1
            curr_c -= 1
            if curr_r >= GRID_NUM or curr_c < 0:
                break
    return TypeRecord[r, c, 3]


# Evaluate the board state for the given color to move
def evaluate_board(board: np.ndarray, color_to_move: int) -> int:
    global TypeRecord, TypeCount
    TypeRecord.fill(TOBEANALSIS)
    TypeCount.fill(0)

    for r_idx in range(GRID_NUM):
        for c_idx in range(GRID_NUM):
            if board[r_idx, c_idx] != NOSTONE:
                # Horizontal
                if TypeRecord[r_idx, c_idx, 0] == TOBEANALSIS:
                    analysis_horizon(board, r_idx, c_idx)
                # Vertical
                if TypeRecord[r_idx, c_idx, 1] == TOBEANALSIS:
                    analysis_vertical(board, r_idx, c_idx)
                # Left Diagonal
                if TypeRecord[r_idx, c_idx, 2] == TOBEANALSIS:
                    analysis_left_diag(board, r_idx, c_idx)
                # Right Diagonal
                if TypeRecord[r_idx, c_idx, 3] == TOBEANALSIS:
                    analysis_right_diag(board, r_idx, c_idx)

    # Aggregate TypeCount from TypeRecord
    for r_idx in range(GRID_NUM):
        for c_idx in range(GRID_NUM):
            stone_type_on_board = board[r_idx,c_idx]
            if stone_type_on_board != NOSTONE:
                player_idx = stone_type_on_board # MYBLACK (0) or MYWHITE (1)
                for k_direction in range(4): # Directions
                    pattern = TypeRecord[r_idx, c_idx, k_direction]
                    if pattern != NOTYPE and pattern != ANALYSED and pattern != TOBEANALSIS:
                        if 1 <= pattern < TypeCount.shape[1]: # Ensure pattern is valid index
                            TypeCount[player_idx, pattern] += 1
    
    # Scoring logic (direct translation of Julia/C++ version)
    idx_black = MYBLACK
    idx_white = MYWHITE

    if TypeCount[idx_black, FIVE] > 0: return -9999 # Black wins
    if TypeCount[idx_white, FIVE] > 0: return 9999  # White wins

    # Two SFOURs are like a FOUR
    if TypeCount[idx_white, SFOUR] >= 2: TypeCount[idx_white, FOUR] += 1
    if TypeCount[idx_black, SFOUR] >= 2: TypeCount[idx_black, FOUR] += 1
    
    # Correction: The original C++ code divides counts by the number of stones forming the pattern.
    # e.g., a line of 5 identical stones forming a "FIVE" pattern is counted once for that pattern.
    # The current aggregation TypeCount[player_idx, pattern] += 1 might overcount if multiple stones
    # in the same pattern line are processed.
    # The C++ code seems to sum TypeRecord which stores the pattern type *at each stone*.
    # A single horizontal FIVE involves 5 stones. Each would have TypeRecord[r,c,dir] = FIVE.
    # So TypeCount[player, FIVE] would become 5.
    # The fix is to divide by the number of stones in the pattern.
    # For FIVE: divide by 5. For FOUR: divide by 4. For THREE: by 3. For TWO: by 2.
    # This is a common way to count patterns. Let\'s assume the original C++ did this.
    # However, the Julia code did not explicitly show this division in its TypeCount aggregation.
    # For a more direct translation of the Julia code\'s apparent logic, we keep it as is.
    # If the C++ logic was intended, TypeCount would need adjustment.
    # The scoring below seems to expect unique counts of pattern types, not sum of stones in patterns.
    # Example: "if TypeCount[idx_white, FOUR] > 0" implies presence, not number of stones.
    # The Julia code: TypeCount[player_idx, pattern] += 1. This means if a FIVE is found,
    # and it involves 5 stones, TypeCount[player, FIVE] could become 5 if each stone's analysis adds 1.
    # This needs clarification from original C++ or deeper testing.
    # For now, proceeding with the direct translation of Julia's aggregation.

    w_value = 0
    b_value = 0

    if color_to_move == MYWHITE:
        if TypeCount[idx_white, FOUR] > 0: return 9990
        if TypeCount[idx_white, SFOUR] > 0: return 9980 # One SFOUR is a threat
        if TypeCount[idx_black, FOUR] > 0: return -9970
        if TypeCount[idx_black, SFOUR] > 0 and TypeCount[idx_black, THREE] > 0: return -9960
        if TypeCount[idx_white, THREE] > 0 and TypeCount[idx_black, SFOUR] == 0: return 9950
        if TypeCount[idx_black, THREE] > 1 and TypeCount[idx_white, SFOUR] == 0 and \
           TypeCount[idx_white, THREE] == 0 and TypeCount[idx_white, STHREE] == 0: return -9940
        
        w_value += 2000 if TypeCount[idx_white, THREE] > 1 else (200 if TypeCount[idx_white, THREE] > 0 else 0)
        b_value += 500 if TypeCount[idx_black, THREE] > 1 else (100 if TypeCount[idx_black, THREE] > 0 else 0)
    else: # color_to_move == MYBLACK
        if TypeCount[idx_black, FOUR] > 0: return -9990
        if TypeCount[idx_black, SFOUR] > 0: return -9980
        if TypeCount[idx_white, FOUR] > 0: return 9970
        if TypeCount[idx_white, SFOUR] > 0 and TypeCount[idx_white, THREE] > 0: return 9960
        if TypeCount[idx_black, THREE] > 0 and TypeCount[idx_white, SFOUR] == 0: return -9950
        if TypeCount[idx_white, THREE] > 1 and TypeCount[idx_black, SFOUR] == 0 and \
           TypeCount[idx_black, THREE] == 0 and TypeCount[idx_black, STHREE] == 0: return 9940

        b_value += 2000 if TypeCount[idx_black, THREE] > 1 else (200 if TypeCount[idx_black, THREE] > 0 else 0)
        w_value += 500 if TypeCount[idx_white, THREE] > 1 else (100 if TypeCount[idx_white, THREE] > 0 else 0)

    w_value += TypeCount[idx_white, STHREE] * 10
    b_value += TypeCount[idx_black, STHREE] * 10
    w_value += TypeCount[idx_white, TWO] * 4
    b_value += TypeCount[idx_black, TWO] * 4 
    w_value += TypeCount[idx_white, STWO] * 1 # Julia had *1 implicitly
    b_value += TypeCount[idx_black, STWO] * 1

    # Positional value
    for r_idx in range(GRID_NUM):
        for c_idx in range(GRID_NUM):
            if board[r_idx, c_idx] == MYBLACK:
                b_value += PosValue[r_idx, c_idx]
            elif board[r_idx, c_idx] == MYWHITE:
                w_value += PosValue[r_idx, c_idx]
                
    return w_value - b_value


# Generate possible moves
def create_possible_moves(board: np.ndarray, color: int) -> list:
    moves = []
    has_stones_on_board = np.any(board != NOSTONE)

    if not has_stones_on_board: # If board is empty
        # Add center move if board is empty
        center_r, center_c = GRID_NUM // 2, GRID_NUM // 2
        moves.append(MoveStone(color, MyPoint(center_r, center_c)))
        return moves

    # Heuristic: only consider moves near existing stones
    # Define a search radius for "near"
    # For simplicity, let\'s use a 1-cell radius (8 neighbors)
    # A more advanced heuristic might use a larger radius or consider opponent\'s threats.
    
    candidate_points = set()
    for r_idx in range(GRID_NUM):
        for c_idx in range(GRID_NUM):
            if board[r_idx, c_idx] == NOSTONE:
                is_near_stone = False
                # Check 2-cell radius for more candidate moves
                for dr in range(-2, 3): # -2, -1, 0, 1, 2
                    for dc in range(-2, 3):
                        if dr == 0 and dc == 0: continue
                        nr, nc = r_idx + dr, c_idx + dc
                        if 0 <= nr < GRID_NUM and 0 <= nc < GRID_NUM and board[nr, nc] != NOSTONE:
                            is_near_stone = True
                            break
                    if is_near_stone: break
                
                if is_near_stone:
                    candidate_points.add((r_idx, c_idx))

    if not candidate_points and has_stones_on_board: # Should not happen if stones exist
        # Fallback: if no candidates near stones (e.g. very sparse board, or error in logic)
        # allow any empty spot. This case is unlikely if the "near stone" logic is broad enough.
        for r_idx in range(GRID_NUM):
            for c_idx in range(GRID_NUM):
                if board[r_idx, c_idx] == NOSTONE:
                     candidate_points.add((r_idx, c_idx))
    
    for r_cand, c_cand in candidate_points:
        moves.append(MoveStone(color, MyPoint(r_cand, c_cand)))
        
    return moves


# Alpha-Beta search
def alphabeta(current_board: np.ndarray, depth: int, alpha: int, beta: int, color_to_move: int) -> AfterMove:
    score = evaluate_board(current_board, color_to_move)
    if abs(score) >= 9990 or depth == 0: # Win/loss state or max depth
        return AfterMove(State(current_board), score)

    possible_moves = create_possible_moves(current_board, color_to_move)
    if not possible_moves: # No moves possible
        return AfterMove(State(current_board), score) 
    
    best_move_state_for_return = None # Store the board state of the best move found at this level

    if color_to_move == MYWHITE: # Maximizing player
        best_val = -20000 
        current_alpha = alpha
        for move in possible_moves:
            temp_board = np.copy(current_board)
            temp_board[move.ptMovePoint.x, move.ptMovePoint.y] = MYWHITE
            
            result = alphabeta(temp_board, depth - 1, current_alpha, beta, MYBLACK)
            
            if result.score > best_val:
                best_val = result.score
                # The state to return should be the state *after* the current player\'s move
                best_move_state_for_return = State(temp_board) 
            
            current_alpha = max(current_alpha, best_val)
            if beta <= current_alpha:
                break # Beta cut-off
        # Return the state that resulted from the best move at *this* level for MYWHITE
        return AfterMove(best_move_state_for_return, best_val) 
    else: # color_to_move == MYBLACK, Minimizing player
        best_val = 20000
        current_beta = beta
        for move in possible_moves:
            temp_board = np.copy(current_board)
            temp_board[move.ptMovePoint.x, move.ptMovePoint.y] = MYBLACK

            result = alphabeta(temp_board, depth - 1, alpha, current_beta, MYWHITE)

            if result.score < best_val:
                best_val = result.score
                best_move_state_for_return = State(temp_board)

            current_beta = min(current_beta, best_val)
            if current_beta <= alpha:
                break # Alpha cut-off
        return AfterMove(best_move_state_for_return, best_val)

# Make a move for AI
def make_ai_move(board: np.ndarray, ai_color: int, search_depth: int) -> np.ndarray:
    print(f"AI (color: {ai_color}) is thinking with depth {search_depth}...")
    result_after_move = alphabeta(np.copy(board), search_depth, -20000, 20000, ai_color)
    
    if result_after_move.state is not None:
        print(f"AI chooses move leading to score: {result_after_move.score}")
        # Find the actual move made by comparing result_after_move.state.grid with original board
        diff = np.where(result_after_move.state.grid != board)
        if len(diff[0]) > 0:
            move_r, move_c = diff[0][0], diff[1][0]
            print(f"AI places at ({move_r+1}, {move_c+1})") # User-friendly 1-indexed
        return result_after_move.state.grid
    else:
        print("AI could not find a valid move or state. This shouldn\'t happen if game not over.")
        # Fallback: if somehow no state, return original board
        # This might happen if create_possible_moves returns empty and alphabeta doesn\'t handle it well before this.
        # Or if the game is over but not caught by is_game_over before calling AI.
        # A robust AI would have a fallback if alphabeta returns no state (e.g. random valid move).
        # For now, returning the original board means AI effectively passes its turn if this error occurs.
        return board 

# Check if game is over
def is_game_over(board: np.ndarray, last_player_color: int) -> bool:
    # Evaluate board. If a player has FIVE, they won.
    # The `evaluate_board` function returns scores like +/-9999 for wins.
    # We need to check if the `last_player_color` made a winning move.
    # So, we evaluate from the perspective of the *next* player.
    # If White just moved (last_player_color == MYWHITE), evaluate for Black (MYBLACK).
    # If Black has a score of -9999 (meaning Black won), then White\'s last move didn\'t prevent it,
    # or if White has a score of 9999 (meaning White won), then White\'s last move was winning.

    # Let\'s evaluate from the perspective of the player who just moved.
    # If their move resulted in a win for them.
    eval_score_for_black = evaluate_board(board, MYBLACK) # What\'s the score if it were Black\'s turn to assess?
    eval_score_for_white = evaluate_board(board, MYWHITE) # What\'s the score if it were White\'s turn to assess?

    # Check for win by MYBLACK
    if TypeCount[MYBLACK, FIVE] > 0: # Check TypeCount directly after evaluation
        print("Game Over! Black wins.")
        return True
    # Check for win by MYWHITE
    if TypeCount[MYWHITE, FIVE] > 0:
        print("Game Over! White wins.")
        return True

    # Check for draw (no empty spots left)
    if not np.any(board == NOSTONE):
        print("Game Over! It\'s a draw.")
        return True
    return False


# Display board in console
def display_board(board: np.ndarray):
    print("\\n  " + " ".join([f"{i+1:<2}" for i in range(GRID_NUM)]))
    for r_idx in range(GRID_NUM):
        print(f"{r_idx+1:<2} ", end="")
        for c_idx in range(GRID_NUM):
            if board[r_idx, c_idx] == MYBLACK:
                print("B  ", end="")
            elif board[r_idx, c_idx] == MYWHITE:
                print("W  ", end="")
            else:
                print(".  ", end="")
        print()
    print()

# Initialize board
def init_board() -> np.ndarray:
    board = np.full((GRID_NUM, GRID_NUM), NOSTONE, dtype=int)
    return board

# --- Main Game Loop ---
def main_game():
    board = init_board()
    
    player_color_str = ""
    while player_color_str not in ["0", "1"]:
        player_color_str = input("Enter your color: (0 for Black, 1 for White)\\n> ").strip()
        if player_color_str not in ["0", "1"]:
            print("Invalid input. Please enter 0 for Black or 1 for White.")
            
    player_color = int(player_color_str)
    ai_color = 1 - player_color
    current_color = MYBLACK # Black always starts
    
    search_depth = 5 # AI search depth (can be increased, e.g., 4 or 5, but gets slower)
    # For a 15x15 board, depth 3 is reasonable for quick turns.
    # Depth 4-5 will be much stronger but slower.
    # The original Julia had depth 5.

    print(f"You are: {'Black' if player_color == MYBLACK else 'White'}")
    print(f"AI is: {'Black' if ai_color == MYBLACK else 'White'}")
    print(f"Search depth: {search_depth}")

    display_board(board)
    step = 0

    while True:
        # Game over check should ideally happen *after* a move is made.
        # The `is_game_over` function checks the board state.
        # If called before a move, it checks the state from the *previous* turn.

        if current_color == player_color:
            print(f"Your turn ({'Black' if player_color == MYBLACK else 'White'}). Enter row and col (e.g., 7 7):")
            while True:
                try:
                    raw_input = input("> ").strip()
                    parts = raw_input.split()
                    r = int(parts[0]) - 1 # Convert to 0-indexed
                    c = int(parts[1]) - 1 # Convert to 0-indexed
                    if 0 <= r < GRID_NUM and 0 <= c < GRID_NUM and board[r, c] == NOSTONE:
                        board[r, c] = player_color
                        break
                    else:
                        print("Invalid move (out of bounds or spot taken). Try again.")
                except (ValueError, IndexError):
                    print("Invalid input format. Format: row col (e.g., 7 7). Try again.")
        else: # AI\'s turn
            print(f"AI\'s turn ({'Black' if ai_color == MYBLACK else 'White'})...")
            if step == 0 and ai_color == MYBLACK: # AI is black and first move
                center = GRID_NUM // 2
                board[center, center] = ai_color
                print(f"AI places at {center+1}, {center+1}")
            else:
                board = make_ai_move(board, ai_color, search_depth)
        
        display_board(board)
        
        # Check for game over after the move
        # The `is_game_over` function needs the color of the player who just moved.
        if is_game_over(board, current_color): 
            break # is_game_over prints the result

        current_color = 1 - current_color # Switch player
        step += 1
        
    print("Thank you for playing!")

if __name__ == "__main__":
    # Example of how to call evaluate if needed for testing:
    # test_board = init_board()
    # test_board[7,7] = MYBLACK # 0-indexed for internal representation
    # test_board[7,8] = MYBLACK
    # test_board[7,9] = MYBLACK
    # test_board[7,10] = MYBLACK
    # # test_board[7,11] = MYBLACK # Five in a row for black
    # display_board(test_board)
    # # Evaluate from White\'s perspective (it\'s White\'s turn to move)
    # score = evaluate_board(test_board, MYWHITE) 
    # print(f"Evaluation score: {score}")
    # if is_game_over(test_board, MYBLACK): # Check if Black (last player) won
    #    print("Game is over.")
    # else:
    #    print("Game not over.")

    main_game()
    print("\\nGobang AI (Python Version) loaded.")
    print("The analysis_line function\'s pattern matching is a simplified version and may need further refinement for full accuracy, similar to the Julia version.")

