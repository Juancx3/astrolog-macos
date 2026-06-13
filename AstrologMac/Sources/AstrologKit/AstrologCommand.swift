//
//  AstrologCommand.swift
//  AstrologKit
//
//  Type-safe builder for `astrolog` CLI argument arrays, for driving the
//  Astrolog 8.00 command-line binary as a subprocess from macOS/Swift.
//
//  Each nested type maps to one switch group in ../../../SWITCHES_CHEATSHEET.md:
//    ChartMoment    -> (1) time / place   (-qb / -qj / -qL)
//    ChartType      -> (2) chart type     (-w, -g, -v, ...)
//    GraphicsOutput -> (3) graphics out   (-XV, -Xbp, -Xw, -Xo, ...)
//    ChartInput     -> (4) file I/O       (-i, -i1, -iD, -it, ...)
//
//  Build an arg array with `.arguments()`, then hand it to `AstrologRunner`.
//

import Foundation

// MARK: - (1) Time / Place

/// The moment + place a chart is cast for. Maps to the `-q` switch family.
public enum ChartMoment {

    /// `-qb M D Y time dst zone lon lat` — fully specifies moment and place.
    /// `time` is decimal hours (14.5 == 14:30). `lon`/`lat`: negative = E / S.
    case full(month: Int, day: Int, year: Int,
              time: Double, dst: Double, zone: Double,
              lon: Double, lat: Double)

    /// `-qa M D Y time` — date+time; DST/zone/place taken from defaults.
    case dateTime(month: Int, day: Int, year: Int, time: Double)

    /// `-qd M D Y` — date only (cast for noon).
    case date(month: Int, day: Int, year: Int)

    /// `-qj <julianDay>` — set directly by Julian day. Ideal for +/- stepping:
    /// keep one Double and add/subtract a step each keypress.
    case julian(Double)

    /// `-qL <index>` — load entry `index` from the in-memory chart list.
    case listIndex(Int)

    public var arguments: [String] {
        switch self {
        case let .full(m, d, y, t, dst, zone, lon, lat):
            return ["-qb", "\(m)", "\(d)", "\(y)",
                    Self.fmt(t), Self.fmt(dst), Self.fmt(zone),
                    Self.fmt(lon), Self.fmt(lat)]
        case let .dateTime(m, d, y, t):
            return ["-qa", "\(m)", "\(d)", "\(y)", Self.fmt(t)]
        case let .date(m, d, y):
            return ["-qd", "\(m)", "\(d)", "\(y)"]
        case let .julian(jd):
            return ["-qj", Self.fmt(jd)]
        case let .listIndex(i):
            return ["-qL", "\(i)"]
        }
    }

    /// Trim trailing zeros so 14.5 -> "14.5" and 8.0 -> "8".
    static func fmt(_ v: Double) -> String {
        if v == v.rounded() { return String(Int(v)) }
        return String(format: "%g", v)
    }
}

// MARK: - (2) Chart Type

/// The kind of chart to draw. Exactly one applies per render.
public enum ChartType: String {
    case listing          = "-v"
    case wheel            = "-w"
    case grid             = "-g"
    case aspectList       = "-a"
    case midpoints        = "-m"
    case horizon          = "-Z"
    case orbit            = "-S"
    case sectors          = "-l"
    case influence        = "-j"
    case esoteric         = "-7"
    case astrocartography = "-L"
    case calendar         = "-K"
    case moons            = "-8"

    public var arguments: [String] { [rawValue] }
}

// MARK: - (3) Graphics Output

/// Output format. SVG is recommended for a Mac UI (vector, crisp at any zoom,
/// easy to render in an NSImage / WKWebView). PNG is the raster alternative.
public enum GraphicsFormat {
    case svg            // -XV
    case png            // -Xbp
    case bmp            // -Xbw  (Windows 24-bit)
    case postScript     // -Xp
    case metafile       // -XM
    case wireframe      // -X3

    public var formatFlag: String {
        switch self {
        case .svg:        return "-XV"
        case .png:        return "-Xbp"
        case .bmp:        return "-Xbw"
        case .postScript: return "-Xp"
        case .metafile:   return "-XM"
        case .wireframe:  return "-X3"
        }
    }

    /// Conventional file extension for this format.
    public var fileExtension: String {
        switch self {
        case .svg:        return "svg"
        case .png:        return "png"
        case .bmp:        return "bmp"
        case .postScript: return "ps"
        case .metafile:   return "wmf"
        case .wireframe:  return "dw"
        }
    }
}

