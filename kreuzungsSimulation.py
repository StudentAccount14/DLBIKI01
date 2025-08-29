#Für die GUI
import tkinter as tk
#Pyswip, um SWI-Prolog über Python zu nutzen
from pyswip import Prolog
#Pillow für Bilder anpassen
from PIL import Image, ImageTk

# Um Prolog zu initialisieren
prolog = Prolog()

# Um zu Beginn ein Standard-Regelwerk zu laden ("kreuzung" für gleichrangige Kreuzungen)
current_mode = "kreuzung"
prolog.consult("kreuzung.pl")

# Globale Dictionaries für Autos, Pfeile und die Canvasobjekte
cars = {}        #speichert die Autos
arrows = {}      # speichert die Canvasobjekte der angezeigten Pfeile
arrow_car = {}   # speichert den Autonamen, der den Pfeil für einen Stapel mehrerer Autos liefert
traffic_lights = {}  # speichert die Canvasobjekte der Ampeln (die Ampeln)
priority_signs = {} # speichert die Canvasobjekte der Vorfahrtsstraße (die Schilder)

#Anzahl der Autos
car_count = 0

# Funktion zum Ändern des Regelwerks
def change_rule_set(*args):
    global current_mode, prolog
    selected = rule_var.get()
    if selected != current_mode:
        current_mode = selected
        # Prolog-Interpreter wird neu initialisiert, damit alte Moduldefinitionen keine Fehler verursachen
        prolog = Prolog()
        # Um die "alten" Vehikelfakten zu löschen (falls zurückgewechselt wird)
        list(prolog.query(f"retractall({current_mode}:vehicle(_,_,_))"))
        for car in list(cars.keys()):
            canvas.delete(cars[car]["canvas_item"])
            del cars[car]
        # GUI reseten
        # Pfeile zurücksetzen
        for pos in list(arrows.keys()):
            canvas.delete(arrows[pos])
            del arrows[pos]
            del arrow_car[pos]
        # Entfernt die alten Ampeln (falls welche vorhanden sind)
        for pos in list(traffic_lights.keys()):
            canvas.delete(traffic_lights[pos])
        traffic_lights.clear()
        # Entfernt die alten Vorfahrtsschilder (falls welche vorhanden sind)
        for key in list(priority_signs.keys()):
            canvas.delete(priority_signs[key])
        priority_signs.clear()
        #Setup für die ampelgesteuerten Kreuzungen
        if current_mode == "ampel":
            list(prolog.query("use_module('ampel.pl', [])."))
            update_ampel_config("NS gruen")
            # Zeigt die Ampelmenüs, versteckt die Vorfahrtsstraßenmenüs
            ampel_config_label.grid(row=1, column=0, padx=5, pady=5, sticky="w")
            ampel_config_menu.grid(row=1, column=1, padx=5, pady=5, sticky="w")
            priority_street_config_label.grid_remove()
            priority_street_config_menu.grid_remove()
        # Setup für die Kreuzungen mit Vorfahrtsstraße
        elif current_mode == "vorfahrtsstrasse":
            list(prolog.query("use_module('vorfahrtsstrasse.pl',[])."))
            update_priority_street_config("NS")
            # Zeigt Vorfahrtsstraßenmenüs, versteckt die Ampelmenüs
            priority_street_config_label.grid(row=1, column=0, padx=5, pady=5, sticky="w")
            priority_street_config_menu.grid(row=1, column=1, padx=5, pady=5, sticky="w")
            ampel_config_label.grid_remove()
            ampel_config_menu.grid_remove()
        else:
            list(prolog.query("use_module('kreuzung.pl',[])."))
            # Versteckt beide Menüs
            ampel_config_label.grid_remove()
            ampel_config_menu.grid_remove()
            priority_street_config_label.grid_remove()
            priority_street_config_menu.grid_remove()
        status_label.config(text=f"Regelwerk gewechselt zu: {current_mode}")

# Funktion zur Aktualisierung der Ampelkonfiguration
def update_ampel_config(selection):
    list(prolog.query(f"retractall({current_mode}:light(_, _))"))
    if selection == "NS gruen":
        list(prolog.query(f"assertz({current_mode}:light(north, green))"))
        list(prolog.query(f"assertz({current_mode}:light(south, green))"))
        list(prolog.query(f"assertz({current_mode}:light(east, red))"))
        list(prolog.query(f"assertz({current_mode}:light(west, red))"))
    else:
        list(prolog.query(f"assertz({current_mode}:light(north, red))"))
        list(prolog.query(f"assertz({current_mode}:light(south, red))"))
        list(prolog.query(f"assertz({current_mode}:light(east, green))"))
        list(prolog.query(f"assertz({current_mode}:light(west, green))"))
    update_traffic_lights(selection)
    status_label.config(text=f"Ampel: {selection}")

