//
//  RedrawTracker.swift
//  SwiftUIDiagnosticsKit
//
//  Tracks body recomputations per view; frequency and threshold breaches.
//

import Foundation

/// Cause of a redraw for diagnostics.
public enum RedrawCause: Sendable {
    case stateChange
    case envChange
    case bindingChange
    case identityChange
    case unknown
}

actor RedrawTracker {
    static let shared = RedrawTracker()
    
    private static let maxTimestamps = 120
    
    private struct ViewEntry: Sendable {
        var count: Int
        var timestamps: [Date]
        var lastCause: RedrawCause?
    }
    
    private var entries: [String: ViewEntry] = [:]
    private var thresholdBreachCallback: (@Sendable (String) -> Void)?
    
    private init() {}
    
    func setOnThresholdBreach(_ callback: (@Sendable (String) -> Void)?) {
        thresholdBreachCallback = callback
    }
    
    func recordBodyInvocation(viewId: String, cause: RedrawCause = .unknown, parentId: String?) {
        let now = Date()
        if entries[viewId] == nil {
            entries[viewId] = ViewEntry(count: 0, timestamps: [], lastCause: nil)
        }
        entries[viewId]?.count += 1
        entries[viewId]?.timestamps.append(now)
        entries[viewId]?.lastCause = cause
        if var ts = entries[viewId]?.timestamps, ts.count > Self.maxTimestamps {
            ts.removeFirst()
            entries[viewId]?.timestamps = ts
        }
        let rps = redrawsPerSecond(for: viewId)
        let threshold = Diagnostics.currentConfiguration.redrawThresholdPerSecond
        if rps >= Double(threshold) {
            thresholdBreachCallback?(viewId)
        }
    }
    
    func redrawCount(for viewId: String) -> Int {
        entries[viewId]?.count ?? 0
    }
    
    func redrawsPerSecond(for viewId: String) -> Double {
        guard let ts = entries[viewId]?.timestamps, !ts.isEmpty else { return 0 }
        let window: TimeInterval = 1.0
        let cutoff = Date().addingTimeInterval(-window)
        let recent = ts.filter { $0 >= cutoff }
        return Double(recent.count) / window
    }
    
    func recentCauses(for viewId: String) -> RedrawCause? {
        entries[viewId]?.lastCause
    }
    
    func allViewIds() -> [String] {
        Array(entries.keys)
    }
    
    func reset() {
        entries.removeAll()
    }
}
