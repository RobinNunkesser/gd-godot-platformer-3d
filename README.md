# 🎮 gd-godot-platformer-3d (Retro 2.5D Platformer in Godot 4)

> **Plastischer 2.5D-Retro-Platformer in Godot 4** mit vollständiger VGLC-Gegnersuite, gestufter Power-Up-Progression (Super-Pilz, Feuerblume, Super-Stern) und PBR-Rendering mit Licht & Schatten.

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
│   ├── tilemap_loader.gd       # 2D ASCII Parser & Spawner (vollständige VGLC-Palette)
│   ├── tilemap_loader_3d.gd    # 3D PBR Extrusion & Spawner
│   ├── player.gd               # 2D Kinematik, PowerState (Small/Big/Fire), Starman, Feuerbälle
│   ├── player_3d.gd            # 3D Kinematik, PowerState, Starman, Feuerbälle
│   ├── enemy.gd                # 2D Goomba (Patrouille, Stomp-Squash)
│   ├── enemy_3d.gd             # 3D Goomba (Patrouille, Stomp-Squash)
│   ├── enemy_koopa.gd          # 2D Koopa Troopa (Patrouille, Panzer-Rückzug, Kick-Schlittern)
│   ├── enemy_koopa_3d.gd       # 3D Koopa Troopa
│   ├── bullet_bill.gd          # 2D Bullet Bill Projektil (horizontale Flugbahn, Stompbar)
│   ├── bullet_bill_3d.gd       # 3D Bullet Bill Projektil
│   ├── cannon.gd               # 2D Kanonenturm (Launcher B / Standfuß b, dynamisches Abfeuern)
│   ├── cannon_3d.gd            # 3D Kanonenturm
│   ├── piranha_plant.gd        # 2D Piranha-Pflanze (Röhren-Ausfahren, Stomp-resistent, Feuerball-anfällig)
│   ├── piranha_plant_3d.gd     # 3D Piranha-Pflanze
│   ├── fireball.gd             # 2D Hüpfender Feuerball-Projektil
│   ├── fireball_3d.gd          # 3D Hüpfender Feuerball-Projektil
│   ├── mushroom.gd             # 2D Super-Pilz Power-Up (Wachstum)
│   ├── mushroom_3d.gd          # 3D Super-Pilz Power-Up (Wachstum)
│   ├── flower.gd               # 2D Feuerblume Power-Up
│   ├── flower_3d.gd            # 3D Feuerblume Power-Up
│   ├── star.gd                 # 2D Super-Stern (Starman) Power-Up mit Sprungphysik
│   ├── star_3d.gd              # 3D Super-Stern Power-Up
│   ├── state_manager.gd        # Finite State Machine & Highscore
│   ├── main.gd                 # 2D Game Loop mit Kampagnen-Progression & Projektilen
│   └── main_3d.gd              # 3D Game Loop mit Kampagnen-Progression & Projektilen
├── test_gameplay.gd            # Headless Unit- & Level-Testrunner (2D & 3D, prüft alle 6 Suites)
├── LICENSE                     # MIT License
└── project.godot               # Godot 4 Projektkonfiguration
```

---

## 🗺️ Die 5-Level-Kampagne & VGLC-Kompatibilität

Das Spiel enthält eine vollwertige 5-Level-Kampagne mit fließendem Levelübergang bei Erreichen der Zielflagge (`NÄCHSTES LEVEL (X/5)` bzw. `KAMPAGNE NEUSTARTEN`):

| Level | Name | Länge | Didaktischer Fokus / Leveldesign |
|---|---|---|---|
| **Level 1** | *Tutorial / Plains* | 120 Spalten | Grundmechanik, Münzblöcke, Goombas (`E`), Koopa (`K`), Piranha-Röhre (`P`), Kanone (`B`/`b`) |
| **Level 2** | *Pipe Hills* | 125 Spalten | Gestaffelte Röhrenhöhen mit Piranha-Pflanzen, Ziegelbrücken, Koopas und Kanonentürme |
| **Level 3** | *The Chasm* | 130 Spalten | Weite Abgründe mit Trittsteinen, Goombas, Koopas; fordert *Coyote Time* und *Jump Buffering* |
| **Level 4** | *Sky Bricks* | 135 Spalten | Luftige Höhen über Schluchten; Multi-Story Plattform-Parcours mit Ziegel-Highways & Koopas |
| **Level 5** | *GAN Challenge* | 140 Spalten | Vollständiger Obstacle-Mix mit Goombas, Koopas, Röhren-Piranhas, Kanonen und Münz-Runs |

Der Parser verarbeitet beliebige 14-zeilige ASCII-Karten im Standardformat des **Video Game Level Corpus (VGLC)** (*Summerville et al., FDG 2016*):

- `X` = Fester Boden / Pyramidenstufe
- `S` = Ziegelblock (*Brick* – von unten mit Super-Pilz/Feuerblume zerstörbar)
- `?` / `Q` = Fragezeichen-Block (Münze, Super-Pilz, Feuerblume oder Super-Stern)
- `<>`, `[]` = Röhre (Kopf / Schaft)
- `o` = Sammelbare Münze (+100 Punkte)
- `E` = Goomba (*Moving Enemy*, Stomp-Kollision)
- `K` / `k` = Koopa Troopa (Patrouille, Stomp -> Panzer-Rückzug, kickbar)
- `B` / `b` = Bullet Bill Kanone (`B` = Rohrmündung/Launcher, `b` = Standfuß)
- `P` / `y` = Piranha-Pflanze (fährt periodisch aus Röhren aus, unzerstörbar durch Sprung)
- `M` = Super-Pilz Power-Up
- `f` / `F` = Feuerblume Power-Up (bzw. `F` an der Zielflagge)
- `*` = Super-Stern (Starman) Power-Up
- `|` / `F` = Zielflagge (*Goal*)
- `-` = Leerraum / Luft

### 🍄 Vollständige Power-Up Progression
- **Stufenleiter:** `SMALL` ➔ `BIG` (Super-Pilz) ➔ `FIRE` (Feuerblume).
- **Super-Pilz (`M` / aus `?`):**
  - Verwandelt die Spielfigur in **Big Player** (+1000 Punkte).
  - Ermöglicht das Zerschlagen von Ziegelblöcken (`S`) von unten (+50 Punkte).
- **Feuerblume (`f` / aus `?`):**
  - Verwandelt die Spielfigur in **Fire Player** (weißer Rennanzug mit orangem Visier).
  - Ermöglicht das Verschießen hüpfender Feuerbälle (`F` / `Shift` / `X` / `J`), die Gegner wie Goombas, Koopas und Piranha-Pflanzen auf Distanz besiegen (+200 Punkte).
- **Super-Stern / Starman (`*` / aus `?`):**
  - Verleiht 10 Sekunden lang unbesiegbare Unverwundbarkeit mit Regenbogen-Farbzyklus.
  - Jeder berührte Gegner (Goomba, Koopa, Piranha-Pflanze, Bullet Bill) wird bei Kontakt sofort vaporisiert (+200 Punkte).
- **Gestufte Rüstung (Stepped Armor):**
  - Treffer als Fire Player ➔ Rückstufung zu Big Player + 1,5 s Unverwundbarkeitsblinken.
  - Treffer als Big Player ➔ Rückstufung zu Small Player + 1,5 s Unverwundbarkeitsblinken.
  - Treffer als Small Player ➔ Absturz / Game Over.

### 🐢 Vollständiges VGLC-Gegner-Verhalten
- **Goomba (`E`):** Patrouilliert am Boden. Ein Sprung von oben plättet ihn; Seitentreffer schaden dem Spieler.
- **Koopa Troopa (`K`):**
  - Ein Sprung von oben zieht den Kopf ein und versetzt ihn in den Zustand `SHELL_IDLE`.
  - Ein Tritt (von oben oder von der Seite) schlägt den Panzer in `SHELL_SLIDING` (440 px/s / 11 m/s).
  - Der gleitende Panzer prallt an Wänden ab und räumt alle Gegner auf seinem Weg ab!
- **Bullet Bill Kanone (`B` / `b`):**
  - Feuert in Intervallen schwere Bullet Bills horizontal in Richtung des Spielers ab.
  - Bullet Bills fliegen ohne Schwerkraft und können von oben per Stomp unschädlich gemacht werden.
- **Piranha-Pflanze (`P`):**
  - Fährt sinusförmig aus Röhren empor.
  - Gefährlich von allen Seiten: Kann **nicht** von oben durch Sprung besiegt werden!
  - Kann ausschließlich durch Feuerbälle oder im Starman-Modus zerstört werden.

---

## 🎮 Konfigurierbare Steuerung

Die Steuerung kann jederzeit über den UI-Button im Start- und Pause-Menü oder über die Taste **`[C]`** (bzw. Gamepad **`[LB]`**) zwischen 4 Schemata umgeschaltet werden:

| Aktion | Tastatur 1 (WASD) | Tastatur 2 (Pfeile) | Gamepad (Controller) |
|---|---|---|---|
| **Laufen** | `A` / `D` | `←` / `→` | Linker Stick / D-Pad |
| **Springen** | `Leertaste` / `W` | `↑` / `Rechtes Strg` / `Numpad 0` | Button `A` (Kreuz) / Button `Y` |
| **Feuerball schießen** | `Shift` / `F` / `X` / `J` | `Enter` / `KP_Enter` / `Numpad 1` | Button `X` / `B` / Rechter Trigger `RT` |
| **Pause** | `P` / `Esc` | `P` / `Esc` | Button `Start` |
| **Schnell-Reset** | `R` | `R` | Button `Select / Back` |
| **Steuerung wechseln** | `C` | `C` | Button `LB` (Left Bumper) |

Zusätzlich steht das Schema **„Alle aktiv (Kombiniert)“** bereit, bei dem sämtliche Eingabemethoden simultan reagieren.

---

## 🎨 3D-Modelle & Animationen (Quaternius CC0)

Das Spiel verwendet voll animierte LowPoly-3D-Charaktere von **Quaternius** ([quaternius.com](https://quaternius.com)), lizenziert unter **CC0 1.0 Universal (Public Domain)**:

- **Hero-Spielfigur (`assets/models/characters/`):**
  - **Normal / Small Player:** `Alien.fbx` mit Bone-Rigging und flüssigen Animationen (`Alien_Idle`, `Alien_Run`, `Alien_Jump`, `Alien_Death`, `Alien_Punch`).
  - **Super-Pilz / Big Player:** `Alien_Helmet.fbx` (Astronautenhelm-Variante).
  - **Feuerblume & Super-Stern:** Dynamische PBR-Material-Emission (Feuer-Glühen und Rainbow-Starman-Farbrad).
- **Gegner-Suite (`assets/models/enemies/`):**
  - **Goomba-Pendant:** `Rat.fbx` mit Lauf- und Stomp-Tod-Animation (`Rat_Run`, `Rat_Death`).
  - **Koopa-Troopa-Pendant:** `Frog.fbx` mit Sprung-, Schlitter- und Rückzugsverhalten (`Frog_Jump`, `Frog_Death`).
  - **Bullet-Bill-Pendant:** `Wasp.fbx` mit animierten Flügelschlägen im horizontalen Flug (`Wasp_Flying`, `Wasp_Death`).
  - **Piranha-Pflanzen-Pendant:** `Snake_angry.fbx` schnellt zischend aus Röhren empor (`Snake_Attack`).

---

## 📄 Lizenz

Dieses Projekt ist unter der **[MIT-Lizenz](LICENSE)** lizenziert.

---

## 🔗 Verwandte Repositories

- **Babylon.js 2.5D Gegenstück:** [`RobinNunkesser/ts-platformer-babylonjs`](https://github.com/RobinNunkesser/ts-platformer-babylonjs)
- **Live-Demo (Web):** [https://robinnunkesser.github.io/ts-platformer-babylonjs/](https://robinnunkesser.github.io/ts-platformer-babylonjs/)
- **Vorlesung:** [Modul 10: Tile-basierte Welten & Platformer-Physik](https://robinnunkesser.github.io)
