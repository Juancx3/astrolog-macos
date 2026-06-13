import SwiftUI
import AstrologKit

struct ContentView: View {
    @StateObject private var vm = ChartViewModel()

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            chartArea
        }
        .frame(minWidth: 800, minHeight: 700)
        .onAppear { vm.renderChart() }
    }

    // MARK: - Toolbar

    private var toolbar: some View {
        HStack(spacing: 12) {
            Button(action: vm.stepBackward) {
                Image(systemName: "chevron.left")
            }
            .keyboardShortcut("-", modifiers: [])
            .help("Step backward")

            Button(action: vm.stepForward) {
                Image(systemName: "chevron.right")
            }
            .keyboardShortcut("=", modifiers: [])
            .help("Step forward (+)")

            Picker("Step", selection: $vm.stepUnit) {
                ForEach(ChartViewModel.StepUnit.allCases) {
                    Text($0.rawValue).tag($0)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 180)
            .help("Time step size")

            Button("Now", action: vm.jumpToNow)
                .help("Jump to current moment")

            Spacer()

            Text("JD \(vm.julianDay, specifier: "%.4f")")
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .help("Julian day")

            Spacer()

            Picker("Chart type", selection: $vm.chartType) {
                Text("Wheel").tag(ChartType.wheel)
                Text("Grid").tag(ChartType.grid)
                Text("Listing").tag(ChartType.listing)
                Text("Astrocartography").tag(ChartType.astrocartography)
            }
            .pickerStyle(.segmented)
            .frame(width: 300)
            .onChange(of: vm.chartType) { _ in vm.renderChart() }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Chart area

    @ViewBuilder
    private var chartArea: some View {
        if vm.isLoading {
            ProgressView("Rendering…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = vm.errorMessage {
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
                Text(err)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Button("Retry") { vm.renderChart() }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ChartWebView(url: vm.svgURL)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
