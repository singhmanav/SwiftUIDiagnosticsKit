//
//  ObservableObject+Tracking.swift
//  SwiftUIDiagnosticsKit
//
//  Optional tracking for ObservableObject: state changes and leak registration.
//

import Foundation
import Combine

/// A wrapper that tracks an ObservableObject for diagnostics: objectWillChange and deinit.
public final class DiagnosticsObservableObject<Wrapped: ObservableObject>: ObservableObject where Wrapped: AnyObject {
    public let wrapped: Wrapped
    private let viewId: String
    private var cancellables = Set<AnyCancellable>()
    
    public init(wrapped: Wrapped, viewId: String = "") {
        self.wrapped = wrapped
        self.viewId = viewId.isEmpty ? String(describing: type(of: wrapped)) : viewId
        if Diagnostics.isActive, Diagnostics.currentConfiguration.enableMemoryTracking {
            Task {
                await MemoryLeakDetector.shared.register(object: wrapped, expectedDeallocAfter: nil)
            }
        }
        if Diagnostics.isActive, Diagnostics.currentConfiguration.enableStateTracking {
            wrapped.objectWillChange
                .sink { [weak self] _ in
                    guard let self = self else { return }
                    let onMain = Thread.isMainThread
                    Task {
                        await StateMonitor.shared.recordChange(viewId: self.viewId, key: nil, old: nil, new: nil, isOnMainActor: onMain)
                    }
                }
                .store(in: &cancellables)
        }
    }
    
    deinit {
        if Diagnostics.isActive {
            let obj = wrapped
            Task {
                await MemoryLeakDetector.shared.unregister(object: obj)
            }
        }
    }
}

extension ObservableObject where Self: AnyObject {
    /// Wrap this object for diagnostics (state and leak tracking). Use when you want diagnostics on a specific ViewModel.
    public func withDiagnostics(viewId: String = "") -> DiagnosticsObservableObject<Self> {
        DiagnosticsObservableObject(wrapped: self, viewId: viewId)
    }
}
