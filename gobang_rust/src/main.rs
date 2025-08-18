'''
// Translated from Python Gobang AI (which was translated from Julia/C++)

use std::io;

// Constants
const GRID_NUM: usize = 15;
const MYBLACK: i32 = 0;
const MYWHITE: i32 = 1;
const NOSTONE: i32 = 9;

// Chess pattern types
const STWO: i32 = 1;
const STHREE: i32 = 2;
const SFOUR: i32 = 3;
const TWO: i32 = 4;
const THREE: i32 = 5;
const FOUR: i32 = 6;
const FIVE: i32 = 7;
const NOTYPE: i32 = 11;
const ANALYSED: i32 = 255;
const TOBEANALSIS: i32 = 0;

// --- Data Structures ---

#[derive(Clone, Copy)]
struct MyPoint {
    x: usize,
    y: usize,
}

struct MoveStone {
    color: i32,
    pt_move_point: MyPoint,
}

#[derive(Clone)]
struct State {
    grid: [[i32; GRID_NUM]; GRID_NUM],
}

struct AfterMove {
    state: Option<State>,
    score: i32,
}

// --- Global Variables (like) ---
// In Rust, we avoid mutable global state. We'll pass these as parameters.

// --- Helper Functions ---

fn is_valid_pos(x: usize, y: usize) -> bool {
    x < GRID_NUM && y < GRID_NUM
}

// --- Core Logic Functions ---

fn analysis_line(
    line_segment: &[i32],
    stone_pos_in_line: usize,
    current_stone_type: i32,
    m_line_record: &mut [i32],
) -> i32 {
    m_line_record.fill(TOBEANALSIS);

    let num_stones = line_segment.len();
    if num_stones < 5 {
        if num_stones > 0 {
            m_line_record[..num_stones].fill(ANALYSED);
        }
        return NOTYPE;
    }

    let analy_pos_0idx = stone_pos_in_line;

    let mut left_edge_0idx = analy_pos_0idx;
    let mut right_edge_0idx = analy_pos_0idx;

    // Find left boundary
    while left_edge_0idx > 0 && line_segment[left_edge_0idx - 1] == current_stone_type {
        left_edge_0idx -= 1;
    }

    // Find right boundary
    while right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 1] == current_stone_type {
        right_edge_0idx += 1;
    }

    let connected_len = right_edge_0idx - left_edge_0idx + 1;

    // Mark the continuous segment as analyzed
    m_line_record[left_edge_0idx..=right_edge_0idx].fill(ANALYSED);

    if connected_len >= 5 {
        m_line_record[analy_pos_0idx] = FIVE;
        return FIVE;
    }

    if connected_len == 4 {
        let has_left_space = (left_edge_0idx > 0 && line_segment[left_edge_0idx - 1] == NOSTONE)
            || (left_edge_0idx == 0);
        let has_right_space = (right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 1] == NOSTONE)
            || (right_edge_0idx == num_stones - 1);

        if has_left_space && has_right_space {
            m_line_record[analy_pos_0idx] = FOUR;
            return FOUR;
        } else if has_left_space || has_right_space {
            m_line_record[analy_pos_0idx] = SFOUR;
            return SFOUR;
        }
    }

    if connected_len == 3 {
        let left_open = left_edge_0idx > 0 && line_segment[left_edge_0idx - 1] == NOSTONE;
        let right_open = right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 1] == NOSTONE;

        if left_open && right_open {
            m_line_record[analy_pos_0idx] = THREE;
            return THREE;
        } else if left_open || right_open {
            m_line_record[analy_pos_0idx] = STHREE;
            return STHREE;
        }
    }

    if connected_len == 2 {
        let left_open = left_edge_0idx > 0 && line_segment[left_edge_0idx - 1] == NOSTONE;
        let right_open = right_edge_0idx < num_stones - 1 && line_segment[right_edge_0idx + 1] == NOSTONE;

        if left_open && right_open {
            m_line_record[analy_pos_0idx] = TWO;
            return TWO;
        } else if left_open || right_open {
            m_line_record[analy_pos_0idx] = STWO;
            return STWO;
        }
    }

    m_line_record[analy_pos_0idx] = NOTYPE;
    NOTYPE
}

fn analysis_horizon(board: &[[i32; GRID_NUM]; GRID_NUM], r: usize, c: usize, type_record: &mut [[[[i32; 4]; GRID_NUM]; GRID_NUM]]) -> i32 {
    let mut m_line_record = [0; 30];
    let line_segment: Vec<i32> = board[r].to_vec();
    analysis_line(&line_segment, c, board[r][c], &mut m_line_record);
    for s in 0..GRID_NUM {
        if m_line_record[s] != TOBEANALSIS {
            type_record[r][s][0] = m_line_record[s];
        }
    }
    type_record[r][c][0]
}

fn analysis_vertical(board: &[[i32; GRID_NUM]; GRID_NUM], r: usize, c: usize, type_record: &mut [[[[i32; 4]; GRID_NUM]; GRID_NUM]]) -> i32 {
    let mut m_line_record = [0; 30];
    let line_segment: Vec<i32> = (0..GRID_NUM).map(|i| board[i][c]).collect();
    analysis_line(&line_segment, r, board[r][c], &mut m_line_record);
    for s in 0..GRID_NUM {
        if m_line_record[s] != TOBEANALSIS {
            type_record[s][c][1] = m_line_record[s];
        }
    }
    type_record[r][c][1]
}

fn analysis_left_diag(board: &[[i32; GRID_NUM]; GRID_NUM], r: usize, c: usize, type_record: &mut [[[[i32; 4]; GRID_NUM]; GRID_NUM]]) -> i32 {
    let mut m_line_record = [0; 30];
    let mut temp_array_list = Vec::new();
    let (mut start_r, mut start_c) = (r, c);
    while start_r > 0 && start_c > 0 {
        start_r -= 1;
        start_c -= 1;
    }

    let mut stone_pos_in_diag = 0;
    let (mut curr_r, mut curr_c) = (start_r, start_c);
    let mut idx = 0;
    while curr_r < GRID_NUM && curr_c < GRID_NUM {
        temp_array_list.push(board[curr_r][curr_c]);
        if curr_r == r && curr_c == c {
            stone_pos_in_diag = idx;
        }
        curr_r += 1;
        curr_c += 1;
        idx += 1;
    }

    if !temp_array_list.is_empty() {
        analysis_line(&temp_array_list, stone_pos_in_diag, board[r][c], &mut m_line_record);
        let (mut curr_r, mut curr_c) = (start_r, start_c);
        for s in 0..temp_array_list.len() {
            if m_line_record[s] != TOBEANALSIS {
                if curr_r < GRID_NUM && curr_c < GRID_NUM {
                    type_record[curr_r][curr_c][2] = m_line_record[s];
                }
            }
            curr_r += 1;
            curr_c += 1;
            if curr_r >= GRID_NUM || curr_c >= GRID_NUM {
                break;
            }
        }
    }
    type_record[r][c][2]
}

fn analysis_right_diag(board: &[[i32; GRID_NUM]; GRID_NUM], r: usize, c: usize, type_record: &mut [[[[i32; 4]; GRID_NUM]; GRID_NUM]]) -> i32 {
    let mut m_line_record = [0; 30];
    let mut temp_array_list = Vec::new();
    let (mut start_r, mut start_c) = (r, c);
    while start_r > 0 && start_c < GRID_NUM - 1 {
        start_r -= 1;
        start_c += 1;
    }

    let mut stone_pos_in_diag = 0;
    let (mut curr_r, mut curr_c) = (start_r, start_c);
    let mut idx = 0;
    while curr_r < GRID_NUM && curr_c >= 0 {
        temp_array_list.push(board[curr_r][curr_c]);
        if curr_r == r && curr_c == c {
            stone_pos_in_diag = idx;
        }
        curr_r += 1;
        curr_c -= 1;
        idx += 1;
    }

    if !temp_array_list.is_empty() {
        analysis_line(&temp_array_list, stone_pos_in_diag, board[r][c], &mut m_line_record);
        let (mut curr_r, mut curr_c) = (start_r, start_c);
        for s in 0..temp_array_list.len() {
            if m_line_record[s] != TOBEANALSIS {
                if curr_r < GRID_NUM && curr_c >= 0 {
                    type_record[curr_r][curr_c][3] = m_line_record[s];
                }
            }
            curr_r += 1;
            curr_c -= 1;
            if curr_r >= GRID_NUM || curr_c < 0 {
                break;
            }
        }
    }
    type_record[r][c][3]
}

fn evaluate_board(board: &[[i32; GRID_NUM]; GRID_NUM], color_to_move: i32, type_count: &mut [[i32; 20]; 2]) -> i32 {
    let mut type_record = [[[[TOBEANALSIS; 4]; GRID_NUM]; GRID_NUM]; GRID_NUM];
    type_count.iter_mut().for_each(|row| row.fill(0));

    for r_idx in 0..GRID_NUM {
        for c_idx in 0..GRID_NUM {
            if board[r_idx][c_idx] != NOSTONE {
                if type_record[r_idx][c_idx][0] == TOBEANALSIS {
                    analysis_horizon(board, r_idx, c_idx, &mut type_record);
                }
                if type_record[r_idx][c_idx][1] == TOBEANALSIS {
                    analysis_vertical(board, r_idx, c_idx, &mut type_record);
                }
                if type_record[r_idx][c_idx][2] == TOBEANALSIS {
                    analysis_left_diag(board, r_idx, c_idx, &mut type_record);
                }
                if type_record[r_idx][c_idx][3] == TOBEANALSIS {
                    analysis_right_diag(board, r_idx, c_idx, &mut type_record);
                }
            }
        }
    }

    for r_idx in 0..GRID_NUM {
        for c_idx in 0..GRID_NUM {
            let stone_type_on_board = board[r_idx][c_idx];
            if stone_type_on_board != NOSTONE {
                let player_idx = stone_type_on_board as usize;
                for k_direction in 0..4 {
                    let pattern = type_record[r_idx][c_idx][k_direction];
                    if pattern != NOTYPE && pattern != ANALYSED && pattern != TOBEANALSIS {
                        if pattern >= 1 && (pattern as usize) < type_count[0].len() {
                            type_count[player_idx][pattern as usize] += 1;
                        }
                    }
                }
            }
        }
    }

    let idx_black = MYBLACK as usize;
    let idx_white = MYWHITE as usize;

    if type_count[idx_black][FIVE as usize] > 0 { return -9999; }
    if type_count[idx_white][FIVE as usize] > 0 { return 9999; }

    if type_count[idx_white][SFOUR as usize] >= 2 { type_count[idx_white][FOUR as usize] += 1; }
    if type_count[idx_black][SFOUR as usize] >= 2 { type_count[idx_black][FOUR as usize] += 1; }

    let mut w_value = 0;
    let mut b_value = 0;

    if color_to_move == MYWHITE {
        if type_count[idx_white][FOUR as usize] > 0 { return 9990; }
        if type_count[idx_white][SFOUR as usize] > 0 { return 9980; }
        if type_count[idx_black][FOUR as usize] > 0 { return -9970; }
        if type_count[idx_black][SFOUR as usize] > 0 && type_count[idx_black][THREE as usize] > 0 { return -9960; }
        if type_count[idx_white][THREE as usize] > 0 && type_count[idx_black][SFOUR as usize] == 0 { return 9950; }
        if type_count[idx_black][THREE as usize] > 1 && type_count[idx_white][SFOUR as usize] == 0 &&
           type_count[idx_white][THREE as usize] == 0 && type_count[idx_white][STHREE as usize] == 0 { return -9940; }

        w_value += if type_count[idx_white][THREE as usize] > 1 { 2000 } else if type_count[idx_white][THREE as usize] > 0 { 200 } else { 0 };
        b_value += if type_count[idx_black][THREE as usize] > 1 { 500 } else if type_count[idx_black][THREE as usize] > 0 { 100 } else { 0 };
    } else {
        if type_count[idx_black][FOUR as usize] > 0 { return -9990; }
        if type_count[idx_black][SFOUR as usize] > 0 { return -9980; }
        if type_count[idx_white][FOUR as usize] > 0 { return 9970; }
        if type_count[idx_white][SFOUR as usize] > 0 && type_count[idx_white][THREE as usize] > 0 { return 9960; }
        if type_count[idx_black][THREE as usize] > 0 && type_count[idx_white][SFOUR as usize] == 0 { return -9950; }
        if type_count[idx_white][THREE as usize] > 1 && type_count[idx_black][SFOUR as usize] == 0 &&
           type_count[idx_black][THREE as usize] == 0 && type_count[idx_black][STHREE as usize] == 0 { return 9940; }

        b_value += if type_count[idx_black][THREE as usize] > 1 { 2000 } else if type_count[idx_black][THREE as usize] > 0 { 200 } else { 0 };
        w_value += if type_count[idx_white][THREE as usize] > 1 { 500 } else if type_count[idx_white][THREE as usize] > 0 { 100 } else { 0 };
    }

    w_value += type_count[idx_white][STHREE as usize] * 10;
    b_value += type_count[idx_black][STHREE as usize] * 10;
    w_value += type_count[idx_white][TWO as usize] * 4;
    b_value += type_count[idx_black][TWO as usize] * 4;
    w_value += type_count[idx_white][STWO as usize] * 1;
    b_value += type_count[idx_black][STWO as usize] * 1;

    let pos_value = [
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
    ];

    for r_idx in 0..GRID_NUM {
        for c_idx in 0..GRID_NUM {
            if board[r_idx][c_idx] == MYBLACK {
                b_value += pos_value[r_idx][c_idx];
            } else if board[r_idx][c_idx] == MYWHITE {
                w_value += pos_value[r_idx][c_idx];
            }
        }
    }

    w_value - b_value
}

fn create_possible_moves(board: &[[i32; GRID_NUM]; GRID_NUM], color: i32) -> Vec<MoveStone> {
    let mut moves = Vec::new();
    let has_stones_on_board = board.iter().any(|row| row.iter().any(|&cell| cell != NOSTONE));

    if !has_stones_on_board {
        let center = GRID_NUM / 2;
        moves.push(MoveStone { color, pt_move_point: MyPoint { x: center, y: center } });
        return moves;
    }

    let mut candidate_points = std::collections::HashSet::new();
    for r_idx in 0..GRID_NUM {
        for c_idx in 0..GRID_NUM {
            if board[r_idx][c_idx] == NOSTONE {
                let mut is_near_stone = false;
                for dr in -2..=2 {
                    for dc in -2..=2 {
                        if dr == 0 && dc == 0 { continue; }
                        let (nr, nc) = (r_idx as i32 + dr, c_idx as i32 + dc);
                        if nr >= 0 && nr < GRID_NUM as i32 && nc >= 0 && nc < GRID_NUM as i32 {
                            if board[nr as usize][nc as usize] != NOSTONE {
                                is_near_stone = true;
                                break;
                            }
                        }
                    }
                    if is_near_stone { break; }
                }
                if is_near_stone {
                    candidate_points.insert((r_idx, c_idx));
                }
            }
        }
    }

    for (r_cand, c_cand) in candidate_points {
        moves.push(MoveStone { color, pt_move_point: MyPoint { x: r_cand, y: c_cand } });
    }

    moves
}

fn alphabeta(
    current_board: &[[i32; GRID_NUM]; GRID_NUM],
    depth: i32,
    mut alpha: i32,
    mut beta: i32,
    color_to_move: i32,
    type_count: &mut [[i32; 20]; 2],
) -> AfterMove {
    let score = evaluate_board(current_board, color_to_move, type_count);
    if score.abs() >= 9990 || depth == 0 {
        return AfterMove { state: Some(State { grid: *current_board }), score };
    }

    let possible_moves = create_possible_moves(current_board, color_to_move);
    if possible_moves.is_empty() {
        return AfterMove { state: Some(State { grid: *current_board }), score };
    }

    let mut best_move_state_for_return = None;

    if color_to_move == MYWHITE {
        let mut best_val = -20000;
        for move_ in possible_moves {
            let mut temp_board = *current_board;
            temp_board[move_.pt_move_point.x][move_.pt_move_point.y] = MYWHITE;
            let result = alphabeta(&temp_board, depth - 1, alpha, beta, MYBLACK, type_count);
            if result.score > best_val {
                best_val = result.score;
                best_move_state_for_return = Some(State { grid: temp_board });
            }
            alpha = alpha.max(best_val);
            if beta <= alpha {
                break;
            }
        }
        AfterMove { state: best_move_state_for_return, score: best_val }
    } else {
        let mut best_val = 20000;
        for move_ in possible_moves {
            let mut temp_board = *current_board;
            temp_board[move_.pt_move_point.x][move_.pt_move_point.y] = MYBLACK;
            let result = alphabeta(&temp_board, depth - 1, alpha, beta, MYWHITE, type_count);
            if result.score < best_val {
                best_val = result.score;
                best_move_state_for_return = Some(State { grid: temp_board });
            }
            beta = beta.min(best_val);
            if beta <= alpha {
                break;
            }
        }
        AfterMove { state: best_move_state_for_return, score: best_val }
    }
}

fn make_ai_move(board: &[[i32; GRID_NUM]; GRID_NUM], ai_color: i32, search_depth: i32, type_count: &mut [[i32; 20]; 2]) -> [[i32; GRID_NUM]; GRID_NUM] {
    println!("AI (color: {}) is thinking with depth {}...", ai_color, search_depth);
    let result_after_move = alphabeta(board, search_depth, -20000, 20000, ai_color, type_count);

    if let Some(state) = result_after_move.state {
        println!("AI chooses move leading to score: {}", result_after_move.score);
        for r in 0..GRID_NUM {
            for c in 0..GRID_NUM {
                if state.grid[r][c] != board[r][c] {
                    println!("AI places at ({}, {})", r + 1, c + 1);
                    return state.grid;
                }
            }
        }
        state.grid
    } else {
        println!("AI could not find a valid move or state.");
        *board
    }
}

fn is_game_over(board: &[[i32; GRID_NUM]; GRID_NUM], _last_player_color: i32, type_count: &mut [[i32; 20]; 2]) -> bool {
    evaluate_board(board, MYBLACK, type_count);
    if type_count[MYBLACK as usize][FIVE as usize] > 0 {
        println!("Game Over! Black wins.");
        return true;
    }
    if type_count[MYWHITE as usize][FIVE as usize] > 0 {
        println!("Game Over! White wins.");
        return true;
    }

    if !board.iter().any(|row| row.iter().any(|&cell| cell == NOSTONE)) {
        println!("Game Over! It's a draw.");
        return true;
    }
    false
}

fn display_board(board: &[[i32; GRID_NUM]; GRID_NUM]) {
    print!("
  ");
    for i in 0..GRID_NUM {
        print!("{: <2} ", i + 1);
    }
    println!();
    for r_idx in 0..GRID_NUM {
        print!("{:<2} ", r_idx + 1);
        for c_idx in 0..GRID_NUM {
            match board[r_idx][c_idx] {
                MYBLACK => print!("B   "),
                MYWHITE => print!("W   "),
                _ => print!(".   "),
            }
        }
        println!();
    }
    println!();
}

fn init_board() -> [[i32; GRID_NUM]; GRID_NUM] {
    [[NOSTONE; GRID_NUM]; GRID_NUM]
}

fn main() {
    let mut board = init_board();
    let mut type_count = [[0; 20]; 2];

    let player_color: i32;
    loop {
        println!("Enter your color: (0 for Black, 1 for White)");
        let mut input = String::new();
        io::stdin().read_line(&mut input).expect("Failed to read line");
        match input.trim().parse() {
            Ok(0) => { player_color = MYBLACK; break; },
            Ok(1) => { player_color = MYWHITE; break; },
            _ => { println!("Invalid input. Please enter 0 for Black or 1 for White."); continue; }
        }
    }

    let ai_color = 1 - player_color;
    let mut current_color = MYBLACK;
    let search_depth = 5;

    println!("You are: {}", if player_color == MYBLACK { "Black" } else { "White" });
    println!("AI is: {}", if ai_color == MYBLACK { "Black" } else { "White" });
    println!("Search depth: {}", search_depth);

    display_board(&board);
    let mut step = 0;

    loop {
        if current_color == player_color {
            println!("Your turn ({}). Enter row and col (e.g., 7 7):", if player_color == MYBLACK { "Black" } else { "White" });
            loop {
                let mut input = String::new();
                io::stdin().read_line(&mut input).expect("Failed to read line");
                let parts: Vec<&str> = input.trim().split_whitespace().collect();
                if parts.len() == 2 {
                    if let (Ok(r), Ok(c)) = (parts[0].parse::<usize>(), parts[1].parse::<usize>()) {
                        if r > 0 && r <= GRID_NUM && c > 0 && c <= GRID_NUM && board[r - 1][c - 1] == NOSTONE {
                            board[r - 1][c - 1] = player_color;
                            break;
                        } else {
                            println!("Invalid move (out of bounds or spot taken). Try again.");
                        }
                    } else {
                        println!("Invalid input format. Format: row col (e.g., 7 7). Try again.");
                    }
                } else {
                    println!("Invalid input format. Format: row col (e.g., 7 7). Try again.");
                }
            }
        } else {
            println!("AI's turn ({})...", if ai_color == MYBLACK { "Black" } else { "White" });
            if step == 0 && ai_color == MYBLACK {
                let center = GRID_NUM / 2;
                board[center][center] = ai_color;
                println!("AI places at {}, {}", center + 1, center + 1);
            } else {
                board = make_ai_move(&board, ai_color, search_depth, &mut type_count);
            }
        }

        display_board(&board);

        if is_game_over(&board, current_color, &mut type_count) {
            break;
        }

        current_color = 1 - current_color;
        step += 1;
    }

    println!("Thank you for playing!");
}
''