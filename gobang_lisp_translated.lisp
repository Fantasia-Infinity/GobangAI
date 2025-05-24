(in-package :common-lisp-user)

;;; filepath: /Users/shufanzhang/Documents/coderepos/GobangAI/goban_lisp_translated.lisp
;;; 
;;; Gobang AI - Common Lisp Translation
;;; Translated from Julia version of Gobang AI
;;; Note: Graphics and console input parts are adapted for Common Lisp console.

;;; Constants
(defconstant +grid-num+ 15)    ; Board size (15x15)
(defconstant +myblack+ 0)      ; Black stone
(defconstant +mywhite+ 1)      ; White stone  
(defconstant +nostone+ 9)      ; Empty intersection

;;; Chess pattern types
(defconstant +stwo+ 1)         ; Blocked Two
(defconstant +sthree+ 2)       ; Blocked Three
(defconstant +sfour+ 3)        ; Blocked Four / Four with one end blocked
(defconstant +two+ 4)          ; Live Two
(defconstant +three+ 5)        ; Live Three
(defconstant +four+ 6)         ; Live Four
(defconstant +five+ 7)         ; Five-in-a-row
(defconstant +notype+ 11)      ; Undefined pattern
(defconstant +analysed+ 255)   ; Analyzed position
(defconstant +tobeanalysis+ 0) ; To be analyzed

;;; --- Data Structures ---

;;; Point on the board
(defstruct my-point
  x
  y)

;;; Represents a move
(defstruct move-stone
  color
  pt-move-point)

;;; Represents the board state
(defstruct state
  grid)

;;; Represents a state after a move, with its score
(defstruct after-move
  state
  score)

;;; --- Global Variables ---
;;; These were global in C++/Julia, in Lisp they are also global for direct translation

;;; Stores analysis results for a line
(defparameter *m-line-record* (make-array 30 :initial-element 0))

;;; Stores analysis results for the whole board [row, col, direction]
;;; Directions: 0:Horizontal, 1:Vertical, 2:Left-Diagonal, 3:Right-Diagonal
(defparameter *type-record* (make-array (list +grid-num+ +grid-num+ 4) :initial-element 0))

;;; Counts of each pattern type for each color [color_idx, pattern_type_idx]
;;; color_idx: 0 for MYBLACK, 1 for MYWHITE
(defparameter *type-count* (make-array (list 2 20) :initial-element 0))

;;; Positional values for heuristic evaluation
(defparameter +pos-value+ 
  #2A((0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
      (0 1 1 1 1 1 1 1 1 1 1 1 1 1 0)
      (0 1 2 2 2 2 2 2 2 2 2 2 2 1 0)
      (0 1 2 3 3 3 3 3 3 3 3 3 2 1 0)
      (0 1 2 3 4 4 4 4 4 4 4 3 2 1 0)
      (0 1 2 3 4 5 5 5 5 5 4 3 2 1 0)
      (0 1 2 3 4 5 6 6 6 5 4 3 2 1 0)
      (0 1 2 3 4 5 6 7 6 5 4 3 2 1 0)
      (0 1 2 3 4 5 6 6 6 5 4 3 2 1 0)
      (0 1 2 3 4 5 5 5 5 5 4 3 2 1 0)
      (0 1 2 3 4 4 4 4 4 4 4 3 2 1 0)
      (0 1 2 3 3 3 3 3 3 3 3 3 2 1 0)
      (0 1 2 2 2 2 2 2 2 2 2 2 2 1 0)
      (0 1 1 1 1 1 1 1 1 1 1 1 1 1 0)
      (0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)))

;;; --- Helper Functions ---

;;; Check if a position is valid on the board
(defun valid-pos-p (x y)
  (and (>= x 0) (< x +grid-num+) (>= y 0) (< y +grid-num+)))

;;; Convert from 1-indexed to 0-indexed
(defun to-zero-indexed (pos)
  (1- pos))

;;; Convert from 0-indexed to 1-indexed  
(defun to-one-indexed (pos)
  (1+ pos))

;;; --- Core Logic Functions ---

