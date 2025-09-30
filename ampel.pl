% Moduldeklaration
:- module(ampel, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.
:- dynamic light/2.

% Positionen im Uhrzeigersinn: north, east, south, west 
% Fahrtrichtungen: straight, left, right (geradeaus, links, rechts)

% Fakten: opposite(X, Y) bedeutet: X und Y liegen einander gegenüber.
opposite(north, south).
opposite(south, north).
opposite(east, west).
opposite(west, east).

% Linksabbieger-Regel: Bei Gegenverkehr hat ein Fahrzeug A (das geradeaus oder rechts fährt)
% Vorfahrt gegenüber einem Fahrzeug B, das links abbiegt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    opposite(PosA, PosB),         % A und B stehen sich gegenüber
    DirB = left,                  % B will links abbiegen
    (DirA = straight; DirA = right). % A will geradeaus fahren oder rechts abbiegen

% Hilfsprädikat: has_green_light(VName) ist wahr, wenn die Zufahrt (PosA) des Fahrzeugs A (VName) aktuell Grün zeigt.
has_green_light(VName) :-
    vehicle(VName, PosA, _),
    light(PosA, green).

% Hauptregel: can_go(VName) ist wahr, wenn das Fahrzeug A (VName) fahren darf.
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
    ). % Diese Negation bedeutet es gibt kein anderes Fahrzeug mit Grün mit Vorrang vor A