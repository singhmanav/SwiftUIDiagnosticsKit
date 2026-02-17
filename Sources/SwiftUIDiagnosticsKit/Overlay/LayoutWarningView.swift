//
//  LayoutWarningView.swift
//  SwiftUIDiagnosticsKit
//
//  List of current layout warnings from LayoutAnalyzer.
//

import SwiftUI

/// Displays layout warnings: high pass count, oscillation.
public struct LayoutWarningView: View {
    @State private var warnings: [LayoutWarning] = []
    
    public init() {}
    
    public var body: some View {
        TimelineView(.periodic(from: .now, by: 1.0)) { _ in
            LayoutWarningContent(warnings: warnings)
                .task { await refresh() }
        }
    }
    
    private func refresh() async {
        warnings = await LayoutAnalyzer.shared.allWarnings()
    }
}

private struct LayoutWarningContent: View {
    let warnings: [LayoutWarning]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Layout warnings")
                .font(.headline)
            if warnings.isEmpty {
                Text("None")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(Array(warnings.enumerated()), id: \.offset) { _, w in
                    LayoutWarningRow(warning: w)
                }
            }
        }
        .padding(8)
        .frame(maxWidth: 320)
        .background(Color(white: 0.95))
        .cornerRadius(8)
    }
}

private struct LayoutWarningRow: View {
    let warning: LayoutWarning
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(String(warning.viewId.prefix(30)))
                .font(.system(.caption2, design: .monospaced))
            Text(warning.message)
                .font(.caption)
                .foregroundColor(warning.isOscillating ? .red : .orange)
            Text("Passes: \(warning.passCount)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.orange.opacity(0.15))
        .cornerRadius(4)
    }
}
