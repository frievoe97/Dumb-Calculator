//
//  ContentView.swift
//  Dumb Calculator 2
//
//  Created by Friedrich Völkers on 21.01.25.
//

import SwiftUI

enum ColorScheme: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case system = "System"
}

struct ContentView: View {
    @AppStorage("colorScheme") private var colorScheme: ColorScheme = .system
    @AppStorage("isDumbMode") private var isDumbMode = false
    @State private var displayText = "0"
    @State private var currentNumber = ""
    @State private var currentOperation: String?
    @State private var previousNumber: Double?
    @State private var fullExpression = ""
    @State private var history: [String] = []
    @State private var isNewCalculation = false
    @State private var showingMenu = false
    @State private var showingAbout = false
    @State private var currentButtons: [[String]] = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["0", ",", "=", "+"]
    ]
    
    private let defaultButtons = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["0", ",", "=", "+"]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                // Menu Button
                MenuButton(showingMenu: $showingMenu, showingAbout: $showingAbout, isDumbMode: $isDumbMode, colorScheme: $colorScheme, onClearHistory: {
                    history.removeAll()
                })
                
                // History area
                VStack(spacing: 0) {
                    ScrollViewReader { proxy in
                        ScrollView(.vertical, showsIndicators: false) {
                            LazyVStack(alignment: .trailing, spacing: 8) {
                                Spacer() // Sorgt dafür, dass Inhalte am unteren Rand bleiben
                                ForEach(Array(history.enumerated()), id: \.element) { index, calculation in
                                    Text(calculation)
                                        .font(.system(size: 20))
                                        .foregroundColor(.gray)
                                        .frame(maxWidth: .infinity, alignment: .trailing)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: history) { _ in
                            // Automatisch nach unten scrollen, wenn neue Einträge hinzukommen
                            if let lastIndex = history.indices.last {
                                proxy.scrollTo(history[lastIndex], anchor: .bottom)
                            }
                        }
                    }
                }
                .frame(height: geometry.size.height * 0.3, alignment: .bottom)
                .clipped()

                
                // Display area
                Text(fullExpression.isEmpty ? displayText : fullExpression)
                    .font(.system(size: 70))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .padding()
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .onTapGesture(count: 2) {
                        resetCalculator()
                    }
                    .frame(height: geometry.size.height * 0.2) // Feste Höhe für die Display Area
                
                // Buttons area
                VStack(spacing: 0) {
                    ForEach(currentButtons, id: \.self) { row in
                        HStack(spacing: 0) {
                            ForEach(row, id: \.self) { button in
                                Button(action: {
                                    buttonPressed(button)
                                }) {
                                    Text(button)
                                        .font(.system(size: 32))
                                        .frame(width: geometry.size.width / 4,
                                            height: geometry.size.width / 4)
                                        .background(Color.orange)
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                }
                .frame(height: geometry.size.width) // Feste Höhe der Buttons
            }
        }
        .background(Color.black)
        .preferredColorScheme(colorScheme == .system ? nil : 
                            colorScheme == .dark ? .dark : .light)
    }

    func buttonPressed(_ button: String) {
        if isDumbMode {
            shuffleButtons()
        }
        
        switch button {
        case "0"..."9":
            if isNewCalculation {
                resetCalculator()
                isNewCalculation = false
            }
            if currentNumber == "0" {
                currentNumber = button
            } else {
                currentNumber += button
            }
            displayText = currentNumber
            updateFullExpression()
            
        case ",":
            if isNewCalculation {
                resetCalculator()
                isNewCalculation = false
            }
            if !currentNumber.contains(",") {
                currentNumber += currentNumber.isEmpty ? "0," : ","
                displayText = currentNumber
                updateFullExpression()
            }
            
        case "+", "-", "×", "÷":
            isNewCalculation = false
            if currentNumber.isEmpty && previousNumber == nil {
                previousNumber = 0
            } else if !currentNumber.isEmpty {
                if let number = Double(currentNumber.replacingOccurrences(of: ",", with: ".")) {
                    if let previous = previousNumber, let operation = currentOperation {
                        previousNumber = calculate(previous, number, operation)
                        displayText = formatNumber(previousNumber!)
                    } else {
                        previousNumber = number
                    }
                }
            }
            currentOperation = button
            currentNumber = ""
            updateFullExpression()
            
        case "=":
            if let number = Double(currentNumber.replacingOccurrences(of: ",", with: ".")),
               let previous = previousNumber,
               let operation = currentOperation {
                let result = calculate(previous, number, operation)
                let finalExpression = "\(fullExpression) = \(formatNumber(result))"
                history.append(finalExpression)
                displayText = formatNumber(result)
                fullExpression = ""
                previousNumber = result
                currentNumber = formatNumber(result)
                currentOperation = nil
                isNewCalculation = true
            }
        default:
            break
        }
    }
    
    func shuffleButtons() {
        var allButtons = currentButtons.joined().map { $0 }

        allButtons.shuffle()
        currentButtons = stride(from: 0, to: allButtons.count, by: 4).map {
            Array(allButtons[$0..<min($0 + 4, allButtons.count)])
        }
    }
    
    func resetCalculator() {
        displayText = "0"
        currentNumber = ""
        currentOperation = nil
        previousNumber = nil
        fullExpression = ""
        isNewCalculation = false
        currentButtons = defaultButtons
    }
    
    func updateFullExpression() {
        if let operation = currentOperation {
            fullExpression = "\(formatNumber(previousNumber!)) \(operation)\(currentNumber.isEmpty ? "" : " \(currentNumber)")"
        } else {
            fullExpression = currentNumber
        }
    }
    
    func calculate(_ a: Double, _ b: Double, _ operation: String) -> Double {
        if isDumbMode {
            // Occasionally make "mistakes" in dumb mode
            if Double.random(in: 0...1) < 0.2 {  // 20% chance of being dumb
                return Double.random(in: a-b...a+b)  // Return a random number around the actual result
            }
        }
        
        switch operation {
        case "+": return a + b
        case "-": return a - b
        case "×": return a * b
        case "÷": return b != 0 ? a / b : 0
        default: return 0
        }
    }
    
    func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 10
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

struct AboutView: View {
    var body: some View {
        NavigationView {
            List {
                Section {
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "calculator")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        Text("Dumb Calculator")
                            .font(.title2.bold())
                        Text("Version 1.0")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                }
                
                Section("About") {
                    Text("A simple calculator with a twist - it can be dumb sometimes!")
                        .padding(.vertical, 8)
                }
                
                Section("Links") {
                    Link(destination: URL(string: "https://github.com/yourusername/DumbCalculator")!) {
                        HStack {
                            Image(systemName: "github")
                            Text("View on GitHub")
                            Spacer()
                            Image(systemName: "arrow.up.right")
                        }
                    }
                }
                
                Section("License") {
                    Text("MIT License\n\nCopyright (c) 2024\n\nPermission is hereby granted, free of charge...")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("About")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}

extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}

struct MenuButton: View {
    @Binding var showingMenu: Bool
    @Binding var showingAbout: Bool
    @Binding var isDumbMode: Bool
    @Binding var colorScheme: ColorScheme
    let onClearHistory: () -> Void
    
    var body: some View {
        Button(action: { showingMenu = true }) {
            Image(systemName: "ellipsis")
                .foregroundColor(.gray.opacity(0.6))
                .font(.system(size: 20))
        }
        .padding(.top, 8)
        .confirmationDialog("Menu", isPresented: $showingMenu) {
            Button("Clear History", action: onClearHistory)
            Button(isDumbMode ? "Disable Dumb Mode" : "Enable Dumb Mode") {
                isDumbMode.toggle()
            }
            Button(colorScheme == .dark ? "Light Mode" : "Dark Mode") {
                colorScheme = colorScheme == .dark ? .light : .dark
            }
            Button("System Appearance") {
                colorScheme = .system
            }
            Button("About") {
                showingAbout = true
            }
            Button("Cancel", role: .cancel) { }
        }
        .sheet(isPresented: $showingAbout) {
            AboutView()
        }
    }
}

#Preview {
    ContentView()
}
