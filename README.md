# Fight Game

Ein eigener 2D-Platform-Fighter mit **Godot 4.5.2 Standard und GDScript**.
Browser-Client und Dedicated Linux Server stammen aus demselben Projekt.

## Stand

Phase 1: Projektgerüst, statische Arena, umschaltbares Debug-Raster, getrennte
Client-/Server-Startpfade, Smoke-Tests und Web-/Linux-Exportkonfiguration.
Noch keine Bewegung, Kämpfe, Netzwerkverbindung oder veröffentlichte Webseite.

Der TypeScript/PixiJS-Ansatz wurde auf Wunsch durch Godot ersetzt.
Der vollständige Fahrplan steht in [docs/DEVELOPMENT_PLAN.md](docs/DEVELOPMENT_PLAN.md).
Prüfstatus: [Phase 1](docs/phases/01-foundation.md).

## Starten

1. [Godot 4.5.2 Standard](https://godotengine.org/download/archive/4.5.2-stable/) installieren (kein .NET/C#).
2. `project.godot` im Projektmanager importieren.
3. Mit **F6** die geöffnete Client-Szene oder mit **F5** das Projekt starten.
4. Das Raster per Button oder mit Enter/Leertaste umschalten.

CLI-Beispiele verwenden `godot`; unter Windows den vollständigen Pfad zur
Godot-Konsolen-EXE einsetzen, falls sie nicht im PATH steht.

```sh
godot --editor --path .
godot --headless --path . --editor --import
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/smoke.gd -- --server
godot --headless --path . -- --server
```

Der Serverstart gibt derzeit nur einen strukturierten Startstatus aus und bleibt
aktiv. Er öffnet noch keinen Port; Beenden mit Ctrl+C.

## Export

Passende **4.5.2 Export Templates** im Godot-Editor installieren.
Die Ordner `build/web` und `build/server` zuerst anlegen.

```sh
godot --headless --path . --export-release Web
godot --headless --path . --export-release "Linux Server"
```

Den Webexport über HTTP/HTTPS ausliefern, nicht per Doppelklick auf `index.html`.
Beispiel, falls Python installiert ist:

```sh
python -m http.server 8080 --directory build/web --bind 127.0.0.1
```

Danach `http://localhost:8080` öffnen. Der Single-Thread-Webexport verwendet den
Compatibility-Renderer und benötigt WebGL 2. Später liefert Caddy die Webdateien
aus und leitet WSS zum Godot-Server weiter. Docker-Deployment folgt in Phase 24.

## Struktur

- `scenes/`: Bootstrap und Client-Szene
- `scripts/client/`: Darstellung; später Eingabe, UI, Audio, Prediction
- `scripts/server/`: Serverlebenszyklus; später Räume, Sitzungen und Netzwerk
- `tests/`: ausführbare GDScript-Smoke-Tests
- `docs/`: Architektur, Phasen, Testnachweise
- `export_presets.cfg`: Browser und Dedicated Linux Server

Ab Phase 2 kommt `scripts/shared/` für die renderunabhängige Simulation hinzu.
Keine npm-/Node-Abhängigkeiten erforderlich. CI importiert, testet und exportiert
beide Zielplattformen; Exportartefakte stehen beim erfolgreichen Workflow bereit.

