//
//  PerformanceOverheadTests.swift
//  SwiftUIDiagnosticsKitTests
//

import XCTest
@testable import SwiftUIDiagnosticsKit

final class PerformanceOverheadTests: XCTestCase {
    
    func testMetricsStoreAddAndExport() async throws {
        await MetricsStore.shared.clear()
        for i in 0..<100 {
            await MetricsStore.shared.add(DiagnosticEvent(kind: .redrawBreach, viewId: "v\(i)", message: "test"))
        }
        let data = await MetricsStore.shared.exportJSON()
        XCTAssertFalse(data.isEmpty)
    }
    
    func testRedrawTrackerManyViews() async throws {
        await RedrawTracker.shared.reset()
        for i in 0..<50 {
            let id = "view-\(i)"
            for _ in 0..<10 {
                await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .unknown, parentId: nil)
            }
        }
        let ids = await RedrawTracker.shared.allViewIds()
        XCTAssertEqual(ids.count, 50)
    }
}