# Funktion zur Aktualisierung der Vorfahrtsstraßenkonfiguration
def update_priority_street_config(selection):
    list(prolog.query(f"retractall({current_mode}:priority_street(_, _))"))
    if selection == "NS":
        list(prolog.query(f"assertz({current_mode}:priority_street(north, south))"))
    elif selection == "NE":
        list(prolog.query(f"assertz({current_mode}:priority_street(north, east))"))
    elif selection == "NW":
        list(prolog.query(f"assertz({current_mode}:priority_street(north, west))"))
    elif selection == "WE":
        list(prolog.query(f"assertz({current_mode}:priority_street(west, east))"))
    elif selection == "WS":
        list(prolog.query(f"assertz({current_mode}:priority_street(west, south))"))
    elif selection == "ES":
        list(prolog.query(f"assertz({current_mode}:priority_street(east, south))"))
    update_priority_signs(selection)
    status_label.config(text=f"Verlauf Vorfahrtsstrasse: {selection}")

# Hauptfenster erstellen
root = tk.Tk()
root.title("Kreuzungssimulation für DLBIKI01")
tooltip = None

# Globales resizen und laden der PNG-Bildes
# Lädt das Hintergrundbild der Kreuzung und skaliert es auf 400×400
bg_pil_image = Image.open("Kreuzung.png").resize((400, 400))
bg_image = ImageTk.PhotoImage(bg_pil_image)

# Lädt und skaliert die Ampelbilder
ampel_green_pil = Image.open("gruene_ampel.png").resize((40, 60))
ampel_red_pil = Image.open("rote_ampel.png").resize((40, 60))
ampel_green_image = ImageTk.PhotoImage(ampel_green_pil)
ampel_red_image = ImageTk.PhotoImage(ampel_red_pil)

# Lädt das Vorfahrtsschild und skaliert es
priority_sign_pil = Image.open("vorfahrtsstrasse.png").resize((40, 40))
priority_sign_image = ImageTk.PhotoImage(priority_sign_pil)

# Statusanzeige
status_label = tk.Label(root, text="Bitte Auto hinzufügen")
status_label.pack(pady=10)

# Canvas für die grafische Darstellung der Kreuzung
canvas = tk.Canvas(root, width=400, height=400, bg="lightgrey")
canvas.pack(pady=10)

# Platziert das Hintergrundbild auf dem Canvas
canvas_bg = canvas.create_image(200, 200, image=bg_image)

#Alternative, falls es Probleme mit dem Hintergrundbild gibt:
#canvas.create_line(200, 0, 200, 300, width=80, fill="gray")
#canvas.create_line(0, 150, 400, 150, width=80, fill="gray")

# Zum Beschriften der Zufahrtsstraßen
canvas.create_text(200, 80, text="NORTH", fill="white", font=("Arial", 12, "bold"))
canvas.create_text(200, 320, text="SOUTH", fill="white", font=("Arial", 12, "bold"))
canvas.create_text(350, 200, text="EAST", fill="white", font=("Arial", 12, "bold"))
canvas.create_text(60, 200, text="WEST", fill="white", font=("Arial", 12, "bold"))

# Funktionen zum Zeichnen der Ampeln und Vorfahrtsschilder

