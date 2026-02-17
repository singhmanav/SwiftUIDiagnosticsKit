//
//  RedrawTrackerTests.swift
//  SwiftUIDiagnosticsKitTests
//

import XCTest
@testable import SwiftUIDiagnosticsKit

final class RedrawTrackerTests: XCTestCase {
    
    override func tearDown() async throws {
        await RedrawTracker.shared.reset()
    }
    
    func testRedrawCountIncrements() async throws {
        let id = "test-view-1"
        await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .unknown, parentId: nil)
        await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .stateChange, parentId: nil)
        let count = await RedrawTracker.shared.redrawCount(for: id)
        XCTAssertEqual(count, 2)
    }
    
    func testRedrawsPerSecond() async throws {
        let id = "test-view-2"
        for _ in 0..<5 {
            await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .unknown, parentId: nil)
        }
        let rps = await RedrawTracker.shared.redrawsPerSecond(for: id)
        XCTAssertGreaterThanOrEqual(rps, 0)
        let count = await RedrawTracker.shared.redrawCount(for: id)
        XCTAssertEqual(count, 5)
    }
    
    func testRecentCause() async throws {
        let id = "test-view-3"
        await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .bindingChange, parentId: nil)
        let cause = await RedrawTracker.shared.recentCauses(for: id)
        XCTAssertEqual(cause, .bindingChange)
    }
}
