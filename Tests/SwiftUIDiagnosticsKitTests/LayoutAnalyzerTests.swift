//
//  LayoutAnalyzerTests.swift
//  SwiftUIDiagnosticsKitTests
//

import XCTest
@testable import SwiftUIDiagnosticsKit

final class LayoutAnalyzerTests: XCTestCase {
    
    override func tearDown() async throws {
        await LayoutAnalyzer.shared.reset()
    }
    
    func testLayoutPassCount() async throws {
        let id = "layout-view-1"
        await LayoutAnalyzer.shared.recordLayoutPass(viewId: id, size: LayoutSize(width: 100, height: 50))
        await LayoutAnalyzer.shared.recordLayoutPass(viewId: id, size: LayoutSize(width: 100, height: 50))
        let count = await LayoutAnalyzer.shared.layoutPassCount(for: id)
        XCTAssertEqual(count, 2)
    }
    
    func testOscillationDetection() async throws {
        let id = "layout-view-2"
        let sizes: [LayoutSize] = [
            LayoutSize(width: 100, height: 50),
            LayoutSize(width: 200, height: 100),
            LayoutSize(width: 100, height: 50),
            LayoutSize(width: 200, height: 100)
        ]
        for s in sizes {
            await LayoutAnalyzer.shared.recordLayoutPass(viewId: id, size: s)
        }
        let oscillating = await LayoutAnalyzer.shared.detectOscillation(viewId: id)
        XCTAssertTrue(oscillating)
    }
    
    func testWarningsOverThreshold() async throws {
        let id = "layout-view-3"
        for i in 0..<25 {
            await LayoutAnalyzer.shared.recordLayoutPass(viewId: id, size: LayoutSize(width: CGFloat(i), height: 50))
        }
        let warnings = await LayoutAnalyzer.shared.warnings(for: id)
        XCTAssertFalse(warnings.isEmpty)
    }
}