# Funktion zum Zeichnen der Ampeln
def update_traffic_lights(selection):
    # Löscht die alten Ampeln, falls sie noch vorhanden sind
    for dir in list(traffic_lights.keys()):
        canvas.delete(traffic_lights[dir])
    traffic_lights.clear()
    # Setzt Positionen für die Ampeln
    positions = {
        "north": (125, 125),
        "south": (275, 275),
        "east": (275, 125),
        "west": (125, 275)
    }
    #Für normale Ampelsituationen gibt es nur 2 Möglichkeiten: NS oder EW grün
    if selection == "NS gruen":
        # Norden und Süden: Grün, Osten und Westen: Rot
        traffic_lights["north"] = canvas.create_image(positions["north"][0], positions["north"][1], image=ampel_green_image)
        traffic_lights["south"] = canvas.create_image(positions["south"][0], positions["south"][1], image=ampel_green_image)
        traffic_lights["east"] = canvas.create_image(positions["east"][0], positions["east"][1], image=ampel_red_image)
        traffic_lights["west"] = canvas.create_image(positions["west"][0], positions["west"][1], image=ampel_red_image)
    else:
        # Andernfalls: Norden und Süden: Rot, Westen und Osten: Grün
        traffic_lights["north"] = canvas.create_image(positions["north"][0], positions["north"][1],
                                                      image=ampel_red_image)
        traffic_lights["south"] = canvas.create_image(positions["south"][0], positions["south"][1],
                                                      image=ampel_red_image)
        traffic_lights["east"] = canvas.create_image(positions["east"][0], positions["east"][1], image=ampel_green_image)
        traffic_lights["west"] = canvas.create_image(positions["west"][0], positions["west"][1], image=ampel_green_image)

# Funktion zum Zeichnen der Vorfahrtsschilder
def update_priority_signs(config):
    # Löscht die alten Vorfahrtsschilder
    for key in list(priority_signs.keys()):
        canvas.delete(priority_signs[key])
    priority_signs.clear()
    # Definiert, welche Zufahrtsstraßen bei welcher Einstellung Schilder erhalten
    config_map = {
        "NS": ["north", "south"],
        "NE": ["north", "east"],
        "NW": ["north", "west"],
        "WE": ["west", "east"],
        "WS": ["west", "south"],
        "ES": ["east", "south"]
    }
    # Festgelegte Positionen für Schilder (nach Gefühl angepasst)
    positions = {
        "north": (125, 125),
        "south": (275, 275),
        "east": (275, 125),
        "west": (125, 275)
    }
    for direction in config_map.get(config, []):
        sign = canvas.create_image(positions[direction][0], positions[direction][1], image=priority_sign_image)
        priority_signs[direction] = sign


# Tooltip-Funktion, damit der Namen des Autos beim Mouse-Over angezeigt wird
def show_tooltip(event):
    global tooltip
    x, y = event.x, event.y
    items = canvas.find_overlapping(x, y, x, y)
    info_list = []
    for car_name, data in cars.items():
        if data["canvas_item"] in items:
            info_list.append(f"{car_name}: {data['position']}, {data['richtung']}")
    if info_list:
        tooltip_text = "\n".join(info_list)
        if tooltip is None:
            tooltip = tk.Toplevel(root)
            tooltip.wm_overrideredirect(True)
            label = tk.Label(tooltip, text=tooltip_text, background="lightyellow",
                             relief="solid", borderwidth=1, font=("Arial", 10))
            label.pack()
            tooltip.label = label
        else:
            tooltip.label.config(text=tooltip_text)
        # Tooltip mit kleinem Offset neben dem Mauszeiger positionieren
        tooltip.wm_geometry(f"+{event.x_root + 10}+{event.y_root + 10}")
    else:
        if tooltip:
            tooltip.destroy()
            tooltip = None
# Events zum Aktualisieren und zum Ausblenden des Tooltip
canvas.bind("<Motion>", show_tooltip)
canvas.bind("<Leave>", lambda event: (tooltip.destroy() if tooltip else None))

#Der Rahmen für die Steuerungselemente
control_frame = tk.Frame(root)
control_frame.pack(pady=10)

#Dropdown-Menü für die Regelwerksauswahl
rule_label = tk.Label(control_frame, text="Regelwerk:")
rule_label.grid(row=0, column=0, padx=5)
rule_var = tk.StringVar(value="kreuzung")
rule_options = ["kreuzung", "ampel", "vorfahrtsstrasse"]
rule_menu = tk.OptionMenu(control_frame, rule_var, *rule_options, command=change_rule_set)
rule_menu.grid(row=0, column=1, padx=5)

# Dropdown-Menü um die Position der Autos auszuwählen
position_label = tk.Label(control_frame, text="Position:")
position_label.grid(row=0, column=2, padx=5)
position_var = tk.StringVar(value="north")
position_options = ["north", "south", "west", "east"]
position_menu = tk.OptionMenu(control_frame, position_var, *position_options)
position_menu.grid(row=0, column=3, padx=5)

# Dropdown-Menü für die Fahrtrichtungswahl (right, left, straight)
direction_label = tk.Label(control_frame, text="Richtung:")
direction_label.grid(row=0, column=4, padx=5)
direction_var = tk.StringVar(value="straight")
direction_options = ["right", "left", "straight"]
direction_menu = tk.OptionMenu(control_frame, direction_var, *direction_options)
direction_menu.grid(row=0, column=5, padx=5)

