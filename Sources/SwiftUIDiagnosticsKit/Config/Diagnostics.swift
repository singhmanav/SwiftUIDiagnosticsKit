//
//  Diagnostics.swift
//  SwiftUIDiagnosticsKit
//
//  Namespace for starting/stopping diagnostics and exporting metrics.
//  No-op when not in DEBUG or when config disables tracking.
//

import Foundation

#if DEBUG || SWIFTUI_DIAGNOSTICS
public enum Diagnostics {
    
    private static let lock = NSLock()
    private static var _isActive = false
    private static var _config: DiagnosticsConfiguration = .disabled
    
    /// Whether diagnostics is currently running.
    public static var isActive: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isActive
    }
    
    /// Current configuration. Only meaningful when isActive.
    public static var currentConfiguration: DiagnosticsConfiguration {
        lock.lock()
        defer { lock.unlock() }
        return _config
    }
    
    /// Start diagnostics with the given configuration. No-op in Release unless config.useInRelease is true.
    public static func start(config: DiagnosticsConfiguration = .default) {
        lock.lock()
        guard !_isActive else { lock.unlock(); return }
        _config = config
        _isActive = true
        lock.unlock()
        // Actual wiring to trackers happens when they're implemented
        DiagnosticsRuntime.shared.start(config: config)
    }
    
    /// Stop diagnostics and clear session state.
    public static func stop() {
        lock.lock()
        guard _isActive else { lock.unlock(); return }
        _isActive = false
        lock.unlock()
        DiagnosticsRuntime.shared.stop()
    }
    
    /// Export all session metrics as JSON. Returns empty data if not active or no events.
    public static func exportMetrics() -> Data {
        guard isActive else { return Data() }
        return DiagnosticsRuntime.shared.exportMetrics()
    }

    /// Callback when redraws/sec exceed threshold for a view. Use for tests or custom handling.
    public static func onRedrawThresholdBreach(_ callback: (@Sendable (String) -> Void)?) {
        Task { await RedrawTracker.shared.setOnThresholdBreach(callback) }
    }

    /// When true, overlay can show redraw heatmap. Default true in debug.
    public static var enableRedrawHeatmap = true
    
    /// One-call integration: starts diagnostics with all tracking + console logging enabled.
    /// Call once (e.g. in App init) and use `.diagnosticsQuickStart()` on root view to show the overlay.
    /// - Parameters:
    ///   - config: Configuration to use. Defaults to `.default` (all tracking on, console logging on).
    ///   - logToConsole: Whether to log events to Xcode console. Overrides config value if set.
    public static func quickStart(config: DiagnosticsConfiguration = .default, logToConsole: Bool = true) {
        var cfg = config
        cfg.logToConsole = logToConsole
        start(config: cfg)
        DiagnosticsLogger.log("Diagnostics started via quickStart()", category: .general)
    }
}
#else
public enum Diagnostics {
    public static var isActive: Bool { false }
    public static var currentConfiguration: DiagnosticsConfiguration { .disabled }
    public static func start(config: DiagnosticsConfiguration = .default) {}
    public static func stop() {}
    public static func exportMetrics() -> Data { Data() }
    public static func onRedrawThresholdBreach(_ callback: (@Sendable (String) -> Void)?) {}
    public static var enableRedrawHeatmap = false
    public static func quickStart(config: DiagnosticsConfiguration = .default, logToConsole: Bool = true) {}
}
#endif

/// Internal runtime that coordinates all trackers and storage. Only used when DEBUG/SWIFTUI_DIAGNOSTICS.
final class DiagnosticsRuntime: @unchecked Sendable {
    static let shared = DiagnosticsRuntime()
    
    private let lock = NSLock()
    private var samplingTask: Task<Void, Never>?
    
    private init() {}
    
    func start(config: DiagnosticsConfiguration) {
        Task {
            await MetricsStore.shared.configure(maxEvents: config.maxStoredEvents)
        }
        if config.enablePerformanceTracking {
            let task = Task {
                await self.performanceSamplingLoop()
            }
            lock.lock()
            samplingTask = task
            lock.unlock()
        }
    }
    
    private func performanceSamplingLoop() async {
        while !Task.isCancelled {
            try? await Task.sleep(nanoseconds: 5_000_000_000) // 5s
            guard Diagnostics.isActive, !Task.isCancelled else { break }
            let mb = Double(ProcessInfo.processInfo.physicalMemory) / 1_048_576
            await MetricsStore.shared.add(DiagnosticEvent(kind: .performanceSample, message: "Memory", payload: ["mb": String(format: "%.1f", mb)]))
        }
    }
    
    func stop() {
        lock.lock()
        samplingTask?.cancel()
        samplingTask = nil
        lock.unlock()
        
        Task {
            await RedrawTracker.shared.reset()
            await LayoutAnalyzer.shared.reset()
            await MemoryLeakDetector.shared.reset()
            await StateMonitor.shared.reset()
            await ConcurrencyTracker.shared.reset()
            await MetricsStore.shared.clear()
        }
    }
    
    func exportMetrics() -> Data {
        // Use a detached task + semaphore to bridge sync -> async.
        // Safe: called from non-async Diagnostics.exportMetrics().
        final class Box: @unchecked Sendable {
            var data = Data()
        }
        let box = Box()
        let semaphore = DispatchSemaphore(value: 0)
        Task.detached {
            box.data = await MetricsStore.shared.exportJSON()
            semaphore.signal()
        }
        semaphore.wait()
        return box.data
    }
}
