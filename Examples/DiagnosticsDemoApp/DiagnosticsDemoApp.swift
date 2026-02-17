//
//  DiagnosticsDemoApp.swift
//  DiagnosticsDemoApp
//
//  Sample SwiftUI app that integrates SwiftUIDiagnosticsKit with one call.
//  Add SwiftUIDiagnosticsKit as a local or remote package dependency, then use this as your App entry.
//

import SwiftUI
import SwiftUIDiagnosticsKit

@main
struct DiagnosticsDemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .diagnosticsQuickStart()
        }
    }
}
