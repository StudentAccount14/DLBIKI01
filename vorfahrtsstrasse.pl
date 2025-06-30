% Moduldeklaration
:- module(vorfahrtsstrasse, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.
:- dynamic priority_street/2.

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

% (a) Rechts-vor-Links: Fahrzeug A hat Vorfahrt vor B, wenn A von rechts kommt.
% Die Regel selbst prüft nicht, ob beide Fahrzeuge auf (oder nicht auf) der Vorfahrtsstraße sind.
% Diese Überprüfung findet in can_go statt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    to_right_of(PosB, PosA).

% (b) Linksabbieger-Regel: Bei Gegenverkehr hat ein Fahrzeug A (das geradeaus oder rechts fährt)
% Vorfahrt gegenüber einem Fahrzeug B, das links abbiegt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    opposite(PosA, PosB),         % A und B stehen sich gegenüber
    DirB = left,                  % B will links abbiegen
    (DirA = straight; DirA = right).

% Nicht-Konflikt-Situation: Zwei Fahrzeuge stehen sich gegenüber und haben dieselbe Abbiegerichtung,
% wodurch sie sich nicht gegenseitig blockieren.
non_conflicting(PosA, Dir, PosB, Dir) :-
    opposite(PosA, PosB).

% Hilfsprädikat: Eine Vorfahrtsstraße erlaubt Fahrt für ein Fahrzeug
on_priority_street(VName) :-
    vehicle(VName, PosA, _),
    (priority_street(PosA, _) ; priority_street(_, PosA)).

% Neues Hilfsprädikat für Fall 4.
% Prüft, ob ein Fahrzeug durch ein anderes Fahrzeug blockiert wird, das gemäß den Vorfahrtsregeln Vorrang
% hätte, aber nicht auf der Vorfahrtsstraße fährt.
conflict(VName, PosA, DirA) :-
    vehicle(OtherName, PosB, DirB),
    has_priority_over(PosB, DirB, PosA, DirA),
    \+ on_priority_street(OtherName),
    OtherName \= VName.

% Hauptregel: can_go(Name) ist wahr, wenn das Fahrzeug Name fahren darf.
%Fallunterscheidungen

% Fall 1: Es gibt nur ein Fahrzeug, dann darf es fahren.
can_go(VName) :-
    vehicle(VName, _, _),
    \+ ( vehicle(OtherName, _, _), OtherName \= VName ).


% Fall 2: Es gibt mehrere Fahrzeuge auf der Vorfahrtsstraße.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    on_priority_street(VName),
    \+ (
        vehicle(OtherName, PosB, DirB),
        on_priority_street(OtherName),
        OtherName \= VName,
        % Wenn beide Fahrzeuge gegenüberliegen und denselben Fahrwunsch haben, wird der Konflikt ignoriert.
        has_priority_over(PosB, DirB, PosA, DirA)
    ).

% Fall 3:  Auto auf Vorfahrtsstraße darf fahren, wenn andere Autos nicht auf Vorfahrtsstraße sind.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    on_priority_street(VName),
    \+ (
        vehicle(OtherName, PosB, DirB),
        \+ on_priority_street(OtherName),
        OtherName \= VName
    ).

% Fall 4: Beide Fahrzeuge nicht auf der Vorfahrtsstraße.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    \+ on_priority_street(VName),
    \+ (
        vehicle(Other, _, _),
        on_priority_street(Other)
    ),
    \+ conflict(VName, PosA, DirA).