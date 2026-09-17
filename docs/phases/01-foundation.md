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

Geprüft am 17.09.2026 mit Godot 4.5.2:

- Windows: Headless-Projektimport erfolgreich, keine Skriptfehler.
- Windows: Client- und Server-Smoke-Test bestanden.
- Windows: Web- und Linux-Serverexport erfolgreich.
- Chromium: Webexport über lokalen HTTP-Server geladen; ein Canvas, keine
  JavaScript-/Konsolenfehler. Screenshot visuell geprüft: Arena, Texte, zwei
  Figuren, drei Plattformen und Rasterbutton sichtbar.
- GitHub Actions auf Ubuntu: Import, beide Smoke-Tests, beide Exporte und Start
  der exportierten Linux-Serverdatei bestanden:
  [CI-Lauf](https://github.com/johannesjwolf-coder/fight-game/actions/runs/35199012323).

Firefox/WebKit und echte Tastatur-/Mausinteraktion sind noch nicht manuell
abgenommen; die Rasterfunktion selbst wurde im automatischen Szenentest geprüft.
Kein öffentlicher Server deployt, keine Multiplayer-/Performance-Zusage.
