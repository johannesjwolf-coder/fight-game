# Phase 2 — Simulation, Aufzeichnung und Replay

## Ergebnis

Ein gemeinsamer GDScript-Kern ohne Node-, UI-, Netzwerk- oder Uhrabhängigkeit.
`step(state, inputs)` validiert zwei tickgenaue InputFrames, kopiert den Zustand,
integriert ganzzahlige Geschwindigkeit, aktualisiert Timer/Inputs und erzeugt
Pressed-/Released-Ereignisse. Noch kein Player Controller oder Combat.

Positionen: 1000 Subunits pro Welt-Einheit; Geschwindigkeit: Subunits pro Tick.
Initial zwei Figuren mit Position, Geschwindigkeit und Inputmasken. Snapshotkopien
sind unabhängig. SHA-256 über feste Array-Reihenfolge und ausschließlich Integerwerte.
Keine Annahme, dass Godots allgemeine Physik deterministisch sei.

Clock: 60 Hz, ganzzahliger Mikrosekunden-Akkumulator, maximal acht Nachholschritte,
expliziter Zähler für verworfene Ticks. Bei langen Unterbrechungen kein unendliches
Aufholen. Die Darstellung pollt Debugwerte mit 10 Hz. Die Live-Uhr rundet Render-
Delta auf Mikrosekunden; Replayzustände hängen ausschließlich von Tickinputs ab.

Replayformat v1 mit Regelkennung `foundation-v1`, vollständigem Anfangszustand und
Inputpaaren. Prüfung von Größe (1 MiB), maximal 3600 Frames, Integerwerten, Masken,
Version und aufeinanderfolgenden Ticks. Aufzeichnung kopiert Inputs; Wiederholung
liefert jeden Zustands-Hash und Ereignisse. Aufnahme in dieser Phase im Speicher,
JSON-Codec für spätere Speicherung; kein Dateiimport-Dialog.

## Bedienung

Browser neu laden. Pause/Weiter, +1 Tick, Reset, Replay prüfen und 30/60/144-Hz-Test
im Debugpanel. Reset startet eine neue Aufnahme und behält den Pausenzustand.
Nach 3600 Ticks pausiert die Aufnahme automatisch. Figuren bleiben statisch;
Tastatur-Movement ist ausdrücklich Phase 3.

## Prüfungen

```sh
godot --headless --path . --script tests/simulation.gd
godot --headless --path . --script tests/smoke.gd
godot --headless --path . --script tests/smoke.gd -- --server
godot --headless --path . -- --verify-replay
```

Automatisch: Zustandsisolation, Tick/Timer, Inputkanten, falsche Masken/Ticks,
Integerintegration, Replay-JSON-Roundtrip, alle 121 Zustandshashes einer 120-Tick-
Fixture, Ereignisgleichheit, Fortsetzung ab Snapshot-Tick 60, kaputte JSON-Daten,
gebrochene Reihenfolge, Bruchzahlen, Aufnahmegrenze, Inputkopien, Catch-up-Grenze
und 30/60/144-Hz-Zeitpartitionierung.

Fixture-Trace: `62b8be83a780f2c4c0db6d6a30f4096e1ec148a90790787b67dac87bd9e8b35e`.

Lokaler Windows-Simulationstest bestanden. Web-/Linux-Exports und Browservergleich
werden vor Abschluss geprüft; CI führt den Vergleich mit dem exportierten
Linux-Server und drei Browser-Engines aus. Das prüft den aktuellen Integerkern,
nicht die noch nicht implementierten Physik-/Combatsysteme.
