//
//  LayoutAnalyzer.swift
//  SwiftUIDiagnosticsKit
//
//  Tracks layout passes per view; detects loops and oscillation.
//

import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

#if canImport(CoreGraphics)
public typealias LayoutSize = CGSize
#else
public struct LayoutSize: Sendable {
    public var width: Double
    public var height: Double
    public init(width: Double, height: Double) { self.width = width; self.height = height }
}
#endif

public struct LayoutWarning: Sendable {
    public let viewId: String
    public let passCount: Int
    public let isOscillating: Bool
    public let message: String
}

actor LayoutAnalyzer {
    static let shared = LayoutAnalyzer()
    private static let maxSizes = 10
    
    private struct ViewEntry: Sendable {
        var passCount: Int
        var sizes: [LayoutSize]
        var lastPassTime: Date?
    }
    
    private var entries: [String: ViewEntry] = [:]
    
    private init() {}
    
    func recordLayoutPass(viewId: String, size: LayoutSize) {
        let now = Date()
        if entries[viewId] == nil {
            entries[viewId] = ViewEntry(passCount: 0, sizes: [], lastPassTime: nil)
        }
        entries[viewId]?.passCount += 1
        entries[viewId]?.lastPassTime = now
        entries[viewId]?.sizes.append(size)
        if var s = entries[viewId]?.sizes, s.count > Self.maxSizes {
            s.removeFirst()
            entries[viewId]?.sizes = s
        }
    }
    
    func layoutPassCount(for viewId: String) -> Int {
        entries[viewId]?.passCount ?? 0
    }
    
    func detectOscillation(viewId: String) -> Bool {
        guard let sizes = entries[viewId]?.sizes, sizes.count >= 4 else { return false }
        let s = sizes
        // A->B->A->B pattern
        if s.count >= 4 {
            let a = s[s.count - 4]
            let b = s[s.count - 3]
            let a2 = s[s.count - 2]
            let b2 = s[s.count - 1]
            if abs(a.width - a2.width) < 0.1, abs(b.width - b2.width) < 0.1,
               abs(a.height - a2.height) < 0.1, abs(b.height - b2.height) < 0.1 {
                return true
            }
        }
        return false
    }
    
    func warnings(for viewId: String) -> [LayoutWarning] {
        var out: [LayoutWarning] = []
        guard let e = entries[viewId] else { return out }
        if e.passCount >= 20 {
            out.append(LayoutWarning(viewId: viewId, passCount: e.passCount, isOscillating: false, message: "High layout pass count: \(e.passCount)"))
        }
        if detectOscillation(viewId: viewId) {
            out.append(LayoutWarning(viewId: viewId, passCount: e.passCount, isOscillating: true, message: "Oscillating layout"))
        }
        return out
    }
    
    func allWarnings() -> [LayoutWarning] {
        var result: [LayoutWarning] = []
        for id in entries.keys {
            result.append(contentsOf: warnings(for: id))
        }
        return result
    }
    
    func reset() {
        entries.removeAll()
    }
}
