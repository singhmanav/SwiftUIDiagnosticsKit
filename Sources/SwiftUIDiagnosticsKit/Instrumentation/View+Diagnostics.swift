//
//  View+Diagnostics.swift
//  SwiftUIDiagnosticsKit
//
//  View modifier for redraw and layout instrumentation.
//

import SwiftUI

#if canImport(CoreGraphics)
import CoreGraphics
#endif

// MARK: - Public API

extension View {
    /// Enable diagnostics for this view: redraw counting, layout pass tracking, optional cause.
    /// No-op when Diagnostics is not active or tracking is disabled.
    public func enableDiagnostics() -> some View {
        modifier(DiagnosticsViewModifier())
    }
    
    /// One-call integration: starts diagnostics, shows a floating overlay, and enables console logging.
    /// Apply this to your **root view** inside WindowGroup:
    /// ```
    /// WindowGroup { ContentView().diagnosticsQuickStart() }
    /// ```
    /// - Parameters:
    ///   - showOverlay: Show the floating diagnostics overlay. Default true.
    ///   - logToConsole: Log events to Xcode console with `[SwiftUIDiagnostics]` prefix. Default true.
    ///   - config: Configuration. Default is `.default` (all tracking on).
    public func diagnosticsQuickStart(
        showOverlay: Bool = true,
        logToConsole: Bool = true,
        config: DiagnosticsConfiguration = .default
    ) -> some View {
        modifier(DiagnosticsQuickStartModifier(
            showOverlay: showOverlay,
            logToConsole: logToConsole,
            config: config
        ))
    }
}

/// Modifier that starts diagnostics on first appear and optionally shows the overlay.
private struct DiagnosticsQuickStartModifier: ViewModifier {
    let showOverlay: Bool
    let logToConsole: Bool
    let config: DiagnosticsConfiguration
    @State private var started = false
    
    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
            if showOverlay && started {
                DiagnosticsOverlayView()
                    .padding(12)
            }
        }
        .onAppear {
            guard !started else { return }
            started = true
            Diagnostics.quickStart(config: config, logToConsole: logToConsole)
        }
    }
}

// MARK: - PreferenceKey for layout

struct LayoutDiagnosticsPreferenceKey: PreferenceKey {
    static var defaultValue: [LayoutDiagnosticsItem] { [] }
    static func reduce(value: inout [LayoutDiagnosticsItem], nextValue: () -> [LayoutDiagnosticsItem]) {
        value.append(contentsOf: nextValue())
    }
}

struct LayoutDiagnosticsItem: Equatable {
    let viewId: String
    let size: CGSize
}

// MARK: - Modifier

struct DiagnosticsViewModifier: ViewModifier {
    @State private var viewId: String = ""
    @State private var bodyCount: Int = 0
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { geo in
                    Color.clear
                        .preference(key: LayoutDiagnosticsPreferenceKey.self, value: [LayoutDiagnosticsItem(viewId: viewId, size: geo.size)])
                }
            )
            .onPreferenceChange(LayoutDiagnosticsPreferenceKey.self) { items in
                guard let item = items.first(where: { $0.viewId == viewId }) else { return }
                Task {
                    await LayoutAnalyzer.shared.recordLayoutPass(viewId: viewId, size: item.size)
                    let config = Diagnostics.currentConfiguration
                    if config.enableLayoutTracking {
                        let warnings = await LayoutAnalyzer.shared.warnings(for: viewId)
                        if !warnings.isEmpty {
                            for w in warnings {
                                await MetricsStore.shared.add(DiagnosticEvent(kind: .layoutWarning, viewId: w.viewId, message: w.message))
                            }
                        }
                    }
                }
            }
            .modifier(RedrawTrackingModifier(viewId: $viewId, bodyCount: $bodyCount))
    }
}

/// Inner modifier that assigns stable ID and records body invocations.
private struct RedrawTrackingModifier: ViewModifier {
    @Binding var viewId: String
    @Binding var bodyCount: Int
    
    func body(content: Content) -> some View {
        let _ = recordRedraw()
        return content
            .onAppear {
                if viewId.isEmpty {
                    viewId = UUID().uuidString
                }
            }
    }
    
    private func recordRedraw() {
        guard Diagnostics.isActive, Diagnostics.currentConfiguration.enableRedrawTracking else { return }
        let id = viewId.isEmpty ? "pending-\(bodyCount)" : viewId
        bodyCount += 1
        Task {
            await RedrawTracker.shared.recordBodyInvocation(viewId: id, cause: .unknown, parentId: nil)
            let rps = await RedrawTracker.shared.redrawsPerSecond(for: id)
            let threshold = Diagnostics.currentConfiguration.redrawThresholdPerSecond
            if rps >= Double(threshold) {
                await MetricsStore.shared.add(DiagnosticEvent(kind: .redrawBreach, viewId: id, message: "Redraws/sec: \(rps) >= \(threshold)", payload: ["rps": "\(rps)"]))
            }
        }
    }
}

