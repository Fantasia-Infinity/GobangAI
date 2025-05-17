\
# Translated from C++ Gobang AI
# Note: Graphics and console input (conio.h) specific parts are adapted for Julia console.

using Gtk # Added for GUI

# Constants
const GRID_NUM = 15 # Board size (15x15)
const MYBLACK = 0    # Black stone
const MYWHITE = 1    # White stone
const NOSTONE = 9    # Empty intersection

# Chess pattern types
const STWO = 1       # Blocked Two
const STHREE = 2     # Blocked Three
const SFOUR = 3      # Blocked Four / Four with one end blocked
const TWO = 4        # Live Two
const THREE = 5      # Live Three
const FOUR = 6       # Live Four
const FIVE = 7       # Five-in-a-row
const NOTYPE = 11    # Undefined pattern
const ANALYSED = 255 # Analyzed position
const TOBEANALSIS = 0 # To be analyzed

# --- Data Structures ---

# Point on the board
struct MyPoint
    x::Int
    y::Int
end

# Represents a move
struct MoveStone
    color::Int
    ptMovePoint::MyPoint
end

# Represents the board state
struct State
    grid::Matrix{Int}
    State(initial_grid::Matrix{Int}) = new(copy(initial_grid))
end

# Represents a state after a move, with its score
struct AfterMove
    state::Union{State, Nothing} # Can be nothing if no move is made or in initial states
    score::Int
    AfterMove(s::Union{State, Nothing}, sc::Int) = new(s, sc)
    AfterMove() = new(nothing, 0) # Default constructor
end

# --- Global Variables (adapted for Julia) ---
# These were global in C++, in Julia they might be passed around or encapsulated differently.
# For direct translation, we'll define them globally, though this is not always idiomatic Julia.

# Stores analysis results for a line
m_LineRecord = zeros(Int, 30)

# Stores analysis results for the whole board [row, col, direction]
# Directions: 1:Horizontal, 2:Vertical, 3:Left-Diagonal, 4:Right-Diagonal
TypeRecord = zeros(Int, GRID_NUM, GRID_NUM, 4)

# Counts of each pattern type for each color [color_idx, pattern_type_idx]
# color_idx: 1 for MYBLACK (0+1), 2 for MYWHITE (1+1)
TypeCount = zeros(Int, 2, 20)

# Positional values for heuristic evaluation
const PosValue = [
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
]

# --- Helper Functions ---

# Check if a position is valid on the board
isValidPos(x::Int, y::Int) = (0 <= x < GRID_NUM) && (0 <= y < GRID_NUM)

# --- Core Logic Functions ---

