# Entwicklungsplan: Fight Game mit Godot

## Entscheidung und MVP

Der ursprüngliche TypeScript-/PixiJS-Plan wird auf Nutzerwunsch durch **Godot
4.5.2 Standard + typisiertes GDScript** ersetzt. Browser und Dedicated Linux
Server verwenden dieselben Gameplay-Module. Keine parallele TypeScript-Simulation,
kein React, Fastify oder npm im MVP. Bestehende Gameplay-Ziele bleiben erhalten.

MVP: Desktop-Browser, frei belegbare Tastatur, Training, lokales 1v1 an einer
Tastatur und private Online-1v1-Lobbys. Zwei eigene Kämpfer (Funke: leicht und
mobil; Amboss: schwer und starke Launcher), eine Arena, drei Stocks, acht Minuten.
Damage-Prozent, Knockback, Dodge, Recovery, Luftkampf und Combos. Gastzugang ohne
Account. Selbsthosting auf Linux mit Docker und Caddy.

Zeitablauf: Stocks, dann niedrigerer Schaden; danach Unentschieden. Gleichzeitige
letzte KOs ergeben ein Unentschieden. Keine fremden Namen, Assets oder Sounds.

## Stack und Architektur

- Godot 4.5.2 Standard mit GDScript, Compatibility-Renderer, WebGL 2 und
  Single-Thread-Webexport. Editor und Export Templates müssen dieselbe Version haben.
- Godot Control-Nodes für Menüs und Debug-UI, Node2D für Darstellung,
  AnimationPlayer/SpriteFrames für spätere Animationen.
- Eigene kleine kinematische Simulation statt Abhängigkeit von den Animationen
  oder der allgemeinen Engine-Physik. Godot-Physik ist nicht automatisch über
  Browser und Linux hinweg deterministisch.
- Gemeinsame reine GDScript-Daten und Funktionen, später typisierte Resources
  für Charaktere, Angriffe und Maps. Resources sind unveränderliche Definitionen;
  veränderlicher Matchzustand liegt in eigenen Zustandsobjekten.
- WebSocketPeer/WebSocketMultiplayerPeer als Transport; der Server entscheidet.
  Kein ENet/UDP für den Browser. Ein selbst definiertes versioniertes Protokoll
  verhindert Vertrauen in clientseitige Treffer oder Positionen.
- Headless-Godot auf Linux für Räume und Simulation. Caddy liefert Webdateien und
  WSS-Reverse-Proxy. Keine Datenbank im Echtzeitpfad; PostgreSQL erst nach dem MVP.
- GDScript-Tests per Headless-CLI; Browser-Smoke- und Mehrclienttests mit Playwright
  erst beim Web-/Netzwerk-Testausbau. Das spätere Testwerkzeug ist keine Spielruntime.

```text
Browser: Control UI + Input + gemeinsame Simulation + Node2D-Darstellung
                        | HTTPS / WSS
Caddy: Webdateien + Reverse Proxy
                        |
Dedicated Godot Server: Sitzungen + Räume + autoritative Simulation
                        |
später PostgreSQL: Accounts und Ergebnisse außerhalb des Ticks
```

Zielstruktur (Ordner entstehen mit ihrer Phase):

```text
scenes/          bootstrap, client, UI, arena
scripts/client/  input, presentation, animation, audio, network, debug
scripts/server/  sessions, lobbies, rooms, network, monitoring
scripts/shared/  state, simulation, physics, combat, protocol, replay
content/         characters, attacks, maps, rules
tests/           smoke, simulation, replay, network, browser, performance
docs/            DEVELOPMENT_PLAN.md, phases/
infra/           docker, caddy
```

Simulation importiert keine Szenen, Rendering-, Netzwerk- oder UI-Komponenten.
Der Bootstrap wählt den Client oder den Server über `dedicated_server` beziehungsweise
`--server`. Der Phase-1-Server ist nur ein Lebenszyklus-Gerüst ohne Netzwerkport.

## Schnittstellen und Daten

- `step(state, inputs, rules)` führt einen Tick aus und liefert Zustand/Ereignisse.
- InputSystem: Geräte zu InputFrames, Puffer, Rebinding und Fokusverlust.
- MovementSystem/CollisionSystem: kinematische Bewegung, Plattformen, Sprünge.
- CombatSystem: Startup, Active, Recovery, Hitstop, Hitstun, Cancels.
- KnockbackSystem/StockSystem: Launch, Blast Zones, Respawn, Ergebnis.
- SnapshotCodec/PredictionController: vollständige Zustände, Historie, Replay.
- PresentationSystem/TrainingController: Anzeige, Effekte und reproduzierbare Tests.
- MatchRoom: zwei Sitzplätze, Tick, Verbindungen und Matchlebenszyklus.

