:- use_module(library(lists)).
:- use_module(library(clpfd)).
:- use_module(library(random)).


% transpose(+Matrix, -Transposed) - транспонує матрицю.

% maplist(+Pred, +List) - застосовує предикат Pred до кожного елементу списку, повертає true\false.
% maplist(+Pred, +List, -List2) - застосовує предикат Pred до кожного елементу списку і повертає перетворений список.

% flatten(+NestedList, -FlatList) - Перетворює вкладені списки у плоский список — без підсписків.
% member(+Element, +List) - Перевіряє, чи Element належить до списку List.

% nth0(+Index, +List, ?Element) - отримує елемент з індексом Index у списку List або знаходить індекс для Element.


% === Створення дошки ===
% init_board(+N, +M, -Board)
init_board(N, M, Board) :-
    length(Row, M),
    maplist(=('e'), Row),
    length(Board, N),
    maplist(=(Row), Board).

% === Хід гравця ===
% drop_token(+Board, +Col, +Player, -NewBoard)
drop_token(Board, Col, Player, NewBoard) :-
    transpose(Board, Transposed),
    nth0(Col, Transposed, Column),
    reverse(Column, Rev),
    replace_first_e(Rev, Player, PlayerRev),
    reverse(PlayerRev, NewColumn),
    replace_column(Transposed, Col, NewColumn, NewTransposed),
    transpose(NewTransposed, NewBoard).

% replace_first_e(+RevColumn, +Player, -NewColumn)
replace_first_e([e|Rest], Player, [Player|Rest]) :- !.
replace_first_e([H|T], Player, [H|R]) :- replace_first_e(T, Player, R).

% replace_column(+Board, +Index, +NewCol, -NewBoard)
replace_column(Board, Index, NewCol, NewBoard) :-
    nth0(Index, Board, _, Rest),
    nth0(Index, NewBoard, NewCol, Rest).

% === Перевірка на перемогу ===
% check_win(+Board, +K, +Player)
check_win(Board, K, Player) :-
    ( row_win(Board, K, Player), !
    ; column_win(Board, K, Player), !
    ; diag1_win(Board, K, Player), !
    ; diag2_win(Board, K, Player)
    ).

% row_win(+Board, +K, +Player)
row_win(Board, K, Player) :-
    member(Row, Board),
    consecutive_k(Row, K, Player).

% column_win(+Board, +K, +Player)
column_win(Board, K, Player) :-
    transpose(Board, Columns),
    row_win(Columns, K, Player).

% diag1_win(+Board, +K, +Player)
diag1_win(Board, K, Player) :-
    diagonals(Board, Diags),
    member(Diag, Diags),
    consecutive_k(Diag, K, Player).

% diag2_win(+Board, +K, +Player)
diag2_win(Board, K, Player) :-
    maplist(reverse, Board, Reversed),
    diagonals(Reversed, Diags),
    member(Diag, Diags),
    consecutive_k(Diag, K, Player).

% === K поспіль значень для гравця ===
% consecutive_k(+List, +K, +Player)
consecutive_k(List, K, Player) :-
    length(Slice, K),
    maplist(=(Player), Slice),
    append(_, Rest, List),
    append(Slice, _, Rest).

% === Всі можливі діагоналі з дошки для перевірки виграшу ===
% diagonals(+Board, -Diags)
diagonals(Board, Diags) :-
    length(Board, N),
    Board = [Row|_],
    length(Row, M),
    MinD is -(N - 1),
    MaxD is M - 1,
    numlist(MinD, MaxD, Ds),
    findall(Diag, (member(D, Ds), diagonal(Board, D, Diag)), Diags).

% diagonal(+Board, -Diag)
diagonal(Board, D, Diag) :-
    findall(E, (
        nth0(I, Board, R),
        J is I + D,
        J >= 0,
        length(R, Len), J < Len,
        nth0(J, R, E)
    ), Diag),
    Diag \= [].

% === Зміна гравця ===
% switch_player(+Current, -Next)
switch_player(x, o).
switch_player(o, x).

% === Перевірка на нічию ===
% full_board(+Board)
full_board(Board) :-
    flatten(Board, Flat),
    \+ member(e, Flat).


% === AI: ===
% choose_move(+Board, +Player, +K, +Mode, -Col)

choose_move(Board, Player, K, ai-easy, Col) :-
    try_win(Board, Player, K, Col), !;
    findall(C, valid_move(Board, C), [Col|_]).


choose_move(Board, Player, K, ai-medium, Col) :-
    try_win(Board, Player, K, Col), !;
    try_block(Board, Player, K, Col), !;
    best_move_minimax(Board, Player, K, 2, Col), !.

choose_move(Board, Player, K, ai-hard, Col) :-
    valid_columns(Board, Cols),
    length(Cols, L),
    ( L < 5 -> Depth = 4 ; Depth = 3 ),
    ( try_win(Board, Player, K, Col), !
    ; try_block(Board, Player, K, Col), !
    ; best_move_minimax(Board, Player, K, Depth, Col) ).


% try_block(+Board, +Player, +K, -Col)
try_block(Board, Player, K, Col) :-
    switch_player(Player, Opponent),
    valid_columns(Board, Cols),
    member(Col, Cols), 
    drop_token(Board, Col, Opponent, B), 
    check_win(B, K, Opponent), 
    !.