/// A graphics render: format, output path, size, and common display options.
public struct GraphicsOutput {
    public var format: GraphicsFormat = .svg
    public var outputPath: String              // -Xo <file>  (required headless)
    public var width: Int? = 900               // -Xw x [y]
    public var height: Int? = nil
    public var glyphScale: Int? = nil          // -Xs n   (100...400)
    public var textScale: Int? = nil           // -XS n
    public var color: Bool = true              // =Xm / _Xm
    public var reverseBackground: Bool = false // -Xr  (white bg)
    public var sidebar: Bool = false           // -Xv
    public var labelObjects: Bool = false      // -Xl
    public var aspectGlyphs: Bool = false      // -XA
    public var infoText: Bool = false          // -Xt
    public var border: Bool = false            // -Xu
    public var thickLines: Bool = false        // -Xx
    public var antialias: Bool = false         // -Xx0

    public init(outputPath: String) {
        self.outputPath = outputPath
    }

    public var arguments: [String] {
        var a: [String] = [format.formatFlag]
        if let w = width {
            a += ["-Xw", "\(w)"]
            if let h = height { a.append("\(h)") }
        }
        if let s = glyphScale { a += ["-Xs", "\(s)"] }
        if let s = textScale  { a += ["-XS", "\(s)"] }
        // -Xm toggles color; force the desired state explicitly so a fresh
        // process (which starts from astrolog.as defaults) is deterministic.
        a.append(color ? "=Xm" : "_Xm")
        if reverseBackground { a.append("-Xr") }
        if sidebar           { a.append("-Xv") }
        if labelObjects      { a.append("-Xl") }
        if aspectGlyphs      { a.append("-XA") }
        if infoText          { a.append("-Xt") }
        if border            { a.append("-Xu") }
        if thickLines        { a.append("-Xx") }
        if antialias         { a.append("-Xx0") }
        a += ["-Xo", outputPath]
        return a
    }
}

// MARK: - (4) File Input

/// Load a chart from a saved `.as` file into a particular slot.
public enum ChartInput {
    case main(path: String)            // -i  <file>
    case slot(Int, path: String)       // -i1 ... -i9 <file>
    case asDefault(path: String)       // -iD <file>
    case asTransit(path: String)       // -it <file>
    case appendToList(path: String)    // -il <file>

    public var arguments: [String] {
        switch self {
        case let .main(p):         return ["-i", p]
        case let .slot(n, p):      return ["-i\(n)", p]
        case let .asDefault(p):    return ["-iD", p]
        case let .asTransit(p):    return ["-it", p]
        case let .appendToList(p): return ["-il", p]
        }
    }
}

// MARK: - Command assembler

/// Assembles a full `astrolog` argument vector from the four switch groups.
///
/// Supply either `moment` (inline time/place, e.g. for +/- stepping) or
/// `input` (load from file) — or both, e.g. an inline natal chart plus a
/// second chart loaded into a slot for synastry.
public struct AstrologCommand {
    public var chartType: ChartType = .wheel
    public var moment: ChartMoment?
    public var input: ChartInput?
    public var graphics: GraphicsOutput?
    /// Any extra raw switches not modeled above (e.g. "-r1", "-c", "-b").
    public var extraFlags: [String] = []

    public init(chartType: ChartType = .wheel,
                moment: ChartMoment? = nil,
                input: ChartInput? = nil,
                graphics: GraphicsOutput? = nil,
                extraFlags: [String] = []) {
        self.chartType = chartType
        self.moment = moment
        self.input = input
        self.graphics = graphics
        self.extraFlags = extraFlags
    }

    public func arguments() -> [String] {
        var argv: [String] = []
        argv += chartType.arguments
        if let m = moment   { argv += m.arguments }
        if let i = input    { argv += i.arguments }
        argv += extraFlags
        if let g = graphics { argv += g.arguments }   // graphics last
        return argv
    }
}

// MARK: - Runner

/// Runs the `astrolog` binary with the given command and returns its stdout.
public enum AstrologRunner {

    public enum RunError: Error {
        case nonZeroExit(Int32, stderr: String)
    }

    /// - Parameters:
    ///   - binary: absolute path to the compiled CLI `astrolog` executable.
    ///   - command: the assembled command.
    ///   - workingDirectory: dir the process runs in (where it finds
    ///     astrolog.as, the ephemeris files, atlas.as, fonts, etc.).
    /// - Returns: stdout text (useful for text charts; empty for `-Xo` renders).
    @discardableResult
    public static func run(binary: String,
                           command: AstrologCommand,
                           workingDirectory: URL) throws -> String {
        let proc = Process()
        proc.executableURL = URL(fileURLWithPath: binary)
        proc.arguments = command.arguments()
        proc.currentDirectoryURL = workingDirectory

        let out = Pipe(), err = Pipe()
        proc.standardOutput = out
        proc.standardError = err

        try proc.run()
        proc.waitUntilExit()

        let errData = err.fileHandleForReading.readDataToEndOfFile()
        if proc.terminationStatus != 0 {
            throw RunError.nonZeroExit(proc.terminationStatus,
                stderr: String(decoding: errData, as: UTF8.self))
        }
        let outData = out.fileHandleForReading.readDataToEndOfFile()
        return String(decoding: outData, as: UTF8.self)
    }
}