;;; Analyzes a single line (row, column, or diagonal) for patterns
(defun analysis-line (line-segment stone-pos-in-line current-stone-type)
  "Analyze a line segment for stone patterns"
  ;; Reset m-line-record for this call
  (fill *m-line-record* +tobeanalysis+)
  
  (let ((num-stones (length line-segment)))
    (when (< num-stones 5)
      ;; Mark all as analyzed if too short to form significant patterns
      (loop for i from 0 below num-stones do
        (setf (aref *m-line-record* i) +analysed+))
      (return-from analysis-line 0))
    
    ;; Convert to 0-indexed for logic
    (let ((analy-pos-0idx stone-pos-in-line))
      
      ;; Boundaries of connected stones of the same type
      (let ((left-edge-0idx analy-pos-0idx)
            (right-edge-0idx analy-pos-0idx))
        
        ;; Find left boundary
        (loop while (and (> left-edge-0idx 0) 
                        (= (nth left-edge-0idx line-segment) current-stone-type)) do
          (decf left-edge-0idx))
        (when (/= (nth left-edge-0idx line-segment) current-stone-type)
          (incf left-edge-0idx))
        
        ;; Find right boundary
        (loop while (and (< right-edge-0idx (1- num-stones))
                        (= (nth (1+ right-edge-0idx) line-segment) current-stone-type)) do
          (incf right-edge-0idx))
        (when (/= (nth right-edge-0idx line-segment) current-stone-type)
          (decf right-edge-0idx))
        
        ;; Extend to include empty spots for pattern analysis
        (let ((left-range-0idx left-edge-0idx)
              (right-range-0idx right-edge-0idx))
          
          (loop while (and (> left-range-0idx 0)
                          (/= (nth left-range-0idx line-segment) 
                              (- 1 current-stone-type))) do
            (decf left-range-0idx))
          (when (and (> left-range-0idx 0)
                     (= (nth left-range-0idx line-segment) (- 1 current-stone-type)))
            (incf left-range-0idx))
          
          (loop while (and (< right-range-0idx (1- num-stones))
                          (/= (nth (1+ right-range-0idx) line-segment)
                              (- 1 current-stone-type))) do
            (incf right-range-0idx))
          (when (and (< right-range-0idx (1- num-stones))
                     (= (nth (1+ right-range-0idx) line-segment) 
                         (- 1 current-stone-type)))
            (decf right-range-0idx))
          
          (when (< (- right-range-0idx left-range-0idx -1) 5)
            (loop for k from left-range-0idx to right-range-0idx do
              (setf (aref *m-line-record* k) +analysed+))
            (return-from analysis-line +notype+))
          
          ;; Mark the continuous segment as analyzed
          (loop for k from left-edge-0idx to right-edge-0idx do
            (setf (aref *m-line-record* k) +analysed+))
          
          (let ((connected-len (- right-edge-0idx left-edge-0idx -1)))
            
            ;; Pattern Recognition
            (cond
              ;; Five-in-a-row
              ((>= connected-len 5)
               (setf (aref *m-line-record* analy-pos-0idx) +five+)
               +five+)
              
              ;; Four
              ((= connected-len 4)
               (let ((has-left-space (and (> left-edge-0idx 0)
                                         (= (nth (1- left-edge-0idx) line-segment) +nostone+)))
                     (has-right-space (and (< right-edge-0idx (1- num-stones))
                                          (= (nth (1+ right-edge-0idx) line-segment) +nostone+))))
                 (cond
                   ((and has-left-space has-right-space)
                    (setf (aref *m-line-record* analy-pos-0idx) +four+)
                    +four+)
                   ((or has-left-space has-right-space)
                    (setf (aref *m-line-record* analy-pos-0idx) +sfour+)
                    +sfour+)
                   (t
                    (setf (aref *m-line-record* analy-pos-0idx) +notype+)
                    +notype+))))
              
              ;; Three
              ((= connected-len 3)
               (let ((left-open (and (> left-edge-0idx 0)
                                    (= (nth (1- left-edge-0idx) line-segment) +nostone+)))
                     (right-open (and (< right-edge-0idx (1- num-stones))
                                     (= (nth (1+ right-edge-0idx) line-segment) +nostone+))))
                 (cond
                   ((and left-open right-open)
                    (setf (aref *m-line-record* analy-pos-0idx) +three+)
                    +three+)
                   ((or left-open right-open)
                    (setf (aref *m-line-record* analy-pos-0idx) +sthree+)
                    +sthree+)
                   (t
                    (setf (aref *m-line-record* analy-pos-0idx) +notype+)
                    +notype+))))
              
              ;; Two
              ((= connected-len 2)
               (let ((left-open (and (> left-edge-0idx 0)
                                    (= (nth (1- left-edge-0idx) line-segment) +nostone+)))
                     (right-open (and (< right-edge-0idx (1- num-stones))
                                     (= (nth (1+ right-edge-0idx) line-segment) +nostone+))))
                 (cond
                   ((and left-open right-open)
                    (setf (aref *m-line-record* analy-pos-0idx) +two+)
                    +two+)
                   ((or left-open right-open)
                    (setf (aref *m-line-record* analy-pos-0idx) +stwo+)
                    +stwo+)
                   (t
                    (setf (aref *m-line-record* analy-pos-0idx) +notype+)
                    +notype+))))
              
              ;; Default
              (t
               (setf (aref *m-line-record* analy-pos-0idx) +notype+)
               +notype+))))))))

