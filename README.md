# Astrolog — macOS Front End

A project to build a native **macOS (SwiftUI)** front end for **Astrolog 8.00**,
a long-standing astrology/astronomy charting engine written in C/C++. The app
drives the existing Astrolog command-line engine as a subprocess and displays
the charts it renders — it **does not reimplement** the calculations.

---

## Background / origin

This repository began as an **analysis of the Astrolog 8.00 source code** —
its architecture, structure, and components — with the goal of putting a modern
macOS interface on top of the proven calculation engine without rewriting it.


That analysis (engine → graphics rendering layer → Windows GUI) led to a
concrete plan: rather than port Astrolog's rendering to macOS/Quartz or rebuild
its GUI, **replicate a thin UI on macOS that connects to Astrolog's existing
command-line, switch-driven interface.** Astrolog already does everything via
command-line switches, so the engine can be driven as-is.

## What is Astrolog?

- Free astrology/astronomy software, **Copyright © 1991–2026 Walter D. Pullen**
  (<http://www.astrolog.org>), licensed under **GNU GPL v2**.
- ~106,000 lines of C/C++.
- Calculates positions of planets, asteroids, fixed stars, and abstract
  astrological points for any date/time/location, and renders them as text
  tables or graphical charts (wheels, grids, astrocartography maps, globes…).
- **Three swappable calculation backends**, selected at runtime:
  **Swiss Ephemeris** (Astrodienst AG — most accurate), **Placalc** (older
  Astrodienst routines), and the original **Matrix** formulas.
- Ships as a Unix/X11 tool, a Windows GUI, or a headless chart/image generator —
  all driven by command-line **switches**.
- Architecturally: a UI-free calculation/ephemeris **engine** wrapped by thin,
  **switch-driven** presentation layers; one drawing API targets six output
  formats (bitmap, PostScript, WMF, SVG, wireframe, live screen).

## Approach (key decisions)

| Decision | Rationale |
|----------|-----------|
| **Reuse the engine, don't port it** | The engine has no UI/platform dependency; all behavior is reachable via switches. |
| **Drive the `astrolog` CLI as a subprocess** | Swift builds a switch string, runs the binary, displays the output file. No C changes needed. |
| **SVG output** (`-XV`) | Vector, crisp at any zoom, renders natively in a Mac view; PNG (`-Xbp`) is the raster alternative. |
| **Manual time-stepping, not animation** | The target interaction is viewing a chart and pressing `+`/`-` to step through time — a discrete recompute-and-redraw at human cadence, which the subprocess model handles well. |

> An **in-process C bridge** (compile Astrolog as a library; call
> `FProcessCommandLine` / `CastChart` and present its 24-bit bitmap buffer via a
> `CGImage`) is a documented future option, needed only for smooth real-time
> animation, live "Now" mode, or interactive globe rotation.

## Repository layout

```
/ (repo root)             Astrolog 8.00 C/C++ engine (vendored, GPL v2) + assets
├── README.md               this file
├── HANDOFF.md              architecture findings, decisions, next steps
├── BUILD.md                build the headless CLI engine AND the Swift package
├── SWITCHES_CHEATSHEET.md  verified four-group switch reference + templates
├── ephem/  font/  *.as  earth.bmp    runtime resources the CLI needs
└── AstrologMac/            the macOS front end
    ├── Package.swift                       SwiftPM manifest (library + tests)
    ├── Sources/AstrologKit/                type-safe argv builder + runner
    └── Tests/AstrologKitTests/             unit tests for argv assembly
```

## Status

- [x] Architecture analysis (engine, graphics layer, Windows GUI)
- [x] Approach decided (subprocess model, SVG output)
- [x] Verified switch reference (`SWITCHES_CHEATSHEET.md`)
- [x] `AstrologKit` — argv builder (`AstrologCommand`) + subprocess runner
      (`AstrologRunner`) + unit tests
- [ ] Build the headless `astrolog` CLI binary on macOS (`BUILD.md`)
- [ ] SwiftUI app shell + view model with `+`/`-` time-stepping

See **`HANDOFF.md`** for the full context and next steps (written so a fresh
session on the Mac can continue the work).

## Building

See **`BUILD.md`**. In short:

```sh
# 1. The CLI engine (run on macOS; comment out #define X11 in astrolog.h first)
clang++ -O2 -std=c++17 -Wno-write-strings -Wno-narrowing -Wno-comment *.cpp -o astrolog -lm

# 2. The Swift core
cd AstrologMac && swift build && swift test
```

## License

The Astrolog engine is **GPL v2** (Walter D. Pullen). The bundled **Swiss
Ephemeris** and **Placalc** routines are under their own Astrodienst AG licenses
(see headers and `license.htm`). These notices must be preserved. The license
for the new macOS front-end code is to be determined by the author; note the app
runs the engine as a **separate process** rather than linking it.
