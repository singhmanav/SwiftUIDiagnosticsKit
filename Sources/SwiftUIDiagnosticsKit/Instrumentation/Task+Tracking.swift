//
//  Task+Tracking.swift
//  SwiftUIDiagnosticsKit
//
//  Task creation wrapper for concurrency tracking and leak detection.
//

import Foundation

/// Create a Task that is registered with ConcurrencyTracker. Call from view code to track cancellation.
public func diagnosticsTrackedTask<T>(
    priority: TaskPriority? = nil,
    viewId: String? = nil,
    operation: @escaping @Sendable () async throws -> T
) -> Task<T, Error> {
    let taskId = UUID().uuidString
    let config = Diagnostics.currentConfiguration
    guard Diagnostics.isActive, config.enableConcurrencyTracking else {
        return Task(priority: priority, operation: operation)
    }
    Task {
        await ConcurrencyTracker.shared.registerTask(id: taskId, expectedCancelAfter: nil)
    }
    return Task(priority: priority) {
        defer {
            Task {
                await ConcurrencyTracker.shared.completeTask(id: taskId)
            }
        }
        let result: T
        do {
            result = try await operation()
            return result
        } catch {
            throw error
        }
    }
}