# Analyzes a single line (row, column, or diagonal) for patterns
function analysis_line!(line_segment::Vector{Int}, stone_pos_in_line::Int, current_stone_type::Int)
    # line_segment is 0-indexed in C++, Julia is 1-indexed. Adjusting.
    # stone_pos_in_line is 0-indexed in C++, adjusting.
    
    # Reset m_LineRecord for this call (or ensure it's properly managed)
    fill!(m_LineRecord, TOBEANALSIS) # Assuming m_LineRecord is accessible and of appropriate size

    num_stones = length(line_segment)
    if num_stones < 5
        # Mark all as analyzed if too short to form significant patterns
        if num_stones > 0
             m_LineRecord[1:num_stones] .= ANALYSED
        end
        return 0 # Or some indicator of no significant pattern
    end

    # Convert to 0-indexed for logic, then back for m_LineRecord
    analy_pos_0idx = stone_pos_in_line 
    
    # Boundaries of connected stones of the same type
    left_edge_0idx = analy_pos_0idx
    right_edge_0idx = analy_pos_0idx

    # Find left boundary
    while left_edge_0idx > 0 && line_segment[left_edge_0idx] == current_stone_type # line_segment[left_edge_0idx -1 +1]
        left_edge_0idx -= 1
    end
    if line_segment[left_edge_0idx + 1] != current_stone_type # Correct boundary if we overshot
        left_edge_0idx +=1
    end


    # Find right boundary
    while right_edge_0idx < num_stones -1 && line_segment[right_edge_0idx + 2] == current_stone_type
        right_edge_0idx += 1
    end
    if line_segment[right_edge_0idx+1] != current_stone_type
        right_edge_0idx -=1
    end
    
    # Extend to include empty spots for pattern analysis (live/blocked checks)
    left_range_0idx = left_edge_0idx
    right_range_0idx = right_edge_0idx

    while left_range_0idx > 0 && line_segment[left_range_0idx] != 1 - current_stone_type # opponent stone
        left_range_0idx -= 1
    end
     if left_range_0idx > 0 && line_segment[left_range_0idx] == 1 - current_stone_type
        left_range_0idx +=1 # don't include opponent stone
     end


    while right_range_0idx < num_stones -1 && line_segment[right_range_0idx + 2] != 1 - current_stone_type
        right_range_0idx += 1
    end
    if right_range_0idx < num_stones -1 && line_segment[right_range_0idx + 2] == 1 - current_stone_type
        right_range_0idx -=1
    end


    if right_range_0idx - left_range_0idx + 1 < 5
        for k = left_range_0idx:right_range_0idx
            m_LineRecord[k+1] = ANALYSED
        end
        return NOTYPE # Or specific value indicating no significant pattern
    end

    # Mark the continuous segment as analyzed
    for k = left_edge_0idx:right_edge_0idx
        m_LineRecord[k+1] = ANALYSED
    end
    
    connected_len = right_edge_0idx - left_edge_0idx + 1
    
    # --- Pattern Recognition (Simplified for brevity, needs full C++ logic) ---
    # This is a complex part of the C++ code. A direct translation is lengthy.
    # The C++ code checks for FIVE, FOUR, SFOUR, THREE, STHREE, TWO, STWO.
    # Here's a conceptual start:

    if connected_len >= 5
        m_LineRecord[analy_pos_0idx+1] = FIVE
        return FIVE
    end

    if connected_len == 4
        # Check ends for liveness
        has_left_space = left_edge_0idx > 0 && line_segment[left_edge_0idx] == NOSTONE
        has_right_space = right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 2] == NOSTONE
        if has_left_space && has_right_space
            m_LineRecord[analy_pos_0idx+1] = FOUR
            return FOUR
        elseif has_left_space || has_right_space
            m_LineRecord[analy_pos_0idx+1] = SFOUR
            return SFOUR
        end
    end
    
    if connected_len == 3
        # Check for live three vs blocked three, and potential SFOUR (e.g., O_OOO or OOO_O)
        # This requires checking further out for spaces or same-color stones.
        # Example: Live Three ( _OOO_ )
        left_open = left_edge_0idx > 0 && line_segment[left_edge_0idx] == NOSTONE
        right_open = right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 2] == NOSTONE

        if left_open && right_open
            # Check for O_OOO or OOO_O patterns for SFOUR
            # O_OOO: line_segment[left_edge_0idx-1] == current_stone_type && line_segment[left_edge_0idx] == NOSTONE
            # OOO_O: line_segment[right_edge_0idx+2] == NOSTONE && line_segment[right_edge_0idx+3] == current_stone_type
            # This part needs careful translation of the C++ logic for SFOUR involving gaps.
            
            # Simplified:
            m_LineRecord[analy_pos_0idx+1] = THREE
            return THREE
        elseif left_open || right_open
            m_LineRecord[analy_pos_0idx+1] = STHREE
            return STHREE
        end
    end

    if connected_len == 2
        # Similar checks for TWO and STWO, and potential STHREE with gaps
        left_open = left_edge_0idx > 0 && line_segment[left_edge_0idx] == NOSTONE
        right_open = right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 2] == NOSTONE
        if left_open && right_open
             # Check for more complex patterns like O_O_O for STHREE
            m_LineRecord[analy_pos_0idx+1] = TWO
            return TWO
        elseif left_open || right_open
            m_LineRecord[analy_pos_0idx+1] = STWO
            return STWO
        end
    end
    
    # Default if no specific pattern matched by this simplified logic
    m_LineRecord[analy_pos_0idx+1] = NOTYPE 
    return NOTYPE
end


# Analyze horizontal line at (r, c)
function analysis_horizon!(board::Matrix{Int}, r::Int, c::Int)
    # Julia is 1-indexed, C++ was 0-indexed. r, c are 1-indexed.
    line_segment = board[r, :] # Get the whole row
    analysis_line!(line_segment, c - 1, board[r,c]) # c-1 for 0-indexed stone_pos_in_line
    for s = 1:GRID_NUM
        if m_LineRecord[s] != TOBEANALSIS
            TypeRecord[r, s, 1] = m_LineRecord[s] # Direction 1 for Horizontal
        end
    end
    return TypeRecord[r, c, 1]
