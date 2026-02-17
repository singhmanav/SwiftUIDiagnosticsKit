//
//  DiagnosticsConfiguration.swift
//  SwiftUIDiagnosticsKit
//
//  Configuration for diagnostics instrumentation. Safe for production:
//  all tracking is disabled by default in Release unless explicitly enabled.
//

import Foundation

/// Configuration for SwiftUI diagnostics. Use to enable/disable subsystems and set thresholds.
public struct DiagnosticsConfiguration: Sendable {
    
    // MARK: - Feature Flags
    
    /// Enable redraw (body recomputation) tracking.
    public var enableRedrawTracking: Bool
    
    /// Enable layout pass and loop detection.
    public var enableLayoutTracking: Bool
    
    /// Enable memory leak detection (ObservableObject, Task, etc.).
    public var enableMemoryTracking: Bool
    
    /// Enable state mutation and MainActor tracking.
    public var enableStateTracking: Bool
    
    /// Enable concurrency monitoring (Task, MainActor violations).
    public var enableConcurrencyTracking: Bool
    
    /// Enable performance sampling (duration, memory).
    public var enablePerformanceTracking: Bool
    
    // MARK: - Thresholds
    
    /// Redraws per second above which a breach is reported. Default 60.
    public var redrawThresholdPerSecond: Int
    
    /// Layout passes in a short window above which a loop is suspected. Default 20.
    public var layoutLoopThreshold: Int
    
    /// Seconds after expected dealloc before object is flagged as suspected leak. Default 10.
    public var leakTimeout: TimeInterval
    
    /// Task duration in seconds above which a long-running warning is emitted. Default 5.
    public var longRunningTaskThreshold: TimeInterval
    
    /// Max number of events to keep in MetricsStore (cap to avoid unbounded growth). Default 10_000.
    public var maxStoredEvents: Int
    
    /// When true, instrumentation runs even in Release (e.g. internal builds). Default false.
    public var useInRelease: Bool
    
    /// When true, every diagnostics event is also logged to console via os_log.
    /// Prefix: `[SwiftUIDiagnostics]`. Filterable in Xcode by subsystem `com.swiftuidiagnosticskit`.
    public var logToConsole: Bool
    
    // MARK: - Initialization
    
    public init(
        enableRedrawTracking: Bool = true,
        enableLayoutTracking: Bool = true,
        enableMemoryTracking: Bool = true,
        enableStateTracking: Bool = true,
        enableConcurrencyTracking: Bool = true,
        enablePerformanceTracking: Bool = true,
        redrawThresholdPerSecond: Int = 60,
        layoutLoopThreshold: Int = 20,
        leakTimeout: TimeInterval = 10,
        longRunningTaskThreshold: TimeInterval = 5,
        maxStoredEvents: Int = 10_000,
        useInRelease: Bool = false,
        logToConsole: Bool = true
    ) {
        self.enableRedrawTracking = enableRedrawTracking
        self.enableLayoutTracking = enableLayoutTracking
        self.enableMemoryTracking = enableMemoryTracking
        self.enableStateTracking = enableStateTracking
        self.enableConcurrencyTracking = enableConcurrencyTracking
        self.enablePerformanceTracking = enablePerformanceTracking
        self.redrawThresholdPerSecond = redrawThresholdPerSecond
        self.layoutLoopThreshold = layoutLoopThreshold
        self.leakTimeout = leakTimeout
        self.longRunningTaskThreshold = longRunningTaskThreshold
        self.maxStoredEvents = maxStoredEvents
        self.useInRelease = useInRelease
        self.logToConsole = logToConsole
    }
    
    /// Default configuration: all tracking on, standard thresholds. Debug-only by default.
    public static let `default` = DiagnosticsConfiguration()
    
    /// All tracking disabled (e.g. for production when useInRelease is false).
    public static let disabled = DiagnosticsConfiguration(
        enableRedrawTracking: false,
        enableLayoutTracking: false,
        enableMemoryTracking: false,
        enableStateTracking: false,
        enableConcurrencyTracking: false,
        enablePerformanceTracking: false,
        logToConsole: false
    )
}