| Modell | Inhalt |
|---|---|
| CharacterDefinition | ID, Name, Gewicht, Beschleunigung, Geschwindigkeit, Sprungimpulse, Gravity, Falllimit, Dodge-Werte, Hurtboxes, Attack- und Animationsreferenzen |
| AttackDefinition | ID, Kategorie, Startup/Active/Recovery, Damage, Basis-Knockback, Scaling, Winkel, Hitstun/Hitstop, Hitbox-Zeitfenster, Bewegungsimpulse, Cancels |
| HitboxDefinition | Versatz, Größe, aktive Frames, Treffergruppe, Wiederholungssperre |
| MapDefinition | ID, feste und durchspringbare Plattformen, Spawns, Blast-Zone-Rechteck |
| MatchState | Tick, Phase, Timer, Fighterzustände, Damage/Stocks, Position/Geschwindigkeit, Ressourcen, Angriffsalter, Trefferregister |
| InputFrame | Sequenz, Ziel-Tick, Richtungen, gehaltene Aktionen, neue Tastendrücke |
| Snapshot | Tick, bestätigte Inputs, kompletter Matchzustand, Protokollversion, Content-Hash |

Alle Configs auf IDs, Referenzen, endliche Zahlen und gültige Zeitfenster prüfen.
Snapshots enthalten Inputbuffer, Cooldowns, Hitstop und getroffene Ziele.
Keine ausführbaren Objekte oder Resources aus untrusted Netzwerknachrichten laden.

## Simulation, Movement und Combat

60 feste Ticks/s auf Server und Client; Darstellung unabhängig davon. Gameplay-
Zeiten sind ganzzahlige Ticks, Position und Geschwindigkeit werden quantisiert.
Stabile Update-Reihenfolge, keine Echtzeituhr oder unkontrollierter Zufall im Kern.
Hash-/Replaytests vergleichen Webexport und Linux-Server. Aufholen ist begrenzt;
Überlast wird gemessen. AABB-Kollision mit Sweeps für hohe Geschwindigkeiten;
Einwegplattformen tragen nur beim Fallen von oben. Keine Körperblockade zwischen
Kämpfern. Down + Jump lässt durch Einwegplattformen fallen.

| Aktion | Spieler 1 | Spieler 2 |
|---|---|---|
| Richtungen | W/A/S/D | Pfeiltasten |
| Jump | F | K |
| Light | G | L |
| Heavy | H | O |
| Dodge/Dash | R | I |

Online nutzt jeder die Spieler-1-Belegung. Belegung wird lokal unter `user://`
gespeichert; Browser-Persistenz wird geprüft und Fehler werden angezeigt.
Inputbuffer sechs Ticks, Coyote Time vier Ticks. Beschleunigung, Bremsen,
Luftsteuerung, variable Sprunghöhe, ein Luftsprung, Fast Fall, Dash und Dodge.
Air Dodge und Recovery einmal pro Bodenkontakt. Explizite Unverwundbarkeitsfenster.
Kein Wall Jump, Ledge Grab oder Wall Cling im MVP.

Light neutral/seitlich/abwärts am Boden und in der Luft; Heavy entsprechend am
Boden. Up + Heavy in Luft = Recovery, Down + Heavy = Ground Pound, andere Heavy-
Luftinputs verwenden den zugehörigen Luftangriff. Mittlere Angriffe entstehen
durch Framewerte; keine dritte Angriffstaste. Geschwindigkeit wird direkt über
Move-Frames definiert, ohne versteckte globale Multiplikatoren.

Angriffe: Startup -> Active -> Recovery. Standard ein Treffer je Ziel/Treffergruppe;
Multihits benötigen explizite Fenster. Treffer pro Tick sammeln und gleichzeitig
anwenden, damit Spielerreihenfolge keine Vorteile erzeugt. Hitstop hält Betroffene
an, Inputs werden weiter gepuffert. Hitstun sperrt Aktionen. Cancels nur in
konfigurierten Fenstern; keine universelle Dodge-Unterbrechung.

True Combo: kein handlungsfähiges Fenster zwischen Treffern. String: Fluchtfenster
vorhanden. Training unterscheidet beide. Dummy kann zum frühesten Zeitpunkt Dodge
oder Sprung versuchen. Standardgravitation auch in Combos; Ausnahmen pro Move.
Directional Influence ändert den Launchwinkel um maximal zwölf Grad.

```text
D = Schaden nach dem Treffer
K = (BasisKnockback + Scaling * (D / 100)^1.25) * sqrt(100 / Gewicht)
LaunchVelocity = Richtung(Angriffswinkel + DI) * K
```

K in Welt-Einheiten/s, Referenzgewicht 100. Launch ersetzt die bisherige
Geschwindigkeit; Hitstun ist aus K und Move-Werten abgeleitet und begrenzt.
Tests: 0/20/50/100/150 Prozent und leichte/mittlere/schwere Gewichte.
Mehr Damage muss bei sonst gleichem Treffer stärker launchen.

