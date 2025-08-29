% Moduldeklaration
:- module(ampel, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.
:- dynamic light/2.

% Positionen im Uhrzeigersinn: north, east, south, west 
% Fahrtrichtungen: straight, left, right (geradeaus, links, rechts)

% Fakten: to_right_of(X, Y) bedeutet: Die Straße X liegt rechts von Straße Y aus Sicht des Fahrers auf Y.
% Anmerkung:  Diese Fakten werden in diesem Modul nicht verwendet.
to_right_of(north, east).
to_right_of(east, south).
to_right_of(south, west).
to_right_of(west, north).

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
    (DirA = straight; DirA = right). % A will geradeaus fahren oder rechts abbiegen

% Hilfsprädikat: has_green_light(VName) ist wahr, wenn die Zufahrt des Fahrzeugs VName aktuell Grün zeigt.
has_green_light(VName) :-
    vehicle(VName, PosA, _),
    light(PosA, green).

% Hauptregel: can_go(VName) ist wahr, wenn das Fahrzeug VName fahren darf.
% Ein Fahrzeug darf nur fahren, wenn es Grün hat.
% Bei mehreren Fahrzeugen mit Grünlicht gilt die Konfliktprüfung anhand der Vorfahrtsregeln.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    has_green_light(VName),
    \+ (
        vehicle(OtherName, PosB, DirB),
        has_green_light(OtherName),
        OtherName \= VName,
        has_priority_over(PosB, DirB, PosA, DirA)
    ).