//
//  StateMonitorTests.swift
//  SwiftUIDiagnosticsKitTests
//

import XCTest
@testable import SwiftUIDiagnosticsKit

final class StateMonitorTests: XCTestCase {
    
    override func tearDown() async throws {
        await StateMonitor.shared.reset()
    }
    
    func testRecordChange() async throws {
        await StateMonitor.shared.recordChange(viewId: "v1", key: "count", old: "0", new: "1", isOnMainActor: true)
        await StateMonitor.shared.recordChange(viewId: "v1", key: "count", old: "1", new: "2", isOnMainActor: true)
        let redundant = await StateMonitor.shared.redundantUpdateCount(for: "v1")
        XCTAssertEqual(redundant, 0)
    }
    
    func testRedundantUpdate() async throws {
        await StateMonitor.shared.recordChange(viewId: "v2", key: "x", old: "same", new: "same", isOnMainActor: true)
        let redundant = await StateMonitor.shared.redundantUpdateCount(for: "v2")
        XCTAssertEqual(redundant, 1)
    }
    
    func testMainActorViolation() async throws {
        await StateMonitor.shared.recordChange(viewId: "v3", key: nil, old: nil, new: nil, isOnMainActor: false)
        let violations = await StateMonitor.shared.violationsList()
        XCTAssertFalse(violations.isEmpty)
    }
}