# Dropdown-Menü für die Ampelkonfiguration (nur bei ampelgesteuerter Kreuzung)
ampel_config_label = tk.Label(control_frame, text="Ampelkonfiguration:")
ampel_config_var = tk.StringVar(value="NS gruen")
ampel_config_options = ["NS gruen", "EW gruen"]
ampel_config_menu = tk.OptionMenu(control_frame, ampel_config_var, *ampel_config_options, command=update_ampel_config)
ampel_config_label.grid_remove()
ampel_config_menu.grid_remove()

# Dropdown-Menü für den Verlauf der Vorfahrtsstraße (nur bei Kreuzung mit Vorfahrtsstraße)
priority_street_config_label = tk.Label(control_frame, text="Verlauf Vorfahrtsstraße:")
priority_street_config_var = tk.StringVar(value="NS")
priority_street_config_options = ["NS", "NE", "NW", "WE", "WS", "ES"]
priority_street_config_menu = tk.OptionMenu(control_frame, priority_street_config_var, *priority_street_config_options, command=update_priority_street_config)
priority_street_config_label.grid_remove()
priority_street_config_menu.grid_remove()

# Hilfsfunktion: Zeichnet einen Pfeil, der die Fahrtrichtung anzeigt.
# Dabei werden Position und Richtung (straight, left, right) berücksichtigt.
def create_direction_arrow(pos, direction, x, y):
    if pos == "north":
        if direction == "straight":
            return canvas.create_line(x, y + 10, x, y + 30, arrow=tk.LAST, width=4)
        elif direction == "left":
            return canvas.create_line(x, y + 10, x + 20, y + 10, arrow=tk.LAST, width=4)
        elif direction == "right":
            return canvas.create_line(x, y + 10, x - 20, y + 10, arrow=tk.LAST, width=4)
    elif pos == "south":
        if direction == "straight":
            return canvas.create_line(x, y - 10, x, y - 30, arrow=tk.LAST, width=4)
        elif direction == "left":
            return canvas.create_line(x, y - 10, x - 20, y - 10, arrow=tk.LAST, width=4)
        elif direction == "right":
            return canvas.create_line(x, y - 10, x + 20, y - 10, arrow=tk.LAST, width=4)
    elif pos == "east":
        if direction == "straight":
            return canvas.create_line(x - 10, y, x - 30, y, arrow=tk.LAST, width=4)
        elif direction == "left":
            return canvas.create_line(x - 10, y, x - 10, y + 20, arrow=tk.LAST, width=4)
        elif direction == "right":
            return canvas.create_line(x - 10, y, x - 10, y - 20, arrow=tk.LAST, width=4)
    elif pos == "west":
        if direction == "straight":
            return canvas.create_line(x + 10, y, x + 30, y, arrow=tk.LAST, width=4)
        elif direction == "left":
            return canvas.create_line(x + 10, y, x + 10, y - 20, arrow=tk.LAST, width=4)
        elif direction == "right":
            return canvas.create_line(x + 10, y, x + 10, y + 20, arrow=tk.LAST, width=4)
    return None

# Aktualisiert oder entfernt den Pfeil, falls das führende Auto entfernt wurde (losgefahren ist).
def update_arrow_for_position(pos):
    candidates = []
    for car_name, data in cars.items():
        if data["position"] == pos:
            try:
                idx = int(car_name[3:])
            except:
                idx = 9999
            candidates.append((idx, car_name, data))
    if pos in arrows:
        canvas.delete(arrows[pos])
        del arrows[pos]
        del arrow_car[pos]
    if candidates:
        candidates.sort(key=lambda tup: tup[0])
        chosen = candidates[0]
        new_car = chosen[1]
        x, y = canvas.coords(cars[new_car]["canvas_item"])
        arrow_item = create_direction_arrow(pos, cars[new_car]["richtung"], x, y)
        arrows[pos] = arrow_item
        arrow_car[pos] = new_car

# Statusaktualisierung (Label über der Kreuzung)
def update_status():
    if not cars:
        status_label.config(text="Bitte Auto hinzufügen")
    else:
        status_label.config(text="Klicken Sie auf ein Auto, um zu prüfen, ob es fahren darf.")

