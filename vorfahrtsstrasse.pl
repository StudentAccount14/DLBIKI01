% Moduldeklaration
:- module(vorfahrtsstrasse, [vehicle/3, can_go/1]).

% Direktiven
:- dynamic vehicle/3.
:- dynamic priority_street/2.

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
opposite(east, west).
opposite(west, east).

% Rechts-vor-links-Regel: Fahrzeug A hat Vorfahrt vor B, wenn A von rechts kommt.
% Anmerkung: Diese und die nächste Regel prüfen nicht, ob beide Fahrzeuge auf (oder nicht auf)
% der Vorfahrtsstraße sind. Diese Überprüfung findet in can_go/1 statt.
has_priority_over(PosA, _DirA, PosB, _DirB) :-
    to_right_of(PosA, PosB).  % A kommt von rechts von B


% Linksabbieger-Regel: Bei Gegenverkehr hat ein Fahrzeug A (das geradeaus oder rechts fährt)
% Vorfahrt gegenüber einem Fahrzeug B, das links abbiegt.
has_priority_over(PosA, DirA, PosB, DirB) :-
    opposite(PosA, PosB),         % A und B stehen sich gegenüber
    DirB = left,                  % B will links abbiegen
    (DirA = straight; DirA = right). % A will geradeaus fahren oder rechts abbiegen

% Hilfsprädikat: Ein Fahrzeug befindet sich auf der Vorfahrtsstraße,
% wenn seine aktuelle Position Teil eines in priority_street/2 definierten Verlaufs ist.
on_priority_street(VName) :-
    vehicle(VName, PosA, _),
    (priority_street(PosA, _) ; priority_street(_, PosA)).

% Annahme: Gegenüberliegende Linksabbieger biegen voreinander in die nächste Fahrspur ab
% und behindern sich nicht.

% Hilfsprädikat für Fall 3.
% Prüft, ob ein Fahrzeug A (VName) durch ein anderes Fahrzeug B (OtherName) blockiert wird, das gemäß den Vorfahrtsregeln Vorrang
% hätte, aber nicht auf der Vorfahrtsstraße fährt.
conflict(VName, PosA, DirA) :-
    vehicle(OtherName, PosB, DirB),          % Ein Fahrzeug B existiert
    has_priority_over(PosB, DirB, PosA, DirA), % B hat nach Vorfahrtsregeln Vorrang vor A
    \+ on_priority_street(OtherName),          % B ist nicht auf Vorfahrtsstraße
    OtherName \= VName.                     % B ist nicht A

% Hauptregel: can_go(VName) ist wahr, wenn das Fahrzeug A (VName) fahren darf.
% Fallunterscheidungen
% Fall 1: Es gibt nur ein Fahrzeug, dann darf es fahren.
can_go(VName) :-
    vehicle(VName, _, _),
    \+ ( vehicle(OtherName, _, _), OtherName \= VName ).  % Es existiert kein anderes Fahrzeug


% Fall 2: Es gibt Fahrzeuge auf der Vorfahrtsstraße.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    on_priority_street(VName),
    \+ (
        vehicle(OtherName, PosB, DirB),
        on_priority_street(OtherName),
        OtherName \= VName,
        has_priority_over(PosB, DirB, PosA, DirA)
    ).  % Diese Negation bedeutet es gibt kein anderes Fahrzeug auf der Vorfahrtsstraße mit Vorrang vor A


% Fall 3: Alle Fahrzeuge sind nicht auf einer Vorfahrtsstraße.
can_go(VName) :-
    vehicle(VName, PosA, DirA),
    \+ on_priority_street(VName),
    \+ (
        vehicle(OtherName, _, _),
        on_priority_street(OtherName)
    ),
    \+ conflict(VName, PosA, DirA).

