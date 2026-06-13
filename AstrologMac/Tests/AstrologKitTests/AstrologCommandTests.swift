import XCTest
@testable import AstrologKit

final class AstrologCommandTests: XCTestCase {

    func testFullMomentTrimsTrailingZeros() {
        let m = ChartMoment.full(month: 6, day: 12, year: 2026,
                                 time: 14.5, dst: 0, zone: 8,
                                 lon: 122.33, lat: 47.6)
        XCTAssertEqual(m.arguments,
            ["-qb", "6", "12", "2026", "14.5", "0", "8", "122.33", "47.6"])
    }

    func testJulianMoment() {
        XCTAssertEqual(ChartMoment.julian(2461173.5).arguments,
                       ["-qj", "2461173.5"])
    }

    func testChartTypeFlag() {
        XCTAssertEqual(ChartType.wheel.arguments, ["-w"])
        XCTAssertEqual(ChartType.grid.arguments, ["-g"])
    }

    func testGraphicsOutputOrderAndOptions() {
        var g = GraphicsOutput(outputPath: "/tmp/chart.svg")
        g.format = .svg
        g.width = 900
        g.sidebar = true
        g.labelObjects = true
        XCTAssertEqual(g.arguments,
            ["-XV", "-Xw", "900", "=Xm", "-Xv", "-Xl", "-Xo", "/tmp/chart.svg"])
    }

    func testColorOffForcesUnderscoreForm() {
        var g = GraphicsOutput(outputPath: "/tmp/c.png")
        g.format = .png
        g.width = nil
        g.color = false
        XCTAssertEqual(g.arguments, ["-Xbp", "_Xm", "-Xo", "/tmp/c.png"])
    }

    func testFullCommandAssemblyOrder() {
        var g = GraphicsOutput(outputPath: "/tmp/chart.svg")
        g.width = 900
        let cmd = AstrologCommand(
            chartType: .wheel,
            moment: .full(month: 6, day: 12, year: 2026,
                          time: 14.5, dst: 0, zone: 8, lon: 122.33, lat: 47.6),
            graphics: g)
        XCTAssertEqual(cmd.arguments(),
            ["-w",
             "-qb", "6", "12", "2026", "14.5", "0", "8", "122.33", "47.6",
             "-XV", "-Xw", "900", "=Xm", "-Xo", "/tmp/chart.svg"])
    }

    func testSynastryWithSecondChartSlot() {
        let cmd = AstrologCommand(
            chartType: .wheel,
            moment: .dateTime(month: 6, day: 12, year: 2026, time: 14.5),
            input: .slot(1, path: "partner.as"),
            extraFlags: ["-r1"])
        XCTAssertEqual(cmd.arguments(),
            ["-w", "-qa", "6", "12", "2026", "14.5", "-i1", "partner.as", "-r1"])
    }
}