# Neues Auto hinzufügen
def add_car():
    global car_count
    car_name = f"car{car_count}"
    posA = position_var.get().lower()
    dirA = direction_var.get().lower()
    prolog.assertz(f"{current_mode}:vehicle({car_name}, {posA}, {dirA})")
    if posA == "north":
        x, y = 180, 125
    elif posA == "south":
        x, y = 220, 275
    elif posA == "east":
        x, y = 275, 180
    elif posA == "west":
        x, y = 125, 220
    # Bestimmt den Drehwinkel des Autobilds anhand der Position. (Pillow dreht standardmäßig gegen den Uhrzeigersinn.)
    angle = 0
    if posA == "south":
        angle = 180
    elif posA == "east":
        angle = -90
    elif posA == "west":
        angle = 90
    # Lädt das Originalbild des Autos
    base_pil_image = Image.open("car.png").resize((50, 50))
    # Dreht das Bild entsprechend
    rotated_pil_image = base_pil_image.rotate(angle, expand=True)
    # Konvertiert das gedrehte Bild zu einem für Tkinter kompatiblen PhotoImage
    car_image_rotated = ImageTk.PhotoImage(rotated_pil_image)
    # Zeichnet das Auto als Bild im Canvas
    item = canvas.create_image(x, y, image=car_image_rotated, tags=car_name)
    #Referenz damit das Bild nicht vom Garbage Collector gelöscht wird
    cars[car_name] = {"position": posA, "richtung": dirA, "canvas_item": item, "image": car_image_rotated}

    #Version ohne Autobild, nur ein blauer Kreis
    #item = canvas.create_oval(x - 15, y - 15, x + 15, y + 15, fill="blue", outline="black", tags=car_name)
    #cars[car_name] = {"position": posA, "richtung": dirA, "canvas_item": item}

    canvas.tag_bind(car_name, "<Button-1>", lambda event, cn=car_name: check_car_status(cn))
    # Erstellt einen Pfeil, falls an dieser Position noch keiner vorhanden ist
    if posA not in arrow_car:
        arrow_item = create_direction_arrow(posA, dirA, x, y)
        arrows[posA] = arrow_item
        arrow_car[posA] = car_name
    # Pfeil in den Vordergrund holen, damit er nicht von neu hinzugefügten Autos überdeckt wird
    canvas.tag_raise(arrows[posA])
    car_count += 1
    update_status()

# Button zum Hinzufügen eines neuen Autos
add_car_button = tk.Button(control_frame, text="Auto hinzufügen", command=add_car)
add_car_button.grid(row=0, column=6, padx=5)

# Zum Prüfen, ob ein Auto fahren darf (sendet eine entsprechende Prolog-Anfrage)
def check_car_status(car_name):
    query = f"{current_mode}:can_go({car_name})"
    result = list(prolog.query(query))
    if result:
        msg = f"{car_name} darf fahren."
    else:
        msg = f"{car_name} darf nicht fahren."
    status_label.config(text=msg)

#Zum Ermitteln, welches Auto als Nächstes fahren kann
def next_car():
    # Prüft, ob ein Auto vorhanden ist
    if not cars:
        status_label.config(text="Kein Auto vorhanden. Bitte Auto hinzufügen.")
        return

    query_result = list(prolog.query(f"{current_mode}:can_go(X)"))
    if query_result:
        next_car_name = query_result[0]['X']
        print(f"{next_car_name} darf als Nächstes fahren.")
        status_label.config(text=f"{next_car_name} fährt jetzt.")
        if next_car_name in cars:
            posA = cars[next_car_name]["position"]
            dirA = cars[next_car_name]["richtung"]
            prolog.retract(f"{current_mode}:vehicle({next_car_name}, {posA}, {dirA})")
            canvas.delete(cars[next_car_name]["canvas_item"])
            del cars[next_car_name]
            if posA in arrow_car and arrow_car[posA] == next_car_name:
                update_arrow_for_position(posA)
        else:
            #Für die Fehlersuche
            print(f"Fehler, den Code noch einmal prüfen.")
    else:
        print("Kein Fahrzeug darf fahren.")
        status_label.config(text="Kein Fahrzeug darf fahren.")
    root.after(4000, update_status)

# Button, der das nächste Auto "losfahren" lässt (also entfernt)
next_car_button = tk.Button(control_frame, text="Nächstes Auto fahren lassen", command=next_car)
next_car_button.grid(row=0, column=7, padx=5)

root.mainloop()