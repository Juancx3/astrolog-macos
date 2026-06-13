# AstrologMac

A native macOS front end for **Astrolog 8.00**. The app drives the existing
Astrolog CLI engine (in the repo root) as a subprocess and displays the charts
it renders — it does not reimplement the astrology/ephemeris calculations.

## Modules

- **`AstrologKit`** (this package) — pure-Swift core. Builds type-safe
  `astrolog` argument vectors (`AstrologCommand`) and runs the binary
  (`AstrologRunner`). UI-free, so it builds/tests on any Swift toolchain.
- **AstrologMac app** (added on the Mac) — the SwiftUI shell that depends on
  `AstrologKit`.

## Quick start

```sh
swift build
swift test
```

## Example

```swift
import AstrologKit

var gfx = GraphicsOutput(outputPath: "/tmp/chart.svg")
gfx.width = 900
gfx.sidebar = true

let cmd = AstrologCommand(
    chartType: .wheel,
    moment: .full(month: 6, day: 12, year: 2026,
                  time: 14.5, dst: 0, zone: 8, lon: 122.33, lat: 47.6),
    graphics: gfx)

try AstrologRunner.run(
    binary: "/path/to/astrolog",
    command: cmd,
    workingDirectory: URL(fileURLWithPath: "/path/to/astrolog/resources"))
// -> writes /tmp/chart.svg
```

See `../SWITCHES_CHEATSHEET.md` for the full switch reference and
`../HANDOFF.md` for the architecture and next steps.
