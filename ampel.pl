% Moduldeklaration
:- module(ampel, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.
:- dynamic light/2.

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
opposite(east, west).
opposite(west, east).


% Nicht-Konflikt-Situation: Zwei Fahrzeuge stehen sich gegenüber und haben dieselbe Abbiegerichtung,
% wodurch sie sich nicht gegenseitig blockieren.
non_conflicting(PosA, Dir, PosB, Dir) :-
    opposite(PosA, PosB).

% Linksabbieger-Regel: Bei Gegenverkehr hat ein Fahrzeug A (das geradeaus oder rechts fährt)
% Vorfahrt gegenüber einem Fahrzeug B, das links abbiegt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    opposite(PosA, PosB),         % A und B stehen sich gegenüber
    DirB = left,                  % B will links abbiegen
    (DirA = straight; DirA = right).

% Hilfsprädikat: Ampel erlaubt Fahrt für ein Fahrzeug
has_green_light(VName) :-
    vehicle(VName, PosA, _),
    light(PosA, green).

% Hauptregel: can_go(Name) ist wahr, wenn das Fahrzeug Name fahren darf.
% Dabei darf ein Fahrzeug nur fahren, wenn es grün hat
%Fallunterscheidungen
% Fall 1: Es gibt nur ein Fahrzeug, dann darf es fahren.
can_go(VName) :-
    vehicle(VName, _, _),
    has_green_light(VName),
    \+ ( vehicle(OtherName, _, _), OtherName \= VName ).

% Fall 2: Bei mehreren Fahrzeuge gilt die bestehende Konfliktprüfung.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    has_green_light(VName),
    \+ (
        vehicle(OtherName, PosB, DirB),
        has_green_light(OtherName),
        OtherName \= VName,
        % Wenn beide Fahrzeuge gegenüberliegen und denselben Fahrwunsch haben, wird der Konflikt ignoriert.
        \+ non_conflicting(PosA, DirA, PosB, DirB),
        has_priority_over(PosB, DirB, PosA, DirA)
    ).