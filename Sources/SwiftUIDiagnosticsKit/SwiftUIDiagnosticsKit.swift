//
//  SwiftUIDiagnosticsKit.swift
//  SwiftUIDiagnosticsKit
//
//  Production-ready SwiftUI diagnostics: redraws, layout, memory, state, concurrency, performance.
//

import SwiftUI
import Foundation

// Public API is provided by:
// - DiagnosticsConfiguration, Diagnostics (Config/)
// - View.enableDiagnostics() (Instrumentation/View+Diagnostics)
// - DiagnosticsOverlay(), RedrawHeatmapView, LayoutWarningView (Overlay/)
// - Core trackers are used internally; overlay and export expose aggregated data.