;;; Analyze horizontal line at (r, c) - using 0-indexed coordinates
(defun analysis-horizon (board r c)
  "Analyze horizontal line at position (r,c)"
  (let ((line-segment (loop for col from 0 below +grid-num+
                           collect (aref board r col))))
    (analysis-line line-segment c (aref board r c))
    (loop for s from 0 below +grid-num+ do
      (when (/= (aref *m-line-record* s) +tobeanalysis+)
        (setf (aref *type-record* r s 0) (aref *m-line-record* s))))
    (aref *type-record* r c 0)))

;;; Analyze vertical line at (r, c) - using 0-indexed coordinates
(defun analysis-vertical (board r c)
  "Analyze vertical line at position (r,c)"
  (let ((line-segment (loop for row from 0 below +grid-num+
                           collect (aref board row c))))
    (analysis-line line-segment r (aref board r c))
    (loop for s from 0 below +grid-num+ do
      (when (/= (aref *m-line-record* s) +tobeanalysis+)
        (setf (aref *type-record* s c 1) (aref *m-line-record* s))))
    (aref *type-record* r c 1)))

;;; Analyze left-diagonal (top-left to bottom-right) through (r, c)
(defun analysis-left-diag (board r c)
  "Analyze left diagonal through position (r,c)"
  (let ((temp-array '()))
    
    ;; Determine start of diagonal
    (let ((start-r r) (start-c c))
      (loop while (and (> start-r 0) (> start-c 0)) do
        (decf start-r)
        (decf start-c))
      
      ;; Extract diagonal and find relative position
      (let ((stone-pos-in-diag 0)
            (curr-r start-r) 
            (curr-c start-c)
            (idx 0))
        
        (loop while (and (< curr-r +grid-num+) (< curr-c +grid-num+)) do
          (push (aref board curr-r curr-c) temp-array)
          (when (and (= curr-r r) (= curr-c c))
            (setf stone-pos-in-diag idx))
          (incf curr-r)
          (incf curr-c)
          (incf idx))
        
        (setf temp-array (nreverse temp-array))
        
        (when temp-array
          (analysis-line temp-array stone-pos-in-diag (aref board r c))
          
          ;; Store results back
          (setf curr-r start-r curr-c start-c)
          (loop for s from 0 below (length temp-array) do
            (when (/= (aref *m-line-record* s) +tobeanalysis+)
              (when (and (< curr-r +grid-num+) (< curr-c +grid-num+))
                (setf (aref *type-record* curr-r curr-c 2) (aref *m-line-record* s))))
            (incf curr-r)
            (incf curr-c)
            (when (or (>= curr-r +grid-num+) (>= curr-c +grid-num+))
              (return))))
        
        (aref *type-record* r c 2)))))

;;; Analyze right-diagonal (top-right to bottom-left) through (r, c)
(defun analysis-right-diag (board r c)
  "Analyze right diagonal through position (r,c)"
  (let ((temp-array '()))
    
    ;; Determine start of diagonal  
    (let ((start-r r) (start-c c))
      (loop while (and (> start-r 0) (< start-c (1- +grid-num+))) do
        (decf start-r)
        (incf start-c))
      
      ;; Extract diagonal and find relative position
      (let ((stone-pos-in-diag 0)
            (curr-r start-r)
            (curr-c start-c)
            (idx 0))
        
        (loop while (and (< curr-r +grid-num+) (>= curr-c 0)) do
          (push (aref board curr-r curr-c) temp-array)
          (when (and (= curr-r r) (= curr-c c))
            (setf stone-pos-in-diag idx))
          (incf curr-r)
          (decf curr-c)
          (incf idx))
        
        (setf temp-array (nreverse temp-array))
        
        (when temp-array
          (analysis-line temp-array stone-pos-in-diag (aref board r c))
          
          ;; Store results back
          (setf curr-r start-r curr-c start-c)
          (loop for s from 0 below (length temp-array) do
            (when (/= (aref *m-line-record* s) +tobeanalysis+)
              (when (and (< curr-r +grid-num+) (>= curr-c 0))
                (setf (aref *type-record* curr-r curr-c 3) (aref *m-line-record* s))))
            (incf curr-r)
            (decf curr-c)
            (when (or (>= curr-r +grid-num+) (< curr-c 0))
              (return))))
        
        (aref *type-record* r c 3)))))

;;; Evaluate the board state for the given color to move
(defun evaluate-board (board color-to-move)
  "Evaluate board position for given color"
  ;; Reset global analysis storage
  (loop for i from 0 below +grid-num+ do
    (loop for j from 0 below +grid-num+ do
      (loop for k from 0 below 4 do
        (setf (aref *type-record* i j k) +tobeanalysis+))))
  
  (loop for i from 0 below 2 do
    (loop for j from 0 below 20 do
      (setf (aref *type-count* i j) 0)))
  
  ;; Analyze all positions
  (loop for r from 0 below +grid-num+ do
    (loop for c from 0 below +grid-num+ do
      (when (/= (aref board r c) +nostone+)
        ;; Horizontal
        (when (= (aref *type-record* r c 0) +tobeanalysis+)
          (analysis-horizon board r c))
        ;; Vertical  
        (when (= (aref *type-record* r c 1) +tobeanalysis+)
          (analysis-vertical board r c))
        ;; Left Diagonal
        (when (= (aref *type-record* r c 2) +tobeanalysis+)
          (analysis-left-diag board r c))
        ;; Right Diagonal
        (when (= (aref *type-record* r c 3) +tobeanalysis+)
          (analysis-right-diag board r c)))))
  
  ;; Aggregate TypeCount from TypeRecord
  (loop for r from 0 below +grid-num+ do
    (loop for c from 0 below +grid-num+ do
      (let ((stone-type-on-board (aref board r c)))
        (when (/= stone-type-on-board +nostone+)
          (let ((player-idx stone-type-on-board)) ; MYBLACK (0) -> 0, MYWHITE (1) -> 1
            (loop for k from 0 below 4 do ; Directions
              (let ((pattern (aref *type-record* r c k)))
                (when (and (/= pattern +notype+) 
                          (/= pattern +analysed+) 
                          (/= pattern +tobeanalysis+)
                          (<= 1 pattern 19))
                  (incf (aref *type-count* player-idx pattern))))))))))
  
  ;; Scoring logic
  (let ((idx-black +myblack+)
        (idx-white +mywhite+))
    
    ;; Check for immediate wins
    (when (> (aref *type-count* idx-black +five+) 0)
      (return-from evaluate-board -9999)) ; Black wins
    (when (> (aref *type-count* idx-white +five+) 0)
      (return-from evaluate-board 9999))  ; White wins
    
    ;; Two SFOURs are like a FOUR
    (when (> (aref *type-count* idx-white +sfour+) 1)
      (incf (aref *type-count* idx-white +four+)))
    (when (> (aref *type-count* idx-black +sfour+) 1)
      (incf (aref *type-count* idx-black +four+)))
    
    (let ((w-value 0) (b-value 0))
      
      (if (= color-to-move +mywhite+)
          (progn
            (when (> (aref *type-count* idx-white +four+) 0) (return-from evaluate-board 9990))
            (when (> (aref *type-count* idx-white +sfour+) 0) (return-from evaluate-board 9980))
            (when (> (aref *type-count* idx-black +four+) 0) (return-from evaluate-board -9970))
            (when (and (> (aref *type-count* idx-black +sfour+) 0) 
                       (> (aref *type-count* idx-black +three+) 0)) 
              (return-from evaluate-board -9960))
            (when (and (> (aref *type-count* idx-white +three+) 0) 
                       (= (aref *type-count* idx-black +sfour+) 0)) 
              (return-from evaluate-board 9950))
            (when (and (> (aref *type-count* idx-black +three+) 1)
                       (= (aref *type-count* idx-white +sfour+) 0)
                       (= (aref *type-count* idx-white +three+) 0)
                       (= (aref *type-count* idx-white +sthree+) 0))
              (return-from evaluate-board -9940))
            
            (incf w-value (if (> (aref *type-count* idx-white +three+) 1) 2000
                              (if (> (aref *type-count* idx-white +three+) 0) 200 0)))
            (incf b-value (if (> (aref *type-count* idx-black +three+) 1) 500
                              (if (> (aref *type-count* idx-black +three+) 0) 100 0))))
          
          ;; color-to-move == MYBLACK
          (progn
            (when (> (aref *type-count* idx-black +four+) 0) (return-from evaluate-board -9990))
            (when (> (aref *type-count* idx-black +sfour+) 0) (return-from evaluate-board -9980))
            (when (> (aref *type-count* idx-white +four+) 0) (return-from evaluate-board 9970))
            (when (and (> (aref *type-count* idx-white +sfour+) 0)
                       (> (aref *type-count* idx-white +three+) 0))
              (return-from evaluate-board 9960))
            (when (and (> (aref *type-count* idx-black +three+) 0)
                       (= (aref *type-count* idx-white +sfour+) 0))
              (return-from evaluate-board -9950))
            (when (and (> (aref *type-count* idx-white +three+) 1)
                       (= (aref *type-count* idx-black +sfour+) 0)
                       (= (aref *type-count* idx-black +three+) 0)
                       (= (aref *type-count* idx-black +sthree+) 0))
              (return-from evaluate-board 9940))
            
            (incf b-value (if (> (aref *type-count* idx-black +three+) 1) 2000
                              (if (> (aref *type-count* idx-black +three+) 0) 200 0)))
            (incf w-value (if (> (aref *type-count* idx-white +three+) 1) 500
                              (if (> (aref *type-count* idx-white +three+) 0) 100 0)))))
      
      (incf w-value (* (aref *type-count* idx-white +sthree+) 10))
      (incf b-value (* (aref *type-count* idx-black +sthree+) 10))
      (incf w-value (* (aref *type-count* idx-white +two+) 4))
      (incf b-value (* (aref *type-count* idx-black +two+) 4))
      (incf w-value (aref *type-count* idx-white +stwo+))
      (incf b-value (aref *type-count* idx-black +stwo+))
      
      ;; Positional value
      (loop for r from 0 below +grid-num+ do
        (loop for c from 0 below +grid-num+ do
          (cond
            ((= (aref board r c) +myblack+)
             (incf b-value (aref +pos-value+ r c)))
            ((= (aref board r c) +mywhite+)
             (incf w-value (aref +pos-value+ r c))))))
      
      (- w-value b-value))))

;;; Generate possible moves
(defun create-possible-moves (board color)
  "Generate list of possible moves for given color"
  (let ((moves '())
        (has-stones-on-board nil))
    
    ;; Check if there are any stones on board
    (loop for r from 0 below +grid-num+ do
      (loop for c from 0 below +grid-num+ do
        (when (/= (aref board r c) +nostone+)
          (setf has-stones-on-board t)
          (return))))
    
    ;; If board is empty, place at center
    (unless has-stones-on-board
      (let ((center (floor +grid-num+ 2)))
        (return-from create-possible-moves 
          (list (make-move-stone :color color 
                                :pt-move-point (make-my-point :x center :y center))))))
    
    ;; Generate moves near existing stones
    (loop for r from 0 below +grid-num+ do
      (loop for c from 0 below +grid-num+ do
        (when (= (aref board r c) +nostone+)
          ;; Check if near existing stones
          (let ((is-near-stone nil))
            (loop for dr from -1 to 1 do
              (loop for dc from -1 to 1 do
                (unless (and (= dr 0) (= dc 0))
                  (let ((nr (+ r dr)) (nc (+ c dc)))
                    (when (and (valid-pos-p nr nc) (/= (aref board nr nc) +nostone+))
                      (setf is-near-stone t)
                      (return))))
              (when is-near-stone (return)))
            
            (when is-near-stone
              (push (make-move-stone :color color 
                                    :pt-move-point (make-my-point :x r :y c)) 
                    moves))))))
    
    ;; If no moves near stones found, allow any empty spot  
    (when (null moves)
      (loop for r from 0 below +grid-num+ do
        (loop for c from 0 below +grid-num+ do
          (when (= (aref board r c) +nostone+)
            (push (make-move-stone :color color 
                                  :pt-move-point (make-my-point :x r :y c)) 
                  moves)))))
    
    (nreverse moves)))

;;; Alpha-Beta search
(defun alpha-beta (current-board depth alpha beta color-to-move) ; Renamed from alphabeta
  "Alpha-beta minimax search"
  ;; Terminal conditions for recursion
  (let ((score (evaluate-board current-board color-to-move)))
    (when (>= (abs score) 9990) ; Win/loss state
      (return-from alpha-beta (make-after-move :state (make-state :grid current-board)
                                             :score score)))
    (when (= depth 0)
      (return-from alpha-beta (make-after-move :state (make-state :grid current-board)
                                             :score score)))

    (let ((possible-moves (create-possible-moves current-board color-to-move)))
      (when (null possible-moves) ; No moves possible
        (return-from alpha-beta (make-after-move :state (make-state :grid current-board)
                                               :score score)))

      (let ((best-move-state nil))

        (if (= color-to-move +mywhite+) ; Maximizing player
            (let ((best-val -20000)
                  (current-alpha alpha))
              (dolist (move possible-moves)
                (let ((temp-board (make-array (list +grid-num+ +grid-num+))))
                  ;; Copy board
                  (loop for i from 0 below +grid-num+ do
                    (loop for j from 0 below +grid-num+ do
                      (setf (aref temp-board i j) (aref current-board i j))))
                  ;; Make move
                  (setf (aref temp-board (my-point-x (move-stone-pt-move-point move))
                                        (my-point-y (move-stone-pt-move-point move))) +mywhite+)

                  (let ((result (alpha-beta temp-board (1- depth) current-alpha beta +myblack+))) ; Corrected call
                    (when (> (after-move-score result) best-val)
                      (setf best-val (after-move-score result))
                      (setf best-move-state (make-state :grid temp-board)))
                    (setf current-alpha (max current-alpha best-val))
                    (when (<= beta current-alpha)
                      (return))))) ; Beta cut-off
              (make-after-move :state best-move-state :score best-val))

            ;; color-to-move == MYBLACK, Minimizing player
            (let ((best-val 20000)
                  (current-beta beta))
              (dolist (move possible-moves)
                (let ((temp-board (make-array (list +grid-num+ +grid-num+))))
                  ;; Copy board
                  (loop for i from 0 below +grid-num+ do
                    (loop for j from 0 below +grid-num+ do
                      (setf (aref temp-board i j) (aref current-board i j))))
                  ;; Make move
                  (setf (aref temp-board (my-point-x (move-stone-pt-move-point move))
                                        (my-point-y (move-stone-pt-move-point move))) +myblack+)

                  (let ((result (alpha-beta temp-board (1- depth) alpha current-beta +mywhite+))) ; Corrected call
                    (when (< (after-move-score result) best-val)
                      (setf best-val (after-move-score result))
                      (setf best-move-state (make-state :grid temp-board)))
                    (setf current-beta (min current-beta best-val))
                    (when (<= current-beta alpha)
                      (return))))) ; Alpha cut-off
              (make-after-move :state best-move-state :score best-val)))))))

;;; Make a move for AI
(defun make-ai-move (board ai-color search-depth)
  "Make AI move and return new board state"
  (format t "AI (color: ~A) is thinking with depth ~A...~%" ai-color search-depth)
  (let ((result-after-move (alpha-beta board search-depth -20000 20000 ai-color))) ; Corrected call

    (if (after-move-state result-after-move)
        (progn
          (format t "AI chooses move leading to score: ~A~%" (after-move-score result-after-move))
          (state-grid (after-move-state result-after-move)))
        (progn
          (format t "AI could not find a valid move or state. This shouldn\'t happen if game not over.~%")
          board))))

;;; Check if game is over
(defun game-over-p (board current-player-color)
  "Check if the game is over"
  (let ((eval-score (evaluate-board board current-player-color)))
    (cond
      ((<= eval-score -9999)
       (format t "Game Over! Black wins.~%")
       t)
      ((>= eval-score 9999)
       (format t "Game Over! White wins.~%")
       t)
      ;; Check for draw (no empty spots left)
      ((not (loop for i from 0 below +grid-num+
                  thereis (loop for j from 0 below +grid-num+
                               thereis (= (aref board i j) +nostone+))))
       (format t "Game Over! It's a draw.~%")
       t)
      (t nil))))

;;; Display board in console
(defun display-board (board)
  "Display the current board state"
  (format t "~%  ")
  (loop for i from 1 to +grid-num+ do
    (format t "~2D " i))
  (format t "~%")
  
  (loop for r from 0 below +grid-num+ do
    (format t "~2D " (1+ r))
    (loop for c from 0 below +grid-num+ do
      (cond
        ((= (aref board r c) +myblack+) (format t "B  "))
        ((= (aref board r c) +mywhite+) (format t "W  "))
        (t (format t ".  "))))
    (format t "~%"))
  (format t "~%"))

;;; Initialize board
(defun init-board ()
  "Initialize an empty board"
  (let ((board (make-array (list +grid-num+ +grid-num+) :initial-element +nostone+)))
    board))

;;; Utility function to split strings
(defun split-string (string delimiter)
  "Split string by delimiter"
  (let ((result '())
        (start 0))
    (loop for i from 0 below (length string) do
      (when (char= (char string i) delimiter)
        (when (> i start)
          (push (subseq string start i) result))
        (setf start (1+ i))))
    (when (< start (length string))
      (push (subseq string start) result))
    (nreverse result)))

;;; --- Main Game Loop ---
(defun main-game ()
  "Main game loop"
  (let ((board (init-board)))
    
    (format t "Enter your color: (0 for Black, 1 for White)~%")
    (let ((player-color nil))
      (loop until player-color do
        (format t "> ")
        (let ((input (read-line)))
          (cond
            ((string= input "0") (setf player-color +myblack+))
            ((string= input "1") (setf player-color +mywhite+))
            (t (format t "Invalid input. Please enter 0 for Black or 1 for White.~%")))))
      
      (let ((ai-color (- 1 player-color))
            (current-color +myblack+) ; Black always starts
            (search-depth 5)          ; AI search depth
            (step 0))
        
        (format t "You are: ~A~%" (if (= player-color +myblack+) "Black" "White"))
        (format t "AI is: ~A~%" (if (= ai-color +myblack+) "Black" "White"))
        (format t "Search depth: ~A~%" search-depth)
        
        (display-board board)
        
        (loop until (game-over-p board current-color) do
          (if (= current-color player-color)
              ;; Player's turn
              (progn
                (format t "Your turn (~A). Enter row and col (e.g., 7 7):~%" 
                        (if (= player-color +myblack+) "Black" "White"))
                (loop 
                  (handler-case
                      (progn
                        (format t "> ")
                        (let* ((input (read-line))
                               (parts (split-string input #\Space)))
                          (when (= (length parts) 2)
                            (let ((r (1- (parse-integer (first parts))))   ; Convert to 0-indexed
                                  (c (1- (parse-integer (second parts)))))  ; Convert to 0-indexed
                              (if (and (valid-pos-p r c) (= (aref board r c) +nostone+))
                                  (progn
                                    (setf (aref board r c) player-color)
                                    (return))
                                  (format t "Invalid move. Try again.~%"))))))
                    (error ()
                      (format t "Invalid input. Format: row col (e.g., 7 7). Try again.~%")))))
              
              ;; AI's turn
              (progn
                (format t "AI's turn (~A)...~%" (if (= ai-color +myblack+) "Black" "White"))
                (if (and (= step 0) (= ai-color +myblack+)) ; AI is black and first move
                    (let ((center (floor +grid-num+ 2)))
                      (setf (aref board center center) ai-color)
                      (format t "AI places at ~A, ~A~%" (1+ center) (1+ center)))
                    (setf board (make-ai-move board ai-color search-depth)))))
          
          (display-board board)
          (setf current-color (- 1 current-color)) ; Switch player
          (incf step))
        
        (format t "Thank you for playing!~%")))))

;;; Entry point
(defun start-gobang ()
  "Start the Gobang game"
  (format t "Gobang AI (Common Lisp Version) loaded.~%")
  (format t "Starting game...~%")
  (main-game))

;;; Example usage (uncomment to run):
;; (start-gobang)

(format t "Gobang AI (Common Lisp Version) loaded.~%")
(format t "To play, call (start-gobang)~%")
(format t "The analysis-line function's pattern matching is a simplified version and may need further refinement for full accuracy.~%")

;;; Start the game when run as script
(start-gobang)