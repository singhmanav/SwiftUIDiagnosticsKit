//
//  StateMonitor.swift
//  SwiftUIDiagnosticsKit
//
//  Tracks state changes; MainActor and redundant update detection.
//

import Foundation

public struct StateViolation: Sendable {
    public let viewId: String
    public let key: String?
    public let isOnMainActor: Bool
    public let message: String
}

actor StateMonitor {
    static let shared = StateMonitor()
    
    private struct ViewState: Sendable {
        var changeCount: Int
        var redundantCount: Int
        var lastValueKey: String?
    }
    
    private var viewStates: [String: ViewState] = [:]
    private var violations: [StateViolation] = []
    private let maxViolations = 200
    
    private init() {}
    
    func recordChange(viewId: String, key: String?, old: String?, new: String?, isOnMainActor: Bool) {
        if viewStates[viewId] == nil {
            viewStates[viewId] = ViewState(changeCount: 0, redundantCount: 0, lastValueKey: nil)
        }
        viewStates[viewId]?.changeCount += 1
        
        if key != nil, old == new, old != nil {
            viewStates[viewId]?.redundantCount += 1
        }
        viewStates[viewId]?.lastValueKey = key
        
        if !isOnMainActor {
            let v = StateViolation(viewId: viewId, key: key, isOnMainActor: false, message: "State change off MainActor")
            violations.append(v)
            if violations.count > maxViolations { violations.removeFirst() }
        }
    }
    
    func redundantUpdateCount(for viewId: String) -> Int {
        viewStates[viewId]?.redundantCount ?? 0
    }
    
    func violationsList() -> [StateViolation] {
        Array(violations)
    }
    
    func reset() {
        viewStates.removeAll()
        violations.removeAll()
    }
}
