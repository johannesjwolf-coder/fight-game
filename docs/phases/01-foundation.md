# Phase 1 — Godot-Grundgerüst

## Ziel und Änderungen

TypeScript-Gerüst durch Godot 4.5.2/GDScript ersetzt. Client-Szene mit eigener
statischer Arena, Figurenplatzhaltern, Statusanzeige und bedienbarem Raster.
Bootstrap trennt Darstellung und Headless-Server. Physikrate auf 60 Hz eingestellt;
noch keine Simulation implementiert. Web- und Linux-Server-Presets sowie CI vorhanden.
Vollständiger umgestellter Entwicklungsplan aus README verlinkt.

## Start und automatische Prüfung

```sh
godot --headless --path . --editor --import
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/smoke.gd -- --server
godot --path .
```

Smoke-Test prüft 60-Hz-Konfiguration, korrekten exklusiven Startpfad, Szenenladen,
Rasterumschaltung und Freigabe. CI exportiert zusätzlich Web und Linux und startet
die exportierte Serverdatei für drei Frames. Export Templates erforderlich.

## Manuelle Abnahme

- Client: Arena, zwei Figuren und drei Plattformen sichtbar; keine Bewegungsfunktion.
- Rasterbutton mit Maus und Enter/Leertaste bedienbar.
- Browserexport über HTTP: identische Darstellung, keine Konsolefehler.
- Serverpfad: keine Client-Szene, strukturiertes `server_boot`-Log, kein Port offen.

## Prüfstatus

Lokale Engine-/Export-/Browserausführung zunächst offen: Godot ist nicht im PATH;
Download der Engine durch DNS-Auflösung von release-assets.githubusercontent.com
fehlgeschlagen. CI und Tests sind eingerichtet, aber damit noch nicht als bestanden
nachgewiesen. Phase 2 beginnt erst nach bestandenem Gate.