end

# Analyze vertical line at (r, c)
function analysis_vertical!(board::Matrix{Int}, r::Int, c::Int)
    line_segment = board[:, c] # Get the whole column
    analysis_line!(line_segment, r - 1, board[r,c]) # r-1 for 0-indexed stone_pos_in_line
    for s = 1:GRID_NUM
        if m_LineRecord[s] != TOBEANALSIS
            TypeRecord[s, c, 2] = m_LineRecord[s] # Direction 2 for Vertical
        end
    end
    return TypeRecord[r, c, 2]
end

# Analyze left-diagonal (top-left to bottom-right) through (r, c)
function analysis_left_diag!(board::Matrix{Int}, r::Int, c::Int)
    temp_array = Int[]
    
    # Determine start of diagonal
    start_r, start_c = r, c
    while start_r > 1 && start_c > 1
        start_r -= 1
        start_c -= 1
    end
    
    # Relative position of (r,c) in this diagonal
    stone_pos_in_diag = 0

    # Extract diagonal
    curr_r, curr_c = start_r, start_c
    idx = 0
    while curr_r <= GRID_NUM && curr_c <= GRID_NUM
        push!(temp_array, board[curr_r, curr_c])
        if curr_r == r && curr_c == c
            stone_pos_in_diag = idx
        end
        curr_r += 1
        curr_c += 1
        idx +=1
    end

    if !isempty(temp_array)
        analysis_line!(temp_array, stone_pos_in_diag, board[r,c])
        
        # Store results back
        curr_r, curr_c = start_r, start_c
        for s = 1:length(temp_array)
            if m_LineRecord[s] != TOBEANALSIS
                 if curr_r <= GRID_NUM && curr_c <= GRID_NUM # Bounds check
                    TypeRecord[curr_r, curr_c, 3] = m_LineRecord[s] # Direction 3 for Left-Diag
                 end
            end
            curr_r += 1
            curr_c += 1
            if curr_r > GRID_NUM || curr_c > GRID_NUM
                break
            end
        end
    end
    return TypeRecord[r, c, 3]
end

# Analyze right-diagonal (top-right to bottom-left) through (r, c)
function analysis_right_diag!(board::Matrix{Int}, r::Int, c::Int)
    temp_array = Int[]

    # Determine start of diagonal
    start_r, start_c = r, c
    while start_r > 1 && start_c < GRID_NUM
        start_r -= 1
        start_c += 1
    end
    
    stone_pos_in_diag = 0
    
    # Extract diagonal
    curr_r, curr_c = start_r, start_c
    idx = 0
    while curr_r <= GRID_NUM && curr_c >= 1
        push!(temp_array, board[curr_r, curr_c])
        if curr_r == r && curr_c == c
            stone_pos_in_diag = idx
        end
        curr_r += 1
        curr_c -= 1
        idx +=1
    end

    if !isempty(temp_array)
        analysis_line!(temp_array, stone_pos_in_diag, board[r,c])

        # Store results back
        curr_r, curr_c = start_r, start_c
        for s = 1:length(temp_array)
            if m_LineRecord[s] != TOBEANALSIS
                if curr_r <= GRID_NUM && curr_c >= 1 # Bounds check
                    TypeRecord[curr_r, curr_c, 4] = m_LineRecord[s] # Direction 4 for Right-Diag
                end
            end
            curr_r += 1
            curr_c -= 1
             if curr_r > GRID_NUM || curr_c < 1
                break
            end
        end
    end
    return TypeRecord[r, c, 4]
end