% try_win(+Board, +Player, +K, -Col)
try_win(Board, Player, K, Col) :-
    valid_columns(Board, Cols),
    once((
        member(Col, Cols),
        drop_token(Board, Col, Player, B1),
        check_win(B1, K, Player)
    )).

% valid_columns(+Board, -Cols)
valid_columns(Board, []) :- Board == [], !.
valid_columns(Board, Cols) :-
    nth0(0, Board, Row),
    length(Row, M),
    M1 is M - 1,
    numlist(0, M1, All),
    findall(C, (member(C, All),
     valid_move(Board, C)), Cols).

% valid_move(+Board, +Col)
valid_move(Board, Col) :-
    transpose(Board, Trans),
    nth0(Col, Trans, Column),
    member(e, Column).

% === Minimax with Alpha-Beta ===
% best_move_minimax(+Board, +Player, +K, +Depth, -BestCol)

best_move_minimax(Board, Player, K, Depth, BestCol) :-
    valid_columns(Board, AllCols),
    length(AllCols, L),
    MaxCols is min(4, L),  % розглядає тільки до 4 кращих колонок
    findall(C, (
        member(C, AllCols),
        drop_token(Board, C, Player, B1),
        evaluate_heuristic(B1, S),
        S > 0
    ), Preferred),
    append(Preferred, AllCols, Mixed),
    list_to_set(Mixed, LimitedCols),
    length(ColsToTry, MaxCols),
    append(ColsToTry, _, LimitedCols),
    maplist(evaluate_move(Board, Player, K, Depth), ColsToTry, Scores),
    pairs_keys_values(Pairs, Scores, ColsToTry),
    findall(Score, member(Score-_, Pairs), ScoreList),
    max_list(ScoreList, MaxScore),
    findall(C, member(MaxScore-C, Pairs), BestCols),
    random_member(BestCol, BestCols).

% evaluate_move(+Board, +Player, +K, +Depth, +Col, -Score)
evaluate_move(Board, Player, K, Depth, Col, Score) :-
    drop_token(Board, Col, Player, NewBoard),
    Depth1 is Depth - 1,
    switch_player(Player, Opponent),
    minimax_ab(NewBoard, Opponent, K, Depth1, -100000, 100000, Score).

% minimax_ab(+Board, +Player, +K, +Depth, +Alpha, +Beta, -Score)
minimax_ab(Board, Player, K, Depth, Alpha, Beta, Score) :-
    ( check_win(Board, K, x) -> Score = 10000
    ; check_win(Board, K, o) -> Score = -10000
    ; full_board(Board) -> Score = 0
    ; Depth = 0 -> evaluate_heuristic(Board, Score)
    ; valid_columns(Board, Cols),
      ab_loop(Cols, Board, Player, K, Depth, Alpha, Beta, Score)
    ).

% ab_loop(+Cols, +Board, +Player, +K, +Depth, +Alpha, +Beta, -FinalScore)
ab_loop([], _, _, _, _, Alpha, _, Alpha).
ab_loop([Col|Cols], Board, Player, K, Depth, Alpha, Beta, FinalScore) :-
    drop_token(Board, Col, Player, NewBoard),
    Depth1 is Depth - 1,
    switch_player(Player, Opponent),
    minimax_ab(NewBoard, Opponent, K, Depth1, Alpha, Beta, Score),
    ( Player = x ->
        NewAlpha is max(Alpha, Score),
        ( NewAlpha >= Beta -> FinalScore = NewAlpha 
        ; ab_loop(Cols, Board, Player, K, Depth, NewAlpha, Beta, FinalScore) )
    ; Player = o ->
        NewBeta is min(Beta, Score),
        ( Alpha >= NewBeta -> FinalScore = NewBeta 
        ; ab_loop(Cols, Board, Player, K, Depth, Alpha, NewBeta, FinalScore) )
    ).

% === Improved Heuristic ===
% evaluate_heuristic(+Board, -Score)
evaluate_heuristic(Board, Score) :-
    score_lines(Board, x, ScoreX),
    score_lines(Board, o, ScoreO),
    Score is ScoreX - ScoreO.

% score_lines(+Board, +Player, -Score)
score_lines(Board, Player, Score) :-
    findall(S, (
        member(Line, Board), % горизонтальні
        line_score(Line, Player, S)
    ), Scores1),
    transpose(Board, Columns),
    findall(S, (
        member(Col, Columns),
        line_score(Col, Player, S)
    ), Scores2),
    diagonals(Board, Diags1),
    maplist(reverse, Board, RevBoard),
    diagonals(RevBoard, Diags2),
    append([Scores1, Scores2], ScoresH),
    append([Diags1, Diags2], Diags),
    findall(S, (member(D, Diags), line_score(D, Player, S)), Scores3),
    append(ScoresH, Scores3, All),
    sum_list(All, Score).

% line_score(+Line, +Player, -Score)
line_score(Line, Player, Score) :-
    ( consecutive_k(Line, 3, Player) -> Score = 100
    ; consecutive_k(Line, 2, Player) -> Score = 10
    ; consecutive_k(Line, 1, Player) -> Score = 1
    ; Score = 0
    ).