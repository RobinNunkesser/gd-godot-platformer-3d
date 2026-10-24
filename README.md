# 🎮 gd-platformer-godot (Retro Tile-Platformer in Godot 4)

> **Didaktisches 2D/2.5D-Tile-Platformer-Gegenstück** zur Vorlesung *Interaktive Grafikanwendungen (IGA)*  
> Duale Implementierung (Target 1: Godot 4 Native 2D / 2.5D) basierend auf demselben **Micro-GDD** wie [`ts-babylonjs-platformer`](https://github.com/RobinNunkesser/ts-platformer-babylonjs).

---

## 🎯 Didaktische Ziele & Duale Architektur

Dieses Projekt demonstriert die Realisierung eines klassischen Tile-Platformers in **Godot 4 (GDScript)** auf Basis einer modularen ASCII-Level-Architektur, kompatibel zum wissenschaftlichen **Video Game Level Corpus (VGLC)**:

- **$\mathcal{O}(1)$ Kachel-Kollision:** Schnelle Zuordnung von Weltkoordinaten zu diskreten Kacheln ohne Paarvergleiche.
- **Engine-Native Physik:** Nutzung von `CharacterBody2D.move_and_slide()` bzw. `CharacterBody3D` (mit Z-Achsen-Lock) für stabile Kanten- und Blockkollisionen.
- **Game Feel & Saftigkeit:**
  - **Coyote Time (120 ms):** Sprünge nach Verlassen einer Kante bleiben für eine kurze Gnadenfrist gültig.
  - **Jump Buffering (120 ms):** Vorab-Eingaben kurz vor der Landung werden beim Bodenkontakt sofort ausgelöst.
  - **Variable Sprunghöhe:** Frühes Loslassen der Sprungtaste kappt den Aufwärtsimpuls.
- **Zustandsautomat & Highscore:** `READY`, `PLAYING`, `PAUSED`, `FALLEN`, `VICTORY` mit lokaler Persistenz (`user://platformer_score.save`).
- **100 % Prozedurale Grafik:** Keine proprietären Sprite-Rips oder Fremd-Assets; alle Kacheln werden rein prozedural über Farben (`ColorRect`) bzw. PBR-Materialien in 3D gerendert.

---

## 📂 Projektstruktur & Micro-GDD

```text
gd-platformer-godot/
├── docs/gdd/                   # Identische 5 Micro-GDD Bausteine
│   ├── 01_concept_and_loop.md
│   ├── 02_input_and_controls.md
│   ├── 03_architecture_dual.md
│   ├── 04_state_machine.md
│   └── 05_parameters.md
├── levels/                     # 5 kuratierte VGLC-kompatible Kampagnen-Level (100% frei / MIT)
│   ├── level-1.txt             # Welt 1-1: Tutorial & Plains (120 Spalten)
│   ├── level-2.txt             # Welt 1-2: Pipe Hills (125 Spalten)
│   ├── level-3.txt             # Welt 1-3: The Chasm (130 Spalten)
│   ├── level-4.txt             # Welt 1-4: Sky Bricks (135 Spalten)
│   └── level-5.txt             # Welt 1-5: GAN Challenge (140 Spalten)
├── scenes/
│   ├── main.tscn               # 2D-Hauptszene (ColorRect, 2D-Kamera)
│   ├── player.tscn             # 2D CharacterBody2D Szene
│   ├── main_3d.tscn            # 2.5D-Hauptszene (PBR-Kuben, Vulkan 3D-Licht & Schatten)
│   └── player_3d.tscn          # 2.5D CharacterBody3D (Z-Achse gelockt)
├── scripts/
│   ├── config.gd               # 2D Tuning-Parameter (PlatformerConfig)
│   ├── config_3d.gd            # 3D Tuning-Parameter (PlatformerConfig3D)
│   ├── tilemap_loader.gd       # 2D ASCII Parser & Spawner
│   ├── tilemap_loader_3d.gd    # 3D PBR Extrusion & Spawner
│   ├── player.gd               # 2D Kinematik, Power-Up & Schaden
│   ├── player_3d.gd            # 3D Kinematik, Power-Up & Schaden
│   ├── enemy.gd                # 2D Patrouillen-Gegner mit Stomp-Squash
│   ├── enemy_3d.gd             # 3D Patrouillen-Gegner mit Stomp-Squash
│   ├── mushroom.gd             # 2D Super-Pilz Power-Up (Wachstum)
│   ├── mushroom_3d.gd          # 3D Super-Pilz Power-Up (Wachstum)
│   ├── state_manager.gd        # Finite State Machine & Highscore
│   ├── main.gd                 # 2D Game Loop mit Kampagnen-Progression
│   └── main_3d.gd              # 3D Game Loop mit Kampagnen-Progression
├── test_gameplay.gd            # Headless Unit- & Level-Testrunner (2D & 3D, prüft alle 6 Suites)
├── LICENSE                     # MIT License
└── project.godot               # Godot 4 Projektkonfiguration
```

---

## 🗺️ Die 5-Level-Kampagne & VGLC-Kompatibilität

Das Spiel enthält eine vollwertige 5-Level-Kampagne mit fließendem Levelübergang bei Erreichen der Zielflagge (`NÄCHSTES LEVEL (X/5)` bzw. `KAMPAGNE NEUSTARTEN`):

| Level | Name | Länge | Didaktischer Fokus / Leveldesign |
|---|---|---|---|
| **Level 1** | *Tutorial / Plains* | 120 Spalten | Grundmechanik, Coin-Blöcke, erste Patrouillen-Gegner (`E`), Röhren, Treppe zum Ziel |
| **Level 2** | *Pipe Hills* | 125 Spalten | Gestaffelte Röhrenhöhen (Höhe 2, 3, 4), erhöhte Ziegelbrücken, vertikale Hindernisse & Gegner |
| **Level 3** | *The Chasm* | 130 Spalten | Weite Abgründe mit Trittsteinen; fordert *Coyote Time* und *Jump Buffering* |
| **Level 4** | *Sky Bricks* | 135 Spalten | Luftige Höhen über bodenlosen Schluchten; Multi-Story Plattform-Parcours mit Ziegel-Highways |
| **Level 5** | *GAN Challenge* | 140 Spalten | Rhythmisches PCGML-Muster mit rhythmischen Hindernis- und Gegnerketten |

Der Parser verarbeitet beliebige 14-zeilige ASCII-Karten im Standardformat des **Video Game Level Corpus (VGLC)** (*Summerville et al., FDG 2016*):

- `X` = Fester Boden / Pyramidenstufe
- `S` = Ziegelblock (*Brick* – von unten mit Super-Pilz zerstörbar)
- `?` / `Q` = Fragezeichen-Block (Münze oder Super-Pilz)
- `<>`, `[]` = Röhre (Kopf / Schaft)
- `E` = Patrouillierender Gegner (*Goomba-Stil*, Stomp-Kollision)
- `M` = Super-Pilz Power-Up
- `|` / `F` = Zielflagge (*Goal*)
- `-` = Leerraum / Luft

### 🍄 Gegner & Power-Up Mechaniken
- **Gegner (`E`):** Patrouillieren mit Gravitation und prallen an Hindernissen ab.
  - **Stomp:** Fällt die Spielfigur von oben auf den Gegner, wird er plattgedrückt (+200 Punkte) und verleiht einen Sprung-Impuls (*Bounce*).
  - **Seitentreffer:** Trifft der Gegner die normale Spielfigur, führt dies zum Absturz/Game-Over.
- **Super-Pilz (`M` / aus `?`):**
  - Verwandelt die Spielfigur in **Big Player** (+1000 Punkte).
  - **Rüstungsschutz:** Big Player überlebt einen Gegnertreffer, schrumpft zurück und erhält 1,5 s Unverwundbarkeit mit Blinken.
  - **Ziegel zerstören:** Nur Big Player kann Ziegelblöcke (`S`) von unten zerschlagen (+50 Punkte).

Wer das Spiel gegen den akademischen Forschungsbenchmark von *Super Mario Bros.* World 1-1 testen möchte, kann die Rohdatei direkt aus dem [TheVGLC/TheVGLC](https://github.com/TheVGLC/TheVGLC) Repository in den Ordner `levels/` laden:

```bash
curl -o levels/mario-1-1.txt "https://raw.githubusercontent.com/TheVGLC/TheVGLC/master/Super%20Mario%20Bros/Processed/mario-1-1.txt"
```

Liegt `levels/mario-1-1.txt` vor, wird die Datei vom Loader automatisch erkannt und als alternativer Level bereitgestellt.

---

## 🚀 Spiel starten

### 1. Im Godot 4 Editor
1. Öffne Godot 4.3+.
2. Wähle **Import** und navigiere in diesen Ordner.
3. Starte entweder:
   - `scenes/main.tscn` für die **native 2D-Version**, oder
   - `scenes/main_3d.tscn` für die **plastische 2.5D-Version mit 3D-Licht und Schatten**.

### 2. Über die Kommandozeile
```bash
# 2D-Version starten
godot scenes/main.tscn

# 2.5D-Version mit Vulkan-Licht und Parallaxe starten
godot scenes/main_3d.tscn

# Headless Unit-Tests (prüft 2D & 3D Pipelines)
godot --headless -s test_gameplay.gd
```

---

## 🎮 Steuerung

| Aktion | Tastatur |
|---|---|
| **Laufen** | `A` / `D` oder Pfeiltasten `←` / `→` |
| **Springen** | `Leertaste`, `W` oder Pfeiltaste `↑` |
| **Pause** | `P` |
| **Schnell-Reset** | `R` |

---

## 📄 Lizenz

Dieses Projekt ist unter der **[MIT-Lizenz](LICENSE)** lizenziert.

---

## 🔗 Verwandte Repositories

- **Babylon.js 2.5D Gegenstück:** [`RobinNunkesser/ts-platformer-babylonjs`](https://github.com/RobinNunkesser/ts-platformer-babylonjs)
- **Live-Demo (Web):** [https://robinnunkesser.github.io/ts-platformer-babylonjs/](https://robinnunkesser.github.io/ts-platformer-babylonjs/)
- **Vorlesung:** [Modul 10: Tile-basierte Welten & Platformer-Physik](https://robinnunkesser.github.io)