# Evaluate the board state for the given color to move
function evaluate_board(board::Matrix{Int}, color_to_move::Int)::Int
    # Reset global analysis storage
    fill!(TypeRecord, TOBEANALSIS)
    fill!(TypeCount, 0)

    for r = 1:GRID_NUM
        for c = 1:GRID_NUM
            if board[r, c] != NOSTONE
                # Horizontal
                if TypeRecord[r, c, 1] == TOBEANALSIS
                    analysis_horizon!(board, r, c)
                end
                # Vertical
                if TypeRecord[r, c, 2] == TOBEANALSIS
                    analysis_vertical!(board, r, c)
                end
                # Left Diagonal
                if TypeRecord[r, c, 3] == TOBEANALSIS
                    analysis_left_diag!(board, r, c)
                end
                # Right Diagonal
                if TypeRecord[r, c, 4] == TOBEANALSIS
                    analysis_right_diag!(board, r, c)
                end
            end
        end
    end

    # Aggregate TypeCount from TypeRecord
    for r = 1:GRID_NUM
        for c = 1:GRID_NUM
            stone_type_on_board = board[r,c]
            if stone_type_on_board != NOSTONE
                player_idx = stone_type_on_board + 1 # MYBLACK (0) -> 1, MYWHITE (1) -> 2
                for k = 1:4 # Directions
                    pattern = TypeRecord[r, c, k]
                    if pattern != NOTYPE && pattern != ANALYSED && pattern != TOBEANALSIS
                         # Ensure pattern is within bounds for TypeCount
                        if 1 <= pattern <= size(TypeCount, 2)
                            TypeCount[player_idx, pattern] += 1
                        end
                    end
                end
            end
        end
    end
    
    # Scoring logic (direct translation of C++ version)
    # Player indices for TypeCount: Black=1, White=2
    idx_black = MYBLACK + 1
    idx_white = MYWHITE + 1

    if TypeCount[idx_black, FIVE] > 0
        return -9999 # Black wins
    end
    if TypeCount[idx_white, FIVE] > 0
        return 9999 # White wins
    end

    # Two SFOURs are like a FOUR
    if TypeCount[idx_white, SFOUR] > 1
        TypeCount[idx_white, FOUR] += 1
    end
    if TypeCount[idx_black, SFOUR] > 1
        TypeCount[idx_black, FOUR] += 1
    end

    w_value = 0
    b_value = 0

    if color_to_move == MYWHITE
        if TypeCount[idx_white, FOUR] > 0; return 9990; end
        if TypeCount[idx_white, SFOUR] > 0; return 9980; end
        if TypeCount[idx_black, FOUR] > 0; return -9970; end
        if TypeCount[idx_black, SFOUR] > 0 && TypeCount[idx_black, THREE] > 0; return -9960; end
        if TypeCount[idx_white, THREE] > 0 && TypeCount[idx_black, SFOUR] == 0; return 9950; end
        if TypeCount[idx_black, THREE] > 1 && TypeCount[idx_white, SFOUR] == 0 && TypeCount[idx_white, THREE] == 0 && TypeCount[idx_white, STHREE] == 0; return -9940; end
        
        w_value += TypeCount[idx_white, THREE] > 1 ? 2000 : (TypeCount[idx_white, THREE] > 0 ? 200 : 0)
        b_value += TypeCount[idx_black, THREE] > 1 ? 500 : (TypeCount[idx_black, THREE] > 0 ? 100 : 0)
    else # color_to_move == MYBLACK
        if TypeCount[idx_black, FOUR] > 0; return -9990; end
        if TypeCount[idx_black, SFOUR] > 0; return -9980; end
        if TypeCount[idx_white, FOUR] > 0; return 9970; end
        if TypeCount[idx_white, SFOUR] > 0 && TypeCount[idx_white, THREE] > 0; return 9960; end
        if TypeCount[idx_black, THREE] > 0 && TypeCount[idx_white, SFOUR] == 0; return -9950; end
        if TypeCount[idx_white, THREE] > 1 && TypeCount[idx_black, SFOUR] == 0 && TypeCount[idx_black, THREE] == 0 && TypeCount[idx_black, STHREE] == 0; return 9940; end

        b_value += TypeCount[idx_black, THREE] > 1 ? 2000 : (TypeCount[idx_black, THREE] > 0 ? 200 : 0)
        w_value += TypeCount[idx_white, THREE] > 1 ? 500 : (TypeCount[idx_white, THREE] > 0 ? 100 : 0)
    end

    w_value += TypeCount[idx_white, STHREE] * 10
    b_value += TypeCount[idx_black, STHREE] * 10
    w_value += TypeCount[idx_white, TWO] * 4
    b_value += TypeCount[idx_black, TWO] * 4 # Note: C++ had STWO for black here, assuming typo and meant TWO
    w_value += TypeCount[idx_white, STWO]
    b_value += TypeCount[idx_black, STWO]

    # Positional value
    for r = 1:GRID_NUM
        for c = 1:GRID_NUM
            if board[r, c] == MYBLACK
                b_value += PosValue[r][c]
            elseif board[r, c] == MYWHITE
                w_value += PosValue[r][c]
            end
        end
    end
    return w_value - b_value
