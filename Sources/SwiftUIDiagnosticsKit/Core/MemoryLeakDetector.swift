//
//  MemoryLeakDetector.swift
//  SwiftUIDiagnosticsKit
//
//  Tracks registered objects via weak refs; flags suspected leaks after timeout.
//

import Foundation

public struct SuspectedLeak: Sendable {
    public let objectId: String
    public let registeredAt: Date
    public let message: String
}

/// Holds a weak reference to an object. Used so the registry does not retain tracked objects.
final class WeakRef<T: AnyObject>: @unchecked Sendable {
    weak var value: T?
    init(_ value: T) { self.value = value }
}

actor MemoryLeakDetector {
    static let shared = MemoryLeakDetector()
    
    private struct Registration {
        let objectId: String
        let registeredAt: Date
        var expectedDeallocAfter: Date?
        let weakRef: WeakRef<AnyObject>
    }
    
    private var registrations: [String: Registration] = [:]
    
    private init() {}
    
    func register(object: AnyObject, expectedDeallocAfter: Date? = nil) {
        let id = ObjectIdentifier(object).debugDescription
        registrations[id] = Registration(
            objectId: id,
            registeredAt: Date(),
            expectedDeallocAfter: expectedDeallocAfter,
            weakRef: WeakRef(object as AnyObject)
        )
    }
    
    func unregister(object: AnyObject) {
        let id = ObjectIdentifier(object).debugDescription
        registrations.removeValue(forKey: id)
    }
    
    func recordDeinit(objectId: String) {
        registrations.removeValue(forKey: objectId)
    }
    
    func suspectedLeaks(leakTimeout: TimeInterval) -> [SuspectedLeak] {
        let now = Date()
        var result: [SuspectedLeak] = []
        var toRemove: [String] = []
        for (id, reg) in registrations {
            if reg.weakRef.value == nil {
                toRemove.append(id)
                continue
            }
            let deadline = reg.expectedDeallocAfter ?? reg.registeredAt.addingTimeInterval(leakTimeout)
            if now > deadline {
                result.append(SuspectedLeak(objectId: id, registeredAt: reg.registeredAt, message: "Object still alive after timeout"))
            }
        }
        for id in toRemove { registrations.removeValue(forKey: id) }
        return result
    }
    
    func registeredCount() -> Int {
        registrations.count
    }
    
    func reset() {
        registrations.removeAll()
    }
}
