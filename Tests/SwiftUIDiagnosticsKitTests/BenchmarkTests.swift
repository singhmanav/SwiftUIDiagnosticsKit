//
//  BenchmarkTests.swift
//  SwiftUIDiagnosticsKitTests
//
//  Benchmarks to catch regressions in core tracker and MetricsStore performance.
//  These run as part of `swift test` and CI.
//

import XCTest
@testable import SwiftUIDiagnosticsKit

final class BenchmarkTests: XCTestCase {
    
    /// Benchmark: record 10,000 redraw events across 100 views.
    func testRedrawTracker10kEvents() async throws {
        await RedrawTracker.shared.reset()
        
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<100 {
            let id = "bench-view-\(i)"
            for _ in 0..<100 {
                await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .unknown, parentId: nil)
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        let ids = await RedrawTracker.shared.allViewIds()
        XCTAssertEqual(ids.count, 100)
        
        // Should complete in under 2 seconds (generous; typical < 50ms)
        XCTAssertLessThan(elapsed, 2.0, "10k redraw records took \(elapsed)s, expected < 2s")
        print("[Benchmark] 10k redraw events: \(String(format: "%.3f", elapsed))s")
        
        await RedrawTracker.shared.reset()
    }
    
    /// Benchmark: record 1,000 layout passes across 50 views.
    func testLayoutAnalyzer1kPasses() async throws {
        await LayoutAnalyzer.shared.reset()
        
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<50 {
            let id = "bench-layout-\(i)"
            for j in 0..<20 {
                await LayoutAnalyzer.shared.recordLayoutPass(
                    viewId: id,
                    size: LayoutSize(width: CGFloat(j * 10), height: CGFloat(j * 5))
                )
            }
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        XCTAssertLessThan(elapsed, 2.0, "1k layout passes took \(elapsed)s, expected < 2s")
        print("[Benchmark] 1k layout passes: \(String(format: "%.3f", elapsed))s")
        
        await LayoutAnalyzer.shared.reset()
    }
    
    /// Benchmark: insert 10,000 events into MetricsStore and export to JSON.
    func testMetricsStoreExport10k() async throws {
        await MetricsStore.shared.clear()
        await MetricsStore.shared.configure(maxEvents: 15_000)
        
        let insertStart = CFAbsoluteTimeGetCurrent()
        for i in 0..<10_000 {
            await MetricsStore.shared.add(DiagnosticEvent(
                kind: .redrawBreach,
                viewId: "bench-v\(i % 100)",
                message: "bench event \(i)"
            ))
        }
        let insertElapsed = CFAbsoluteTimeGetCurrent() - insertStart
        
        let exportStart = CFAbsoluteTimeGetCurrent()
        let data = await MetricsStore.shared.exportJSON()
        let exportElapsed = CFAbsoluteTimeGetCurrent() - exportStart
        
        XCTAssertFalse(data.isEmpty)
        XCTAssertLessThan(insertElapsed, 2.0, "10k inserts took \(insertElapsed)s, expected < 2s")
        XCTAssertLessThan(exportElapsed, 5.0, "10k export took \(exportElapsed)s, expected < 5s")
        print("[Benchmark] 10k inserts: \(String(format: "%.3f", insertElapsed))s")
        print("[Benchmark] 10k export:  \(String(format: "%.3f", exportElapsed))s, size: \(data.count) bytes")
        
        await MetricsStore.shared.clear()
    }
    
    /// Benchmark: memory leak detector register/check cycle.
    func testMemoryLeakDetectorThroughput() async throws {
        await MemoryLeakDetector.shared.reset()
        
        var objects: [NSObject] = []
        for _ in 0..<100 {
            objects.append(NSObject())
        }
        
        let pastDate = Date().addingTimeInterval(-10)
        let start = CFAbsoluteTimeGetCurrent()
        for obj in objects {
            await MemoryLeakDetector.shared.register(object: obj, expectedDeallocAfter: pastDate)
        }
        let leaks = await MemoryLeakDetector.shared.suspectedLeaks(leakTimeout: 1)
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        // All should be "suspected" since expectedDeallocAfter is in the past
        XCTAssertEqual(leaks.count, 100)
        XCTAssertLessThan(elapsed, 2.0, "100 register+check took \(elapsed)s, expected < 2s")
        print("[Benchmark] 100 register+check: \(String(format: "%.3f", elapsed))s")
        
        await MemoryLeakDetector.shared.reset()
    }
    
    /// Benchmark: state monitor record changes.
    func testStateMonitorThroughput() async throws {
        await StateMonitor.shared.reset()
        
        let start = CFAbsoluteTimeGetCurrent()
        for i in 0..<1000 {
            await StateMonitor.shared.recordChange(
                viewId: "bench-\(i % 50)",
                key: "count",
                old: "\(i)",
                new: "\(i + 1)",
                isOnMainActor: true
            )
        }
        let elapsed = CFAbsoluteTimeGetCurrent() - start
        
        XCTAssertLessThan(elapsed, 2.0, "1k state records took \(elapsed)s, expected < 2s")
        print("[Benchmark] 1k state records: \(String(format: "%.3f", elapsed))s")
        
        await StateMonitor.shared.reset()
    }
}