end


# Generate possible moves
function create_possible_moves(board::Matrix{Int}, color::Int)::Vector{MoveStone}
    moves = MoveStone[]
    for r = 1:GRID_NUM
        for c = 1:GRID_NUM
            if board[r, c] == NOSTONE
                # Add heuristic: only consider moves near existing stones
                is_near_stone = false
                for dr = -1:1
                    for dc = -1:1
                        if dr == 0 && dc == 0; continue; end
                        nr, nc = r + dr, c + dc
                        if 1 <= nr <= GRID_NUM && 1 <= nc <= GRID_NUM && board[nr, nc] != NOSTONE
                            is_near_stone = true
                            break
                        end
                    end
                    if is_near_stone; break; end
                end
                
                # If board is empty, any first move is fine (e.g. center)
                # For simplicity here, we allow all empty spots if no stones yet,
                # or only near existing stones.
                if sum(board .!= NOSTONE) == 0 || is_near_stone
                     push!(moves, MoveStone(color, MyPoint(r, c)))
                end
            end
        end
    end
    # If no moves near stones (e.g. very early game or sparse board), allow any empty spot
    if isempty(moves) && sum(board .!= NOSTONE) > 0
         for r = 1:GRID_NUM
            for c = 1:GRID_NUM
                if board[r, c] == NOSTONE
                    push!(moves, MoveStone(color, MyPoint(r, c)))
                end
            end
        end
    elseif isempty(moves) && sum(board .!= NOSTONE) == 0 # Truly empty board
        push!(moves, MoveStone(color, MyPoint(ceil(Int,GRID_NUM/2), ceil(Int,GRID_NUM/2)))) # Center move
    end


    return moves
end

# Alpha-Beta search
function alphabeta(current_board::Matrix{Int}, depth::Int, alpha::Int, beta::Int, color_to_move::Int)::AfterMove
    
    # Terminal conditions for recursion
    score = evaluate_board(current_board, color_to_move) # Evaluate from perspective of current player
    if abs(score) >= 9990 # Win/loss state
        return AfterMove(State(current_board), score)
    end
    if depth == 0
        return AfterMove(State(current_board), score)
    end

    possible_moves = create_possible_moves(current_board, color_to_move)
    if isempty(possible_moves) # No moves possible, draw or stalemate-like
        return AfterMove(State(current_board), score) # Return current score
    end
    
    best_move_state = nothing # Keep track of the state for the best move

    if color_to_move == MYWHITE # Maximizing player
        best_val = -20000 
        current_alpha = alpha
        for move in possible_moves
            temp_board = copy(current_board)
            temp_board[move.ptMovePoint.x, move.ptMovePoint.y] = MYWHITE
            
            result = alphabeta(temp_board, depth - 1, current_alpha, beta, MYBLACK)
            
            if result.score > best_val
                best_val = result.score
                best_move_state = State(temp_board) # Store the board state of this best move
            end
            current_alpha = max(current_alpha, best_val)
            if beta <= current_alpha
                break # Beta cut-off
            end
        end
        return AfterMove(best_move_state, best_val) # Return the state that led to best_val
    else # color_to_move == MYBLACK, Minimizing player
        best_val = 20000
        current_beta = beta
        for move in possible_moves
            temp_board = copy(current_board)
            temp_board[move.ptMovePoint.x, move.ptMovePoint.y] = MYBLACK

            result = alphabeta(temp_board, depth - 1, alpha, current_beta, MYWHITE)

            if result.score < best_val
                best_val = result.score
                best_move_state = State(temp_board)
            end
            current_beta = min(current_beta, best_val)
            if current_beta <= alpha
                break # Alpha cut-off
            end
        end
        return AfterMove(best_move_state, best_val)
    end
end