Arena: Hauptplattform plus zwei Einwegplattformen. Zuerst Platzhalter, später
eigene Figuren und Animationen für Idle, Run, Jump, Fall, Dash, Dodge, Attack,
Hit, Knockback, Recovery und Death. Animationen folgen Gameplayframes und ändern
niemals dessen Timing. Effekte erhalten IDs, damit Replay keine Sounds dupliziert.

## Multiplayer

60-Hz-Server, 60 Inputframes/s in 30 Batches/s, 30 vollständige Snapshots/s,
120 Ticks Clienthistorie. Beide Kämpfer laufen auf einer gemeinsamen vorhergesagten
Timeline. Gegner hält kurzfristig die letzte Richtung; neue Angriffe werden nicht
erfunden. Serverstand übernehmen, unbestätigte Inputs erneut simulieren.
Visuelle Korrekturen glätten; Hitboxes verwenden ausschließlich den Simulationsstand.
Bei fehlender Historie vollständig resynchronisieren.

Keine verzögerte Gegnerdarstellung mit aktuellen lokalen Hitboxes mischen.
Interpolation nur zwischen Renderzuständen beziehungsweise später für Zuschauer.
MVP kompensiert Latenz durch Prediction und Reconciliation. Server schreibt
entschiedene Treffer nicht rückwirkend um. Verspätete Inputs in nächsten zulässigen
Tick einordnen und messen. Autoritativer Rollback nur als spätere, separat getestete
Erweiterung. Der frühe Netzwerkprototyp ist ein verbindliches Qualitätsgate.

Versionierte Nachrichten: Gastsession/Handshake, Lobby erstellen/beitreten,
Charakter/Ready, Inputs, Snapshot/Ereignisse, Ping/Pong, Ende/Rematch, Reconnect.
Sechs zufällige unterscheidbare Zeichen für Lobbycodes, Kollisionsprüfung.
Code ist kein Authentifizierungstoken. Zwei verbundene bereite Spieler für Start.
Volle Lobby, ungültiger Code und Versionskonflikt werden klar angezeigt.

Limits für Größe, Rate, Tickfenster, Sequenz und Warteschlangen; Origin prüfen;
Spieler aus Session ableiten, nicht aus Nachrichten übernehmen. Überlastete
Sendewarteschlangen begrenzen, alte ungesendete Snapshots ersetzen, dauerhaft
langsame Verbindungen trennen. Keine unbeschränkte WebSocket-Pufferung.

Nach sechs Ticks ohne Input neutralisieren. Disconnect-Figur bleibt treffbar.
Reconnect 15 Sekunden mit kurzlebigem Token und vollständigem Snapshot. Danach
Niederlage; beide getrennt = Abbruch. Serverneustart stellt Matches nicht wieder
her. Fokusverlust löst alle lokalen gehaltenen Tasten.

## 24 Phasen und Gates

Jede Phase dokumentiert Ziel, Änderungen, Startbefehl, Tests und Befund in
`docs/phases/`. Erst nach bestandenem Gate weiter. Kein gesamtes Spiel auf einmal.

