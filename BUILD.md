# Build Instructions

Two independent build products. Both are built **on macOS**.

---

## 1. The `astrolog` CLI binary (C/C++ engine)

The Swift app shells out to this. Build the headless CLI variant — **no X11,
no Windows GUI** — with graphics file output (SVG/PostScript/bitmap) enabled.

### One-time: configure `astrolog.h`

Near the top of `astrolog.h`, the platform `#define`s select the build. For a
headless macOS CLI you want **all of these commented out**:

```c
//#define PC
//#define X11      <- comment out (no X11 dependency / no live window)
//#define WIN
//#define WCLI
//#define WSETUP
```

and these **left enabled** (they already are by default):

```c
#define GRAPH     // graphics / bitmap output
#define SWISS     // Swiss Ephemeris (most accurate)
#define PS        // PostScript output
#define SVG       // SVG output  <- the format the app uses
#define ATLAS     // city / timezone lookup
```

> The shipped `astrolog.h` has `#define X11` enabled. Comment it out for the
> headless build, otherwise the compile/link will require X11 (`-lX11`).

### Compile

From the repo root (where the `.cpp` files live):

```sh
clang++ -O2 -std=c++17 -Wno-write-strings -Wno-narrowing -Wno-comment \
    *.cpp -o astrolog -lm
```

(Equivalent to the provided `Makefile` minus `-lX11`. `-ldl` from the Makefile
is GNU/Linux-specific and not needed on macOS.)

### Smoke test

```sh
./astrolog -w -qb 6 12 2026 14.5 0 8 122.33 47.6 -XV -Xw 900 -Xo /tmp/chart.svg
open /tmp/chart.svg
```

The CLI resolves `astrolog.as`, the `ephem/` files, `atlas.as`, `timezone.as`,
and the fonts relative to its working directory (and the `ASTROLOG` env var /
`DEFAULT_DIR`). Run it from a directory that contains those, or point the
Swift `AstrologRunner.workingDirectory` there.

---

## 2. The Swift package (`AstrologKit`)

Pure-Swift core (argv builder + subprocess runner). No Xcode required.

```sh
cd AstrologMac
swift build          # compile the library
swift test           # run the argv-assembly unit tests
```

This is the fast toolchain sanity check — if `swift test` is green, the Swift
side is wired correctly.

### The SwiftUI app shell (not yet created)

Pick one on the Mac:

- **Xcode app target**: New macOS App, add this package as a local dependency
  (`File ▸ Add Package Dependencies ▸ Add Local…` -> select `AstrologMac/`),
  `import AstrologKit`.
- **XcodeGen**: add a `project.yml` describing the `.app` target + the local
  package dependency, then `xcodegen generate`. Keeps the project file out of
  git (regenerated from the spec).

See `HANDOFF.md` -> "Next steps" for the view-model/UI plan.