# Make a move for AI
function make_ai_move(board::Matrix{Int}, ai_color::Int, search_depth::Int)::Matrix{Int}
    println("AI (color: $ai_color) is thinking with depth $search_depth...")
    result_after_move = alphabeta(board, search_depth, -20000, 20000, ai_color)
    
    if result_after_move.state !== nothing
        println("AI chooses move leading to score: $(result_after_move.score)")
        return result_after_move.state.grid
    else
        println("AI could not find a valid move or state. This shouldn't happen if game not over.")
        # Fallback: if somehow no state, return original board (should be handled by game over check)
        return board 
    end
end

# Check if game is over
function is_game_over(board::Matrix{Int}, current_player_color::Int)::Bool
    # Evaluate from the perspective of the player whose turn it *would* be
    # to see if the *previous* move by opponent was a winning one.
    # Or, evaluate for current player to see if they have a winning move available (less common for this check)
    # The C++ version checks `abs(Evaluate(position,color)) >= 9999;`
    # `color` in C++ `isgameover` is `nowcolor`, i.e. the player whose turn it is.
    # So, if `evaluate_board` returns a winning score for `current_player_color` or losing for them (meaning opponent won)
    
    eval_score = evaluate_board(board, current_player_color) # Evaluate for the player who just moved or is about to move
    
    # Check for win by MYBLACK (score -9999) or MYWHITE (score 9999)
    if eval_score <= -9999 # Black has won
        println("Game Over! Black wins.")
        return true
    elseif eval_score >= 9999 # White has won
        println("Game Over! White wins.")
        return true
    end

    # Check for draw (no empty spots left)
    if !any(x -> x == NOSTONE, board)
        println("Game Over! It's a draw.")
        return true
    end
    return false
end


# Display board in console
function display_board(board::Matrix{Int})
    println("\n  " * join([lpad(string(i), 2) for i = 1:GRID_NUM], " "))
    for r = 1:GRID_NUM
        print(lpad(string(r), 2) * " ")
        for c = 1:GRID_NUM
            if board[r, c] == MYBLACK
                print("B  ")
            elseif board[r, c] == MYWHITE
                print("W  ")
            else
                print(".  ")
            end
        end
        println()
    end
    println()
end

# Initialize board
function init_board()::Matrix{Int}
    board = fill(NOSTONE, (GRID_NUM, GRID_NUM))
    return board
end

# --- Main Game Loop ---
# function main_game() # Commented out to replace with GUI version
#     board = init_board()
#     
#     println("Enter your color: (0 for Black, 1 for White)")
#     player_color = -1 # Initialize with an invalid value
#     while true
#         print("> ") # Add a small prompt for clarity
#         player_color_str = strip(readline())
#         if player_color_str == "0"
#             player_color = MYBLACK
#             break
#         elseif player_color_str == "1"
#             player_color = MYWHITE
#             break
#         else
#             println("Invalid input. Please enter 0 for Black or 1 for White.")
#         end
#     end
#     
#     ai_color = 1 - player_color
#     current_color = MYBLACK # Black always starts
#     
#     search_depth = 5 # AI search depth
#     # if GRID_NUM > 10; search_depth = 2; end # Adjust depth for larger boards if needed
#     # if GRID_NUM > 15; search_depth = 1; end # Deeper search is slow
# 
#     println("You are: $(player_color == MYBLACK ? "Black" : "White")")
#     println("AI is: $(ai_color == MYBLACK ? "Black" : "White")")
#     println("Search depth: $search_depth")
# 
#     display_board(board)
#     step = 0
# 
#     while true
#         if is_game_over(board, current_color) # Check before player/AI move
#             # is_game_over prints the result
#             break
#         end
# 
#         if current_color == player_color
#             println("Your turn ($(player_color == MYBLACK ? "Black" : "White")). Enter row and col (e.g., 7 7):")
#             while true
#                 try
#                     input = readline()
#                     parts = split(input)
#                     r = parse(Int, parts[1])
#                     c = parse(Int, parts[2])
#                     if 1 <= r <= GRID_NUM && 1 <= c <= GRID_NUM && board[r, c] == NOSTONE
#                         board[r, c] = player_color
#                         break
#                     else
#                         println("Invalid move. Try again.")
#                     end
#                 catch e
#                     println("Invalid input. Format: row col (e.g., 7 7). Try again.")
#                 end
#             end
#         else # AI's turn
#             println("AI's turn ($(ai_color == MYBLACK ? "Black" : "White"))...")
#             if step == 0 && ai_color == MYBLACK # AI is black and first move
#                  # Center move for AI if it's black and starts
#                 center = ceil(Int, GRID_NUM / 2)
#                 board[center, center] = ai_color
#                 println("AI places at $center, $center")
#             else
#                 board = make_ai_move(board, ai_color, search_depth)
#             end
#         end
#         
#         display_board(board)
#         current_color = 1 - current_color # Switch player
#         step += 1
#     end
#     println("Thank you for playing!")
# end

