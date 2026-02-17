//
//  DiagnosticsLogger.swift
//  SwiftUIDiagnosticsKit
//
//  Centralized console logger. Logs with [SwiftUIDiagnostics] prefix when enabled.
//  Uses os_log with a dedicated subsystem so logs are visible in Xcode console and filterable.
//

import Foundation
import os.log

/// Centralized diagnostics logger. Controlled by `DiagnosticsConfiguration.logToConsole`.
enum DiagnosticsLogger {
    
    private static let subsystem = "com.swiftuidiagnosticskit"
    
    private static let redrawLog = OSLog(subsystem: subsystem, category: "Redraw")
    private static let layoutLog = OSLog(subsystem: subsystem, category: "Layout")
    private static let memoryLog = OSLog(subsystem: subsystem, category: "Memory")
    private static let stateLog = OSLog(subsystem: subsystem, category: "State")
    private static let concurrencyLog = OSLog(subsystem: subsystem, category: "Concurrency")
    private static let performanceLog = OSLog(subsystem: subsystem, category: "Performance")
    private static let generalLog = OSLog(subsystem: subsystem, category: "General")
    
    enum Category: String {
        case redraw = "Redraw"
        case layout = "Layout"
        case memory = "Memory"
        case state = "State"
        case concurrency = "Concurrency"
        case performance = "Performance"
        case general = "General"
    }
    
    /// Log a diagnostics event to console. No-op if logToConsole is disabled.
    static func log(_ message: String, category: Category = .general) {
        guard Diagnostics.isActive, Diagnostics.currentConfiguration.logToConsole else { return }
        
        let osLog: OSLog
        switch category {
        case .redraw: osLog = redrawLog
        case .layout: osLog = layoutLog
        case .memory: osLog = memoryLog
        case .state: osLog = stateLog
        case .concurrency: osLog = concurrencyLog
        case .performance: osLog = performanceLog
        case .general: osLog = generalLog
        }
        
        os_log("[SwiftUIDiagnostics][%{public}@] %{public}@", log: osLog, type: .debug, category.rawValue, message)
    }
    
    /// Log an event from MetricsStore to console.
    static func logEvent(_ event: DiagnosticEvent) {
        guard Diagnostics.isActive, Diagnostics.currentConfiguration.logToConsole else { return }
        
        let cat: Category
        switch event.kind {
        case .redrawBreach: cat = .redraw
        case .layoutWarning: cat = .layout
        case .suspectedLeak: cat = .memory
        case .stateViolation: cat = .state
        case .concurrencyWarning: cat = .concurrency
        case .performanceSample: cat = .performance
        }
        
        let viewPart = event.viewId.map { " view=\($0)" } ?? ""
        let msgPart = event.message ?? event.kind.rawValue
        log("\(msgPart)\(viewPart)", category: cat)
    }
}
