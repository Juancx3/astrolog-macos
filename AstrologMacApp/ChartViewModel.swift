import Foundation
import Combine
import AstrologKit

@MainActor
final class ChartViewModel: ObservableObject {

    enum StepUnit: String, CaseIterable, Identifiable {
        case day = "Day", month = "Month", year = "Year"
        var id: Self { self }
        var days: Double {
            switch self {
            case .day:   return 1.0
            case .month: return 30.4375
            case .year:  return 365.25
            }
        }
    }

    @Published var svgURL: URL?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var chartType: ChartType = .wheel
    @Published var stepUnit: StepUnit = .day
    @Published var julianDay: Double = ChartViewModel.currentJulianDay()

    // Resolved once at init; falls back to a well-known path for dev runs.
    private let binaryPath: String
    private let resourceDirectory: URL

    init() {
        let fm = FileManager.default

        // Swiss Ephemeris builds its search path as "." + ":" + argv[0] directory.
        // In dev builds argv[0] is the long DerivedData path, which pushes the
        // combined string past SE's 255-char limit. Fix: copy both the binary and
        // the resources to short /tmp paths so argv[0] and the working dir are short.
        // Delete these manually if you update bundled resources.

        let shortBin = "/tmp/astrolog"
        let shortRes = URL(fileURLWithPath: "/tmp/astrolog-res")

        // Copy binary
        if let bundleBin = Bundle.main.path(forResource: "astrolog", ofType: nil),
           !fm.fileExists(atPath: shortBin) {
            try? fm.copyItem(atPath: bundleBin, toPath: shortBin)
        }
        try? fm.setAttributes([.posixPermissions: 0o755], ofItemAtPath: shortBin)
        binaryPath = fm.fileExists(atPath: shortBin) ? shortBin : "/usr/local/bin/astrolog"

        // Copy resources
        if let bundleRes = Bundle.main.resourceURL,
           !fm.fileExists(atPath: shortRes.path) {
            try? fm.copyItem(at: bundleRes, to: shortRes)
        }
        resourceDirectory = fm.fileExists(atPath: shortRes.path)
            ? shortRes
            : (Bundle.main.resourceURL ?? URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
    }

    func stepForward()  { julianDay += stepUnit.days; renderChart() }
    func stepBackward() { julianDay -= stepUnit.days; renderChart() }

    func jumpToNow() {
        julianDay = ChartViewModel.currentJulianDay()
        renderChart()
    }

    func renderChart() {
        isLoading = true
        errorMessage = nil

        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString + ".svg")

        var gfx = GraphicsOutput(outputPath: outputURL.path)
        gfx.sidebar = true

        let cmd = AstrologCommand(
            chartType: chartType,
            moment: .julian(julianDay),
            graphics: gfx)

        let binary = binaryPath
        let workDir = resourceDirectory

        Task.detached(priority: .userInitiated) { [weak self] in
            do {
                try AstrologRunner.run(binary: binary, command: cmd, workingDirectory: workDir)
                await MainActor.run {
                    self?.svgURL = outputURL
                    self?.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self?.errorMessage = error.localizedDescription
                    self?.isLoading = false
                }
            }
        }
    }

    // JD for the current moment (fractional day from J2000.0 epoch).
    static func currentJulianDay() -> Double {
        let j2000 = Date(timeIntervalSince1970: 946_728_000) // 2000-01-01 12:00 UTC
        return 2_451_545.0 + Date().timeIntervalSince(j2000) / 86_400.0
    }
}
