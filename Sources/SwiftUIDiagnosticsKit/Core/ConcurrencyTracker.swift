//
//  ConcurrencyTracker.swift
//  SwiftUIDiagnosticsKit
//
//  Tracks tasks and MainActor violations.
//

import Foundation

public struct LongRunningTaskInfo: Sendable {
    public let taskId: String
    public let createdAt: Date
    public let duration: TimeInterval
}

actor ConcurrencyTracker {
    static let shared = ConcurrencyTracker()
    
    private struct TaskEntry: Sendable {
        let id: String
        let createdAt: Date
        var cancelled: Bool
        var completedAt: Date?
    }
    
    private var tasks: [String: TaskEntry] = [:]
    private var completedDurations: [String: TimeInterval] = [:]
    
    private init() {}
    
    func registerTask(id: String, expectedCancelAfter: Date?) {
        tasks[id] = TaskEntry(id: id, createdAt: Date(), cancelled: false, completedAt: nil)
    }
    
    func cancelTask(id: String) {
        tasks[id]?.cancelled = true
    }
    
    func completeTask(id: String) {
        let now = Date()
        if let t = tasks[id] {
            completedDurations[id] = now.timeIntervalSince(t.createdAt)
        }
        tasks[id]?.completedAt = now
    }
    
    func longRunningTasks(threshold: TimeInterval) -> [LongRunningTaskInfo] {
        let now = Date()
        var result: [LongRunningTaskInfo] = []
        for (_, t) in tasks where t.completedAt == nil && !t.cancelled {
            let duration = now.timeIntervalSince(t.createdAt)
            if duration >= threshold {
                result.append(LongRunningTaskInfo(taskId: t.id, createdAt: t.createdAt, duration: duration))
            }
        }
        return result
    }
    
    func activeTaskCount() -> Int {
        tasks.values.filter { $0.completedAt == nil && !$0.cancelled }.count
    }
    
    func recordMainActorViolation(viewId: String, message: String) {
        Task {
            await MetricsStore.shared.add(DiagnosticEvent(kind: .concurrencyWarning, viewId: viewId, message: message, payload: ["type": "mainActorViolation"]))
        }
    }
    
    func reset() {
        tasks.removeAll()
        completedDurations.removeAll()
    }
}
