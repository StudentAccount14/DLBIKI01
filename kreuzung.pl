% Moduldeklaration
:- module(kreuzung, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.

% Positionen im Uhrzeigersinn: north, east, south, west
% Fahrrichtungen: straight, left, right (geradeaus, links, rechts)

% Fakten: to_right_of(X, Y) bedeutet: Die Strasse X liegt rechts von Strasse Y.
to_right_of(east, north).
to_right_of(south, east).
to_right_of(west, south).
to_right_of(north, west).

% Fakten: opposite(X, Y) bedeutet: X und Y liegen einander gegenüber.
opposite(north, south).
opposite(south, north).
opposite(west, east).
opposite(east, west).

%Fakten: Prioritäten als Tie-Breaker wenn kein Auto fahren darf.
priority_order(north, 1).
priority_order(west, 2).
priority_order(south, 3).
priority_order(east, 4).

% (a) Rechts-vor-Links: Fahrzeug W hat Vorfahrt vor V, wenn W von rechts kommt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    to_right_of(PosB, PosA).

% (b) Linksabbieger-Regel: Fahrzeug A (entgegenkommend) hat Vorfahrt vor B,
% wenn B links abbiegt und A geradeaus fährt oder rechts abbiegt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    opposite(PosA, PosB),         % A und B stehen sich gegenüber
    DirB = left,                  % B will links abbiegen
    (DirA = straight; DirA = right).  % A fährt geradeaus oder will rechts abbiegen

% Nicht-Konflikt-Situation: Zwei Fahrzeuge stehen sich gegenüber und haben dieselbe Abbiegerichtung,
% wodurch sie sich nicht gegenseitig blockieren.
non_conflicting(PosA, Dir, PosB, Dir) :-
    opposite(PosA, PosB).

% Prüft, ob an ein Fahrzeug durch ein anderes blockiert wird
blocked_by(VName, Blocker) :-
    vehicle(VName, PosA, DirA),
    vehicle(Blocker, PosB, DirB),
    Blocker \= VName,
    \+ non_conflicting(PosA, DirA, PosB, DirB),
    has_priority_over(PosB, DirB, PosA, DirA).

% Prüft, ob an ein Fahrzeug V durch ein anderes indirekt blockiert wird
indirectly_blocked(V, B) :- blocked_by(V, B).
indirectly_blocked(V, B) :-
    blocked_by(V, X),
    indirectly_blocked(X, B).

% Tie-Breaker: VName hat die höchste Priorität, wenn kein anderes Fahrzeug mit
% einer besseren (niedrigeren) Priorität existiert.
tie_breaker(VName) :-
    vehicle(VName, Pos, _),
    priority_order(Pos, P),
    \+ ( vehicle(Other, OtherPos, _),
         Other \= VName,
         priority_order(OtherPos, POther),
         POther < P
       ).

% Prüft, ob kein Fahrzeug aktuell unblockiert ist, also alle Fahrzeuge (direkt oder indirekt) blockiert sind.
no_unblocked_vehicle :-
    \+ ( vehicle(V, _, _), \+ indirectly_blocked(V, _) ).

% Fall 1: Der Normalfall. Ein Fahrzeug darf fahren, wenn es nicht (indirekt) blockiert ist.
can_go(VName) :-
    vehicle(VName, _, _),
    \+ indirectly_blocked(VName, _).

% Fall 2: Fallback-Pfad, wenn kein Fahrzeug nicht blockiert ist.
can_go(VName) :-
    no_unblocked_vehicle,
    tie_breaker(VName).
