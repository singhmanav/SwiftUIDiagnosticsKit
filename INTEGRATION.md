# Integration Guide

## Installation (Swift Package Manager)

SwiftUIDiagnosticsKit is distributed as a Swift Package. SPM is the only supported dependency manager (CocoaPods and Carthage are not supported).

### Xcode

1. Open your project in Xcode.
2. Go to **File > Add Package Dependencies**.
3. Enter the URL: `https://github.com/singhmanav/SwiftUIDiagnosticsKit.git`
4. Choose a version rule (e.g. "Up to Next Major" from `1.0.0`) or select the `main` branch.
5. Add the `SwiftUIDiagnosticsKit` library to your app target.

### Package.swift

```swift
dependencies: [
    .package(url: "https://github.com/singhmanav/SwiftUIDiagnosticsKit.git", from: "1.0.0")
]
```

Then add `"SwiftUIDiagnosticsKit"` to the `dependencies` array of your target.

---

## Quick Integration (One Call)

The fastest way to integrate is a single modifier on your root view:

```swift
import SwiftUI
import SwiftUIDiagnosticsKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .diagnosticsQuickStart()
        }
    }
}
```

This single call:
- Starts all diagnostics subsystems (redraws, layout, memory, state, concurrency, performance).
- Shows a floating diagnostics overlay in the top-right corner.
- Logs every diagnostics event to the Xcode console with `[SwiftUIDiagnostics]` prefix.

### Options

```swift
.diagnosticsQuickStart(
    showOverlay: true,      // Toggle overlay visibility (default: true)
    logToConsole: true,     // Toggle console logging (default: true)
    config: .default        // Custom DiagnosticsConfiguration
)
```

### Per-view redraw and layout tracking

To track redraws and layout passes for specific views, add `.enableDiagnostics()`:

```swift
Text("Hello")
    .enableDiagnostics()
```

This is optional. Without it, the overlay still shows global counts, leaks, and tasks.

---

## Advanced Integration

If you prefer manual control (e.g. start/stop at specific moments):

```swift
// In App init
init() {
    #if DEBUG
    Diagnostics.start(config: .default)
    #endif
}
```

Then place the overlay yourself:

```swift
ZStack(alignment: .topTrailing) {
    yourContent
    DiagnosticsOverlayView()
        .padding(24)
}
```

Export metrics for CI or dashboards:

```swift
let data = Diagnostics.exportMetrics()
// JSON array of DiagnosticEvent objects
```

---

## What Gets Tracked

| Subsystem | Automatically tracked? | Requires opt-in? |
|-----------|----------------------|-------------------|
| Redraws (body count, redraws/sec, breaches) | Only for views with `.enableDiagnostics()` | Yes |
| Layout (pass count, oscillation, loops) | Only for views with `.enableDiagnostics()` | Yes |
| Memory leaks (ObservableObject) | When using `DiagnosticsObservableObject` or `.withDiagnostics()` | Yes |
| Task tracking (long-running, not cancelled) | When using `diagnosticsTrackedTask { }` | Yes |
| State mutations (MainActor violations, redundant updates) | Via ObservableObject wrapper | Yes |
| Performance (memory samples) | Automatically when `enablePerformanceTracking` is on | No |

---

## Console Logging

When `logToConsole` is `true` (the default), every event is logged via `os_log`:

- **Prefix:** `[SwiftUIDiagnostics]`
- **Subsystem:** `com.swiftuidiagnosticskit`
- **Categories:** `Redraw`, `Layout`, `Memory`, `State`, `Concurrency`, `Performance`, `General`

### Filtering in Xcode

In the Xcode console, use the filter bar and type `SwiftUIDiagnostics` to see only diagnostics logs.

### Turning off logging

```swift
.diagnosticsQuickStart(logToConsole: false)
// or
var config = DiagnosticsConfiguration.default
config.logToConsole = false
Diagnostics.start(config: config)
```

---

## Production Safety

- All instrumentation is compiled out in Release unless `DiagnosticsConfiguration.useInRelease` is set to `true`.
- No private APIs, no method swizzling.
- No UIKit dependency; SwiftUI + Foundation only.
- No code changes are needed for App Store builds; diagnostics modifiers are no-ops in Release.
- For internal/QA builds, set `useInRelease: true` and optionally control remotely via a feature flag.

---

## Error Handling and Edge Cases

- If `Diagnostics.start()` is never called, the overlay shows "Start Diagnostics first."
- Modifiers are no-ops in Release and when diagnostics is not active.
- MetricsStore caps events at `maxStoredEvents` (default 10,000) to prevent unbounded memory growth.
- Console logging is off if `logToConsole` is `false` or diagnostics is not active.
- `exportMetrics()` returns empty `Data` if diagnostics is not running.

---

## Benchmarking

### Running benchmarks

```bash
cd SwiftUIDiagnosticsKit
swift test --filter PerformanceOverheadTests
```

### What is measured

- **MetricsStore throughput:** 10,000 event inserts + JSON export.
- **RedrawTracker throughput:** 500 views x 10 redraws each.
- **Export latency:** Time to serialize 10,000 events to JSON.

### Expected performance

- Recording 10,000 redraw events: < 50 ms.
- Exporting 10,000 events to JSON: < 100 ms.
- Per-view overhead of `.enableDiagnostics()`: negligible (< 0.1 ms per body evaluation).

Benchmarks run as part of `swift test` and are checked by the CI workflow.