| Phase | Ergebnis | Testgate |
|---|---|---|
| 1 | Godot-Projekt, Client-/Server-Bootstrap, Arena-Vorschau, CI, Exportpresets und Plan | Import, Startpfade, UI-Raster, Web-/Linux-Export und sichtbares Browserfenster |
| 2 | Reiner Simulationskern, feste Ticks, Inputaufzeichnung, Replay | Browser-/Linux-Hashes gleich; 30/60/144-Hz-Rendering ändert Ergebnis nicht |
| 3 | Ground Movement und Tastaturadapter | Velocity/State-Debug; Fokusverlust ohne hängende Tasten |
| 4 | Plattformen und kontinuierliche Kollision | Kanten, Unterseiten, hohe Geschwindigkeit, Collision-Overlay |
| 5 | Jump, Double Jump, Fast Fall, Luftsteuerung | Ressourcen, Coyote Time und Buffer framegenau |
| 6 | Dash, Ground-/Air Dodge | Unverwundbarkeit, Cooldowns, Luftressourcen |
| 7 | Training, Dummy, Reset, Pause, Frame-Schritt | Reproduzierbarer Ausgangszustand, korrekte Debugwerte |
| 8 | Hurt-/Hitboxes, Trefferregister | Grenzen, Spiegelung und doppelte Treffer |
| 9 | Erster datengetriebener Light-Move | Treffer ausschließlich in Active Frames |
| 10 | Damage, Knockback, Hitstun | Damage-/Gewichtsmatrix, Flugbahn und Velocity |
| 11 | Stocks, Blast Zones, Respawn, Recovery, Ground Pound | Gleichzeitige KOs, letzter Stock, Timer, Ressourcen |
| 12 | Hitstop, Cancels, DI, Combos/Strings | True Combo und escapebarer String gegen Flucht-Dummy |
| 13 | Lokales 1v1 | Ganzer Matchablauf, simultane Treffer, Tastatur-Ghosting |
| 14 | Dedicated Server, zwei Clients, Inputs/Snapshots | Einfacher Onlinekampf; manipulierte Positionen abweisen |
| 15 | Prediction, Historie, Reconciliation | 0/50/100/150 ms RTT, Jitter, Unterbrechung; keine Doppelhits/Divergenz |
| 16 | Zwei komplette Charaktere | Resource-Validierung; keine charakterspezifischen Kern-Sonderfälle |
| 17 | Finale Arena, Spawns, Kamera | Fenstergrößen, Distanz, Respawn |
| 18 | Training mit Frame Data, Damage-Regler, Combo-/Damage-Counter | Replaygleichheit, Knockbacktests, Ping offline als n/a |
| 19 | Eigene Animationen, Effekte, Sounds | Animationslänge ändert Combat nicht; kein doppeltes Audio durch Replay |
| 20 | Start, Play, Select, Match, Training, Settings | Tastaturnavigation, persistente Belegung, HUD |
| 21 | Gastlobby, Codes, Ready, Rematch | Ungültig/voll, simultaner Beitritt, Versionskonflikt |
| 22 | Reconnect, Timeout, Limits | Disconnect bei Attack/KO, abgelaufene Tokens, Nachrichtenflut |
| 23 | Performance und Balance | Zehnminutenmatches, Speichertrend, Eingabelatenz, Endloscombos |
| 24 | Docker, HTTPS/WSS, Monitoring, Betriebsanleitung | Externer Zwei-Spieler-Test, Neustart, fehlerhaftes Deployment, Rollback |

Gemeinsame Abnahme: Chromium/Firefox/WebKit plus manuelle reale Browserprüfung.
Replay-Fixtures für Frameränder, Doppelhits, simultane KOs. Bei 100 ms RTT und
moderatem Jitter spielbar ohne falsche Stocks/Doppelhits. Auf dokumentiertem
Referenzgerät Framezeit-P95 <= 16,7 ms. Server hält getestete Matchlast bei 60 Hz
mit Reserve; CPU/Speicher langfristig stabil. Keine nächste Phase bei bekannten
Damage-/Stock-/Synchronisationsfehlern. Tests melden tatsächliche Ausführung;
konfigurierte CI ist kein bereits bestandener Test.

## Deployment und Risiken

Docker Compose: Caddy + Headless-Godot. Webexport statisch über HTTPS, WSS zum
internen Game-Server-Port. Kein Node-Server nötig. Nur 80/443 öffentlich, Secrets
außerhalb Git. CI erstellt versionierte Exporte/Images. Healthcheck, vorheriges
Image für Rollback, geordneter Shutdown mit Aufnahme-Stopp und begrenztem Drain.
Logs ohne Tokens; Metriken zu Matches, Tickdauer, RTT, Korrekturen, Disconnects.
PostgreSQL später mit Backup-/Restoretests und Zugriff außerhalb des Ticks.
Domain, Serverleistung und vorhandenen Proxy vor tatsächlichem Deployment prüfen.

Risiken: Browser-Netzwerklatenz (frühes Gate), WebSocket-Stau (Limits), nicht
deterministische Physik (eigener Kern + Hashvergleich), unvollständige Snapshots
(alle Timer/Ressourcen), Tastatur-Ghosting (Rebinding/Diagnose), Endloscombos
(Flucht-Dummy), Performance (messen vor Pooling), Serverlast (Matchlimit),
Assetumfang (Platzhalter zuerst), Browserpersistenz und WebGL-Unterstützung
(explizite Browserprüfung). Keine automatische Zusage von 60 FPS ohne Messung.

Später: Accounts/Profile, öffentliches Matchmaking, PostgreSQL, weitere Maps,
Gamepads, 2v2/FFA, flexible Custom Lobbys, Zuschauer/Replays. Ranked, Leaderboards
und Friends erst nach stabiler Online-Abnahme. Touch, Waffenwechsel, Wall Jump,
Gefahren und bewegliche Plattformen außerhalb des MVP.

## Technische Quellen

- [Webexport und Grenzen](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_web.html)
- [Dedicated Server](https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_dedicated_servers.html)
- [Fixierte Engine-Version](https://godotengine.org/download/archive/4.5.2-stable/)

Weiterarbeit: „Implementiere Phase 2“, „Teste Phase 2“ usw. Der Wechsel der Engine
ersetzt den Stack, nicht die schrittweise Entwicklung oder die Testgates.
