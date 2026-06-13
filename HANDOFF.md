# Project Handoff — Astrolog macOS Front End

This document carries the full context of the design conversation so a fresh
Claude Code session **on the Mac** (VSCode or Xcode) can continue without
re-deriving anything. Read this first, then `BUILD.md`, then
`SWITCHES_CHEATSHEET.md`.

---

## Goal

Build a native macOS (SwiftUI) front end for **Astrolog 8.00** — a mature
astrology/astronomy charting engine written in C/C++ (this repo) — **without
rewriting the engine.** The Swift app drives Astrolog and displays the charts
it produces.

## The architecture decision (and why)

Astrolog cleanly separates a **calculation/ephemeris engine** (no UI, no
platform deps) from thin, **switch-driven** presentation layers. Everything the
existing Windows GUI and X11 build do is reachable from the command line via
switches. So the plan is:

- **Do NOT port the rendering engine to Quartz** (possible but unnecessary).
- **Drive the existing `astrolog` CLI as a subprocess** from Swift. The Swift
  side assembles a switch string, runs the binary, and displays the output
  file (SVG recommended; PNG alternative).

### Why subprocess is enough for this project

The user's interaction model is **manual time-stepping**: view a chart, press
`+` / `-` to move forward/backward in time. That is a discrete
recompute-and-redraw per keypress at human cadence — NOT real-time animation.
Subprocess cost (process spawn + ephemeris load, tens to low-hundreds of ms) is
imperceptible at keypress cadence.

The subprocess model is explicitly **not** suitable for:
- smooth real-time playback / animation (10–30 fps),
- the live "Now" mode (continuous clock),
- interactive globe drag/rotation.

If those are ever needed, graduate to an **in-process C bridge** (compile
Astrolog as a library, call `FProcessCommandLine` / `CastChart` /
render-to-bitmap directly, presenting the 24-bit RGB `Bitmap` buffer via a
`CGImage`). That path is documented in the conversation but NOT built yet.

### Engine internals worth knowing (verified against source)

- Parse chain: `FProcessCommandLine` -> `FProcessSwitches`
  (`astrolog.cpp:1290`) -> `NProcessSwitchesX` (`xscreen.cpp:1344`) ->
  `Action()` -> `CastChart` -> `FActionX` -> `DrawChartX`.
- All state lives in **global structs** (`us`, `gs`, `gi`, `ci`, `cp0`). This
  is fine for a single-window, single-threaded driver but means **no
  concurrency** — keep any in-process engine calls on one serial queue.
- The graphics engine renders the SAME drawing primitives to six targets
  (bitmap / PostScript / WMF / SVG / wireframe / live screen) by branching on
  `gi.fFile` + `gs.ft`, guarded by `#ifdef`. The in-memory 24-bit bitmap
  (`ftBmp`) path is pure C with no platform graphics calls — the natural bridge
  if we ever go in-process.

---

## Repo layout

```
/ (root)            Astrolog 8.00 C/C++ source (vendored, GPL v2) + assets
  HANDOFF.md          <- you are here
  BUILD.md            how to build the CLI binary AND the Swift package
  SWITCHES_CHEATSHEET.md   the four switch groups, verified, with templates
  ephem/  font/  *.as  earth.bmp   runtime resources the CLI needs
  AstrologMac/        the Swift work
    Package.swift       SwiftPM manifest (library + tests)
    Sources/AstrologKit/AstrologCommand.swift
                        type-safe argv builder + subprocess runner (DONE)
    Tests/AstrologKitTests/AstrologCommandTests.swift
                        unit tests for argv assembly (DONE; run `swift test`)
    README.md
```

`AstrologKit` is pure Swift (Foundation only) — no SwiftUI — so it builds and
tests on any Swift toolchain. The SwiftUI `.app` shell is NOT created yet
(deliberately deferred to the Mac).

---

## What's done

- [x] Architecture analysis of the engine, graphics layer, and Windows GUI.
- [x] Decision: subprocess model, SVG output.
- [x] Full switch reference (`SWITCHES_CHEATSHEET.md`).
- [x] `AstrologKit`: `ChartMoment` / `ChartType` / `GraphicsOutput` /
      `ChartInput` / `AstrologCommand` (argv builder) + `AstrologRunner`
      (subprocess wrapper) + unit tests.

## Next steps (do these on the Mac)

1. **Build the CLI binary** per `BUILD.md` (`clang++`, no X11/WIN). Confirm it
   runs: `./astrolog -w -qb 6 12 2026 14.5 0 8 122.33 47.6 -XV -Xo /tmp/c.svg`.
2. **Verify the package**: `cd AstrologMac && swift test` (toolchain sanity).
3. **Decide app shell**: Xcode app target, or XcodeGen `project.yml`. (Avoid
   hand-authoring `.xcodeproj`.)
4. **Build the SwiftUI layer** (NOT yet written):
   - An `ObservableObject` view model holding the current `ChartMoment`
     (recommend storing a Julian day for easy +/- stepping) and render options.
   - `stepForward()` / `stepBackward()` that adjust the moment, re-run
     `AstrologRunner`, and publish the resulting SVG/image. Debounce so
     key-repeat coalesces to the latest target.
   - A view that renders the SVG (WKWebView or an SVG renderer) or PNG
     (`NSImage`), plus a chart-info entry form and a chart-type picker.
   - Resolve the binary path + working directory (where `astrolog.as`,
     `ephem/`, `atlas.as`, fonts live). Easiest: bundle these resources in the
     app and point `AstrologRunner.workingDirectory` at them.

## Open questions for the user (carry forward)

- Where should runtime resources ship — bundled inside the `.app`, or a
  user-chosen folder? (Affects `workingDirectory`.)
- SVG rendering approach: WKWebView (simplest, full fidelity) vs. a native SVG
  library (lighter, more control)?
- Distribution: signed/notarized `.app`, or local/dev only?

---

## Conventions

- Keep `AstrologKit` UI-free and cross-platform so it stays unit-testable.
- Funnel ALL engine invocations through one place (a serial queue / actor) —
  cheap insurance even in the subprocess model, mandatory if we ever go
  in-process.
- The CLI is invoked from a **working directory** containing its resource
  files; don't rely on absolute `DEFAULT_DIR` paths baked into `astrolog.h`.