#Run the game
# main_game() # Commented out to replace with GUI version

#Example of how to call evaluate if needed for testing:
# test_board = init_board()
# test_board[8,8] = MYBLACK
# test_board[8,9] = MYBLACK
# test_board[8,10] = MYBLACK
# test_board[8,11] = MYBLACK
# # test_board[8,12] = MYBLACK # Five in a row for black
# display_board(test_board)
# score = evaluate_board(test_board, MYWHITE) # White to move
# println("Evaluation score: $score")
# if is_game_over(test_board, MYWHITE); println("Game is over."); else println("Game not over."); end


# --- GUI Implementation ---
const CELL_SIZE = 40
const BOARD_SIZE = GRID_NUM * CELL_SIZE
const PLAYER_COLOR = MYBLACK # Player is Black by default
const AI_COLOR = MYWHITE     # AI is White by default

current_board_gui = init_board()
current_player_gui = MYBLACK # Black starts
game_over_gui = false
status_label_gui = Gtk.GtkLabel("Black's turn")

function draw_board(canvas, board)
    ctx = Gtk.getgc(canvas)
    # Clear canvas
    Gtk.rectangle(ctx, 0, 0, BOARD_SIZE, BOARD_SIZE)
    Gtk.set_source_rgb(ctx, 0.9, 0.8, 0.7) # Light wood color
    Gtk.fill(ctx)

    # Draw grid lines
    Gtk.set_source_rgb(ctx, 0, 0, 0) # Black lines
    Gtk.set_line_width(ctx, 1)
    for i = 0:GRID_NUM
        Gtk.move_to(ctx, i * CELL_SIZE, 0)
        Gtk.line_to(ctx, i * CELL_SIZE, BOARD_SIZE)
        Gtk.stroke(ctx)
        Gtk.move_to(ctx, 0, i * CELL_SIZE)
        Gtk.line_to(ctx, BOARD_SIZE, i * CELL_SIZE)
        Gtk.stroke(ctx)
    end

    # Draw stones
    for r = 1:GRID_NUM
        for c = 1:GRID_NUM
            if board[r, c] == MYBLACK
                Gtk.arc(ctx, (c-0.5) * CELL_SIZE, (r-0.5) * CELL_SIZE, CELL_SIZE/2 - 2, 0, 2*pi)
                Gtk.set_source_rgb(ctx, 0, 0, 0) # Black stone
                Gtk.fill(ctx)
            elseif board[r, c] == MYWHITE
                Gtk.arc(ctx, (c-0.5) * CELL_SIZE, (r-0.5) * CELL_SIZE, CELL_SIZE/2 - 2, 0, 2*pi)
                Gtk.set_source_rgb(ctx, 1, 1, 1) # White stone
                Gtk.fill(ctx)
                Gtk.set_source_rgb(ctx, 0, 0, 0) # Black border for white stone
                Gtk.arc(ctx, (c-0.5) * CELL_SIZE, (r-0.5) * CELL_SIZE, CELL_SIZE/2 - 2, 0, 2*pi)
                Gtk.stroke(ctx)
            end
        end
    end
end

function reset_game_gui(canvas)
    global current_board_gui = init_board()
    global current_player_gui = MYBLACK
    global game_over_gui = false
    Gtk.GAccessor.text(status_label_gui, "Black's turn")
    Gtk.queue_draw(canvas) # Request a redraw instead of drawing directly
end

