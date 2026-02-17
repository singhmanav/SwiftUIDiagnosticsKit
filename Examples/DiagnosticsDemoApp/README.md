# Diagnostics Demo App

This folder contains sample code for integrating **SwiftUIDiagnosticsKit** into a SwiftUI app.

## How to use

1. Create a new **SwiftUI App** in Xcode (File → New → Project → App).
2. Add the **SwiftUIDiagnosticsKit** package:
   - File → Add Package Dependencies
   - Enter the package URL or add a local path to the parent `SwiftUIDiagnosticsKit` package.
3. Replace your `*App.swift` content with `DiagnosticsDemoApp.swift` (adjust the struct name if needed).
4. Replace or add a view with `ContentView.swift` content.
5. Build and run in **Debug**. Start diagnostics and use the overlay and export buttons.

## What it demonstrates

- `Diagnostics.start(config: .default)` in the App initializer.
- `.enableDiagnostics()` on multiple views.
- `DiagnosticsOverlayView()` in an overlay.
- Exporting metrics via `Diagnostics.exportMetrics()`.
- A “redraw storm” button to trigger many updates and test threshold breach.

The demo app is **reference only**; it is not a separate Swift Package so you can copy the files into your own app target.
