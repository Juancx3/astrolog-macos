# Astrolog Switch Cheat Sheet

Companion reference for driving the `astrolog` CLI binary as a subprocess
(e.g. from a Swift/macOS front end). Verified against Astrolog 8.00 source.

**Invocation:** `astrolog [time/place] [chart-type] [graphics-out] [file-io]`

**Parse chain:** `FProcessCommandLine` -> `FProcessSwitches` (astrolog.cpp:1290)
-> `NProcessSwitchesX` (xscreen.cpp:1344) -> `Action()` -> `CastChart`
-> `FActionX` -> `DrawChartX`

**Toggle syntax:** `-x` toggle | `=x` force on | `_x` force off | `:x` neutral.
Trailing tokens after a switch are consumed as that switch's arguments.

---

## (1) Time / Place  — populates `ciCore`

| Switch                              | Args | Meaning                                   |
|-------------------------------------|------|-------------------------------------------|
| `-qb M D Y time dst zone lon lat`   | 8    | full moment + place (use for +/- stepping)|
| `-qa M D Y time`                    | 4    | date+time, place from defaults            |
| `-qd M D Y`                         | 3    | date only (noon)                          |
| `-qj <julianday>`                   | 1    | set by Julian day (easy stepping)         |
| `-qL <index>`                       | 1    | load chart #index from the list           |
| `-z <zone>`                         | 1    | time zone (hours west of UTC)             |
| `-z0 <dst>`                         | 1    | daylight offset                           |
| `-zl <lon> <lat>`                   | 2    | location                                  |
| `-n` / `-nd` / `-nm`                | 0    | now / now-midnight / now-month            |

Longitude/latitude: negative = east / south.

---

## (2) Chart Type  — pick one; sets a `us.f...` flag

| Switch | Chart                  | Switch              | Chart                  |
|--------|------------------------|---------------------|------------------------|
| `-v`   | position listing       | `-l`                | Gauquelin sectors      |
| `-w`   | wheel                  | `-j`                | influence/disposition  |
| `-g`   | aspect grid            | `-7`                | esoteric/ray           |
| `-a`   | aspect list            | `-L [step [dist]]`  | astrocartography       |
| `-m`   | midpoints              | `-K`                | calendar               |
| `-Z`   | horizon (`-Z0` prime vert, `-Zd` rising) | `-E...` | ephemeris table |
| `-S`   | orbit (space)          | `-8`                | moons                  |
| `-T` / `-V` / `-B` / `-d` | transits / progressions (take own dates) |  |  |

---

## (3) Graphics Output  — `-X...`; any `-X` also sets `us.fGraphics`

| Switch          | Effect                          | Switch        | Effect                |
|-----------------|---------------------------------|---------------|-----------------------|
| `-XV`           | SVG (best for a Mac UI)          | `-Xw x [y]`   | image pixel size      |
| `-Xbp`          | PNG (raster)                     | `-Xs n`       | glyph scale 100-400   |
| `-Xbw`          | Windows 24-bit `.bmp`            | `-XS n`       | text scale            |
| `-Xp` / `-Xp0`  | PostScript (`-Xp0` standalone)   | `-Xm`         | color/mono toggle     |
| `-XM`           | metafile (WMF)                   | `-Xr`         | reverse -> white bg   |
| `-X3`           | wireframe                        | `-Xt` / `-Xu` | info text / border    |
| `-Xo <file>`    | output filename (required headless) | `-Xl` / `-XA` | labels / aspect glyphs |
| `-Xv` / `-Xv0`  | sidebar                          | `-Xx` / `-Xx0`| thick lines / antialias |
| `-XX [deg]`     | rotation / sphere                | `-XJ` / `-X8` | Indian / moon wheel   |

---

## (4) File I/O + List

| Switch              | Effect                       | Switch            | Effect                 |
|---------------------|------------------------------|-------------------|------------------------|
| `-i <file>`         | load chart -> `ciCore`       | `-o <file>`       | save chart (`.as`)     |
| `-i1 ... -i9 <file>`| load into slot n             | `-os <file>` / `->` | redirect text output |
| `-iD <file>`        | load as default              | `-il <file>`      | load AND append to list|
| `-it <file>`        | load as transit              | `-id <dir>`       | set chart directory    |
| `-5e[2/3/4]`        | render all list charts       | `-50`             | clear list             |
| `-5d` / `-5n` / `-5l` | sort by date / name / location | `-5f <fld> <val>` | filter list         |

Gating: `-0i` forbids reading, `-0o` forbids writing, `-0X` forbids graphics.

---

## Ready-to-use templates

```sh
# SVG wheel (recommended) -- change only the -qb numbers per +/- press
astrolog -w -qb 6 12 2026 14.30 0 8 122.33 47.6 -XV -Xw 900 -Xo chart.svg

# PNG wheel with sidebar, labels, color
astrolog -w -qb 6 12 2026 14.30 0 8 122.33 47.6 -Xbp -Xw 1200 -Xv -Xl =Xm -Xo chart.png

# Open a saved chart and render it
astrolog -w -i mychart.as -XV -Xo chart.svg

# Synastry: main chart + second chart
astrolog -w -qb 6 12 2026 14.30 0 8 122.33 47.6 -r1 -i1 partner.as -XV -Xo synastry.svg
```

## Build note

Compile the plain CLI binary (`WIN` & `X11` undefined; `GRAPH` + `SVG`/`PS`
defined). It parses switches, casts, writes via `-Xo`, and exits -- exactly the
lifecycle a subprocess-driven UI needs. Args are consumed left-to-right; order
matters only where a switch eats following numbers (`-qb`, `-Xw`, `-L`, `-i1`).
