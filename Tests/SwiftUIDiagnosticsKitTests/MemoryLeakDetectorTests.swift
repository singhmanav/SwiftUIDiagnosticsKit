//
//  MemoryLeakDetectorTests.swift
//  SwiftUIDiagnosticsKitTests
//

import XCTest
@testable import SwiftUIDiagnosticsKit

final class MemoryLeakDetectorTests: XCTestCase {
    
    override func tearDown() async throws {
        await MemoryLeakDetector.shared.reset()
    }
    
    func testRegisterUnregister() async throws {
        let obj = NSObject()
        await MemoryLeakDetector.shared.register(object: obj)
        var count = await MemoryLeakDetector.shared.registeredCount()
        XCTAssertEqual(count, 1)
        await MemoryLeakDetector.shared.unregister(object: obj)
        count = await MemoryLeakDetector.shared.registeredCount()
        XCTAssertEqual(count, 0)
    }
    
    func testSuspectedLeaksAfterTimeout() async throws {
        let obj = NSObject()
        let past = Date().addingTimeInterval(-20)
        await MemoryLeakDetector.shared.register(object: obj, expectedDeallocAfter: past)
        let leaks = await MemoryLeakDetector.shared.suspectedLeaks(leakTimeout: 10)
        XCTAssertFalse(leaks.isEmpty)
        await MemoryLeakDetector.shared.unregister(object: obj)
    }
    
    func testResetClears() async throws {
        let obj = NSObject()
        await MemoryLeakDetector.shared.register(object: obj)
        await MemoryLeakDetector.shared.reset()
        let count = await MemoryLeakDetector.shared.registeredCount()
        XCTAssertEqual(count, 0)
    }
}
