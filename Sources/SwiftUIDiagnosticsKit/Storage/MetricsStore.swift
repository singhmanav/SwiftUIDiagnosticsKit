//
//  MetricsStore.swift
//  SwiftUIDiagnosticsKit
//
//  In-memory event store for diagnostics. Append-only; export to JSON.
//

import Foundation

/// Event kinds for serialization.
enum DiagnosticEventKind: String, Codable, Sendable {
    case redrawBreach
    case layoutWarning
    case suspectedLeak
    case stateViolation
    case concurrencyWarning
    case performanceSample
}

/// Generic diagnostic event for storage and export.
struct DiagnosticEvent: Codable, Sendable {
    let kind: DiagnosticEventKind
    let viewId: String?
    let message: String?
    let timestamp: Date
    let payload: [String: String]?
    
    init(kind: DiagnosticEventKind, viewId: String? = nil, message: String? = nil, payload: [String: String]? = nil) {
        self.kind = kind
        self.viewId = viewId
        self.message = message
        self.timestamp = Date()
        self.payload = payload
    }
}

actor MetricsStore {
    static let shared = MetricsStore()
    
    private var events: [DiagnosticEvent] = []
    private var maxEvents: Int = 10_000
    
    private init() {}
    
    func configure(maxEvents: Int) {
        self.maxEvents = max(maxEvents, 100)
    }
    
    func add(_ event: DiagnosticEvent) {
        events.append(event)
        if events.count > maxEvents {
            events.removeFirst(events.count - maxEvents)
        }
        DiagnosticsLogger.logEvent(event)
    }
    
    func clear() {
        events.removeAll()
    }
    
    func exportJSON() -> Data {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return (try? encoder.encode(events)) ?? Data()
    }
    
    func recentEvents(limit: Int = 100) -> [DiagnosticEvent] {
        Array(events.suffix(limit))
    }
}
