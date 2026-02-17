//
//  DiagnosticsOverlayView.swift
//  SwiftUIDiagnosticsKit
//
//  Floating debug overlay: redraw counts, layout warnings, leaks, tasks, memory.
//

import SwiftUI

private var overlayBackgroundColor: Color { Color(white: 0.95) }

/// Floating overlay showing live diagnostics. Toggleable; does not affect layout.
public struct DiagnosticsOverlayView: View {
    @State private var isExpanded = true
    @State private var showRedrawHeatmap = false
    @State private var showLayoutWarnings = true
    @StateObject private var refreshTicker = RefreshTicker()
    
    public init() {}
    
    public var body: some View {
        #if DEBUG || SWIFTUI_DIAGNOSTICS
        overlayContent
        #else
        Text("Diagnostics disabled")
            .font(.caption)
            .foregroundColor(.secondary)
            .padding(8)
        #endif
    }
    
    @ViewBuilder
    private var overlayContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Diagnostics")
                    .font(.headline)
                Spacer()
                Button(isExpanded ? "−" : "+") { isExpanded.toggle() }
            }
            .padding(.horizontal, 8)
            .padding(.top, 8)
            
            if isExpanded {
                Divider()
                DiagnosticsOverlayBody(showRedrawHeatmap: $showRedrawHeatmap, showLayoutWarnings: $showLayoutWarnings, refreshID: $refreshTicker.refreshID)
                Divider()
                Toggle("Redraw heatmap", isOn: $showRedrawHeatmap)
                Toggle("Layout warnings", isOn: $showLayoutWarnings)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 8)
            }
        }
        .frame(maxWidth: 280, alignment: .leading)
        .background(overlayBackgroundColor)
        .cornerRadius(12)
        .shadow(radius: 8)
    }
}

struct DiagnosticsOverlayBody: View {
    @Binding var showRedrawHeatmap: Bool
    @Binding var showLayoutWarnings: Bool
    @Binding var refreshID: UUID
    @State private var redrawCounts: [(String, Int)] = []
    @State private var layoutWarnings: [LayoutWarning] = []
    @State private var suspectedLeaks: [SuspectedLeak] = []
    @State private var activeTasks: Int = 0
    @State private var memoryMB: Double = 0
    @State private var violations: [StateViolation] = []
    
    var body: some View {
        Group {
            if !Diagnostics.isActive {
                Text("Start Diagnostics first")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(8)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Redraws: \(redrawCounts.prefix(5).map { "\($0.0.prefix(8)):\($0.1)" }.joined(separator: " "))")
                        .font(.system(.caption, design: .monospaced))
                        .lineLimit(2)
                    Text("Layout: \(layoutWarnings.count) warnings")
                        .font(.caption)
                    Text("Leaks: \(suspectedLeaks.count) suspected")
                        .font(.caption)
                        .foregroundColor(suspectedLeaks.isEmpty ? .primary : .red)
                    Text("Tasks: \(activeTasks)")
                        .font(.caption)
                    Text("Memory: \(String(format: "%.1f", memoryMB)) MB")
                        .font(.caption)
                    Text("State violations: \(violations.count)")
                        .font(.caption)
                        .foregroundColor(violations.isEmpty ? .primary : .orange)
                }
                .padding(.horizontal, 8)
                .id(refreshID)
                .task(id: refreshID) {
                    await refresh()
                }
            }
        }
    }
    
    private func refresh() async {
        let ids = await RedrawTracker.shared.allViewIds()
        var counts: [(String, Int)] = []
        for id in ids {
            let count = await RedrawTracker.shared.redrawCount(for: id)
            counts.append((id, count))
        }
        redrawCounts = counts.sorted { $0.1 > $1.1 }
        layoutWarnings = await LayoutAnalyzer.shared.allWarnings()
        suspectedLeaks = await MemoryLeakDetector.shared.suspectedLeaks(leakTimeout: Diagnostics.currentConfiguration.leakTimeout)
        activeTasks = await ConcurrencyTracker.shared.activeTaskCount()
        violations = await StateMonitor.shared.violationsList()
        memoryMB = Double(ProcessInfo.processInfo.physicalMemory) / 1_048_576
    }
}

/// Publishes a new value every second so overlay can refresh.
private final class RefreshTicker: ObservableObject {
    @Published var refreshID = UUID()
    private var timer: Timer?
    init() {
        let t = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.refreshID = UUID()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }
    deinit { timer?.invalidate() }
}

/// Convenience: overlay that can be toggled via binding.
public struct DiagnosticsOverlay: View {
    let isPresented: Bool
    
    public init(isPresented: Bool = true) {
        self.isPresented = isPresented
    }
    
    public var body: some View {
        if isPresented {
            DiagnosticsOverlayView()
        }
    }
}
