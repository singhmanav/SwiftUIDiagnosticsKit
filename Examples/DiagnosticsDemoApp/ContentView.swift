//
//  ContentView.swift
//  DiagnosticsDemoApp
//
//  Demonstrates enableDiagnostics() and intentional redraw storm for testing.
//

import SwiftUI
import SwiftUIDiagnosticsKit

struct ContentView: View {
    @State private var counter = 0
    @State private var trigger = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("SwiftUIDiagnosticsKit Demo")
                .font(.title)
            
            Text("Counter: \(counter)")
                .enableDiagnostics()
                .font(.title2)
            
            Button("Increment") { counter += 1 }
                .enableDiagnostics()
            
            Button("Trigger redraw storm (10 updates)") {
                for i in 1...10 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * 0.05) {
                        counter += 1
                    }
                }
            }
            .enableDiagnostics()
            
            HStack {
                ChildView(label: "A")
                ChildView(label: "B")
            }
            .enableDiagnostics()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ChildView: View {
    let label: String
    @State private var localCount = 0
    
    var body: some View {
        VStack {
            Text("Child \(label): \(localCount)")
                .enableDiagnostics()
            Button("+") { localCount += 1 }
                .enableDiagnostics()
        }
        .padding()
        .background(Color(white: 0.95))
        .cornerRadius(8)
    }
}

#Preview {
    ContentView()
}
