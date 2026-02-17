//
//  RedrawHeatmapView.swift
//  SwiftUIDiagnosticsKit
//
//  List of views colored by redraw frequency (heatmap as list).
//

import SwiftUI

/// Shows view IDs and their redraw counts with color intensity (green = low, red = high).
public struct RedrawHeatmapView: View {
    @State private var items: [(viewId: String, count: Int, rps: Double)] = []
    
    public init() {}
    
    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { _ in
            VStack(alignment: .leading, spacing: 4) {
                Text("Redraw heatmap")
                    .font(.headline)
                if items.isEmpty {
                    Text("No data")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    let maxCount = items.map(\.count).max() ?? 1
                    ForEach(items.prefix(20), id: \.viewId) { item in
                        HStack {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(heatColor(count: item.count, max: maxCount))
                                .frame(width: 60, height: 12)
                            Text(String(item.viewId.prefix(24)))
                                .font(.system(.caption2, design: .monospaced))
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.count)")
                                .font(.caption.monospacedDigit())
                            Text("\(String(format: "%.1f", item.rps))/s")
                                .font(.caption2.monospacedDigit())
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .padding(8)
            .frame(maxWidth: 300)
            .background(Color(white: 0.95))
            .cornerRadius(8)
            .task { await refresh() }
        }
    }
    
    private func heatColor(count: Int, max: Int) -> Color {
        guard max > 0 else { return .green }
        let t = Double(count) / Double(max)
        if t < 0.33 { return .green }
        if t < 0.66 { return .yellow }
        return .red
    }
    
    private func refresh() async {
        let ids = await RedrawTracker.shared.allViewIds()
        items = await ids.asyncMap { id in
            let count = await RedrawTracker.shared.redrawCount(for: id)
            let rps = await RedrawTracker.shared.redrawsPerSecond(for: id)
            return (viewId: id, count: count, rps: rps)
        }.sorted { $0.count > $1.count }
    }
}

extension Sequence {
    func asyncMap<T>(_ transform: (Element) async -> T) async -> [T] {
        var result: [T] = []
        for element in self {
            result.append(await transform(element))
        }
        return result
    }
}