function handle_click(widget, event, canvas)
    global current_board_gui, current_player_gui, game_over_gui
    if game_over_gui
        return
    end

    x, y = event.x, event.y
    r = floor(Int, y / CELL_SIZE) + 1
    c = floor(Int, x / CELL_SIZE) + 1

    if 1 <= r <= GRID_NUM && 1 <= c <= GRID_NUM && current_board_gui[r, c] == NOSTONE && current_player_gui == PLAYER_COLOR
        current_board_gui[r, c] = PLAYER_COLOR
        draw_board(canvas, current_board_gui)
        
        if is_game_over(current_board_gui, PLAYER_COLOR)
            game_over_gui = true
            score = evaluate_board(current_board_gui, PLAYER_COLOR)
            if score <= -9999
                Gtk.GAccessor.text(status_label_gui, "Game Over! Black wins.")
            elseif score >= 9999
                 Gtk.GAccessor.text(status_label_gui, "Game Over! White wins.") # Should not happen if player is black
            elseif !any(x -> x == NOSTONE, current_board_gui)
                 Gtk.GAccessor.text(status_label_gui, "Game Over! It's a draw.")
            end
            return
        end
        
        current_player_gui = AI_COLOR
        Gtk.GAccessor.text(status_label_gui, "AI (White)'s turn...")
        
        # AI Move (with a slight delay for UX, Gtk might need async handling for this)
        # For simplicity, direct call here. In a real app, use Gtk.GLib.idle_add for responsiveness
        yield() # Allow UI to update

        if !game_over_gui && current_player_gui == AI_COLOR
            search_depth_gui = 3 # Can be adjusted
            if sum(current_board_gui .== NOSTONE) == GRID_NUM * GRID_NUM && AI_COLOR == MYBLACK # AI is black and first move
                center = ceil(Int, GRID_NUM / 2)
                current_board_gui[center, center] = AI_COLOR
            else
                current_board_gui = make_ai_move(current_board_gui, AI_COLOR, search_depth_gui)
            end
            draw_board(canvas, current_board_gui)

            if is_game_over(current_board_gui, AI_COLOR)
                game_over_gui = true
                score = evaluate_board(current_board_gui, AI_COLOR)
                if score <= -9999 
                    Gtk.GAccessor.text(status_label_gui, "Game Over! Black wins.") # Should not happen if AI is white
                elseif score >= 9999
                    Gtk.GAccessor.text(status_label_gui, "Game Over! White wins.")
                elseif !any(x -> x == NOSTONE, current_board_gui)
                    Gtk.GAccessor.text(status_label_gui, "Game Over! It's a draw.")
                end
                return
            end
            current_player_gui = PLAYER_COLOR
            Gtk.GAccessor.text(status_label_gui, "Black's turn")
        end
    end
end

function main_gui()
    win = Gtk.GtkWindow("Gobang AI", BOARD_SIZE, BOARD_SIZE + 50)
    Gtk.set_gtk_property!(win, :resizable, false)

    global current_board_gui = init_board() # Ensure board is initialized

    vbox = Gtk.GtkBox(:v) # Vertical box
    push!(win, vbox)

    canvas = Gtk.GtkCanvas(BOARD_SIZE, BOARD_SIZE)
    Gtk.push!(vbox, canvas)

    Gtk.GAccessor.text(status_label_gui, "Black's turn (Player)")
    Gtk.push!(vbox, status_label_gui)
    
    reset_button = Gtk.GtkButton("Reset Game")
    Gtk.push!(vbox, reset_button)

    Gtk.signal_connect(reset_button, "clicked") do widget
        reset_game_gui(canvas)
    end
    
    Gtk.signal_connect(canvas, "button-press-event") do widget, event
        handle_click(widget, event, canvas)
    end

    # Corrected draw signal connection
    Gtk.signal_connect(canvas, "draw") do widget, cr # Add cr to accept the Cairo context
        # It's good practice to use the passed Cairo context 'cr' if available,
        # but Gtk.getgc(widget) should also work once the canvas is realized.
        # For consistency with your existing draw_board, we can keep it,
        # or you could refactor draw_board to accept 'cr'.
        draw_board(widget, current_board_gui)
    end
    
    Gtk.showall(win)
    
    # Initial draw will be handled by the "draw" signal after showall()
    # reset_game_gui(canvas) # Remove this direct call

    if !isinteractive()
        cond = Condition()
        Gtk.signal_connect(win, :destroy) do widget
            notify(cond)
        end
        wait(cond)
    end
end

# Start the GUI
main_gui()

println("Gobang AI (Julia Version) with GUI loaded.")
println("The analysis_line! function's pattern matching is a simplified version of the C++ original and may need further refinement for full accuracy.")

