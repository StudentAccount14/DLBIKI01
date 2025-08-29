% Moduldeklaration
:- module(kreuzung, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.

% Positionen im Uhrzeigersinn: north, east, south, west
% Fahrtrichtungen: straight, left, right (geradeaus, links, rechts)

% Fakten: to_right_of(X, Y) bedeutet: Die Straße X liegt rechts von Straße Y aus Sicht des Fahrers auf Y.
to_right_of(north, east).
to_right_of(east, south).
to_right_of(south, west).
to_right_of(west, north).

% Fakten: opposite(X, Y) bedeutet: X und Y liegen einander gegenüber.
opposite(north, south).
opposite(south, north).
opposite(west, east).
opposite(east, west).

% Fakten: Prioritäten als Tie-Breaker wenn kein Auto fahren darf.
priority_order(north, 1).
priority_order(west, 2).
priority_order(south, 3).
priority_order(east, 4).

% Rechts-vor-Links: Fahrzeug A hat Vorfahrt vor B, wenn A von rechts kommt.
has_priority_over(PosA, _DirA, PosB, _DirB) :-
    to_right_of(PosA, PosB).

% Linksabbieger-Regel: Fahrzeug A (entgegenkommend) hat Vorfahrt vor B,
% wenn B links abbiegt und A geradeaus fährt oder rechts abbiegt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    opposite(PosA, PosB),         % A und B stehen sich gegenüber
    DirB = left,                  % B will links abbiegen
    (DirA = straight; DirA = right).  % A fährt geradeaus oder will rechts abbiegen

% Nicht-Konflikt-Situation: Zwei Fahrzeuge stehen sich gegenüber und haben dieselbe Abbiegerichtung,
% wodurch sie sich nicht gegenseitig blockieren.
non_conflicting(PosA, Dir, PosB, Dir) :-
    opposite(PosA, PosB).

% Prüft, ob ein Fahrzeug VName durch ein anderes blockiert wird.
blocked_by(VName, Blocker) :-
    vehicle(VName, PosA, DirA),
    vehicle(Blocker, PosB, DirB),
    Blocker \= VName,
    \+ non_conflicting(PosA, DirA, PosB, DirB),
    has_priority_over(PosB, DirB, PosA, DirA).


% Tie-Breaker: VName hat die höchste Priorität, wenn kein anderes Fahrzeug mit
% einer besseren (niedrigeren) Priorität existiert.
tie_breaker(VName) :-
    vehicle(VName, Pos, _),
    priority_order(Pos, P),
    \+ ( vehicle(OtherName, OtherPos, _),
         OtherName \= VName,
         priority_order(OtherPos, POther),
         POther < P
       ).

% Prüft, ob kein Fahrzeug aktuell unblockiert ist, also alle Fahrzeuge blockiert sind.
no_unblocked_vehicle :-
    \+ ( vehicle(VName, _, _), \+ blocked_by(VName, _) ).

% Fall 1: Der Normalfall. Ein Fahrzeug darf fahren, wenn es nicht blockiert ist.
can_go(VName) :-
    vehicle(VName, _, _),
    \+ blocked_by(VName, _).

% Fall 2: Der Fallback-Pfad. Wenn alle Fahrzeuge blockiert sind, entscheidet der Tie-Breaker.
can_go(VName) :-
    no_unblocked_vehicle,
    tie_breaker(VName).
