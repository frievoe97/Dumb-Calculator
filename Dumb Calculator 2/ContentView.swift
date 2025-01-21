//
//  ContentView.swift
//  Dumb Calculator 2
//
//  Created by Friedrich Völkers on 21.01.25.
//

import SwiftUI

// MARK: - Models & Enums

enum AppearanceMode: String, CaseIterable {
    case dark = "Dark"
    case light = "Light"
    case system = "System"
}

enum CalculatorButton {
    case number(String)
    case operation(String)
    case decimal
    case equals
    
    var displayValue: String {
        switch self {
        case .number(let value): return value
        case .operation(let symbol): return symbol
        case .decimal: return ","
        case .equals: return "="
        }
    }
}

// MARK: - Main View

struct ContentView: View {
    // MARK: - Properties
    
    @AppStorage("appearanceMode") private var appearanceMode: AppearanceMode = .system
    @AppStorage("isDumbMode") private var isDumbMode = false
    
    @State private var display = CalculatorDisplay()
    @State private var history: [String] = []
    @State private var currentButtons: [[String]]
    @State private var showingMenu = false
    @State private var showingAbout = false
    
    private let defaultButtons: [[String]] = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["0", ",", "=", "+"]
    ]
    
    // MARK: - Initialization
    
    init() {
        _currentButtons = State(initialValue: [
            ["7", "8", "9", "÷"],
            ["4", "5", "6", "×"],
            ["1", "2", "3", "-"],
            ["0", ",", "=", "+"]
        ])
    }
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
                menuButton
                historyView(height: geometry.size.height * 0.3)
                displayView(height: geometry.size.height * 0.2)
                buttonGrid(width: geometry.size.width)
            }
        }
        .background(Color.black)
        .preferredColorScheme(appearanceMode.systemAppearance)
    }
    
    // MARK: - Subviews
    
    private var menuButton: some View {
        MenuButton(
            showingMenu: $showingMenu,
            showingAbout: $showingAbout,
            isDumbMode: $isDumbMode,
            appearanceMode: $appearanceMode,
            onClearHistory: { history.removeAll() }
        )
    }
    
    private func historyView(height: CGFloat) -> some View {
        CalculatorHistoryView(history: history, height: height)
    }
    
    private func displayView(height: CGFloat) -> some View {
        CalculatorDisplayView(
            text: display.currentDisplay,
            height: height,
            onDoubleTap: resetCalculator
        )
    }
    
    private func buttonGrid(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(currentButtons, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(row, id: \.self) { button in
                        CalculatorButtonView(
                            symbol: button,
                            size: width / 4,
                            action: { buttonPressed(button) }
                        )
                    }
                }
            }
        }
        .frame(height: width)
    }
    
    // MARK: - Actions
    
    private func buttonPressed(_ button: String) {
        if isDumbMode {
            shuffleButtons()
        }
        
        display.processInput(button) { result in
            if let result = result {
                history.append("\(display.currentExpression) = \(result)")
            }
        }
    }
    
    private func shuffleButtons() {
        var allButtons = currentButtons.joined().map { $0 }
        allButtons.shuffle()
        currentButtons = stride(from: 0, to: allButtons.count, by: 4).map {
            Array(allButtons[$0..<min($0 + 4, allButtons.count)])
        }
    }
    
    private func resetCalculator() {
        display.reset()
        currentButtons = defaultButtons
    }
}

// MARK: - Supporting Types

struct CalculatorDisplay {
    private(set) var currentDisplay = "0"
    private(set) var currentExpression = ""
    private var currentNumber = ""
    private var currentOperation: String?
    private var previousNumber: Double?
    private var isNewCalculation = false
    
    mutating func reset() {
        currentDisplay = "0"
        currentExpression = ""
        currentNumber = ""
        currentOperation = nil
        previousNumber = nil
        isNewCalculation = false
    }
    
    mutating func processInput(_ button: String, onResult: (String?) -> Void) {
        switch button {
        case "0"..."9":
            if isNewCalculation {
                reset()
                isNewCalculation = false
            }
            if currentNumber == "0" {
                currentNumber = button
            } else {
                currentNumber += button
            }
            currentDisplay = currentNumber
            updateExpression()
            
        case ",":
            if isNewCalculation {
                reset()
                isNewCalculation = false
            }
            if !currentNumber.contains(",") {
                currentNumber += currentNumber.isEmpty ? "0," : ","
                currentDisplay = currentNumber
                updateExpression()
            }
            
        case "+", "-", "×", "÷":
            isNewCalculation = false
            if currentNumber.isEmpty && previousNumber == nil {
                previousNumber = 0
            } else if !currentNumber.isEmpty {
                if let number = Double(currentNumber.replacingOccurrences(of: ",", with: ".")) {
                    if let previous = previousNumber, let operation = currentOperation {
                        previousNumber = calculate(previous, number, operation)
                        currentDisplay = formatNumber(previousNumber!)
                    } else {
                        previousNumber = number
                    }
                }
            }
            currentOperation = button
            currentNumber = ""
            updateExpression()
            
        case "=":
            if let number = Double(currentNumber.replacingOccurrences(of: ",", with: ".")),
               let previous = previousNumber,
               let operation = currentOperation {
                let result = calculate(previous, number, operation)
                currentDisplay = formatNumber(result)
                onResult(currentDisplay)
                previousNumber = result
                currentNumber = formatNumber(result)
                currentOperation = nil
                isNewCalculation = true
            }
        default:
            break
        }
    }
    
    private mutating func updateExpression() {
        if let operation = currentOperation {
            currentExpression = "\(formatNumber(previousNumber!)) \(operation)\(currentNumber.isEmpty ? "" : " \(currentNumber)")"
        } else {
            currentExpression = currentNumber
        }
    }
    
    private func calculate(_ a: Double, _ b: Double, _ operation: String) -> Double {
        switch operation {
        case "+": return a + b
        case "-": return a - b
        case "×": return a * b
        case "÷": return b != 0 ? a / b : 0
        default: return 0
        }
    }
    
    private func formatNumber(_ number: Double) -> String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 10
        formatter.decimalSeparator = ","
        return formatter.string(from: NSNumber(value: number)) ?? "0"
    }
}

// MARK: - Supporting Views

struct CalculatorHistoryView: View {
    let history: [String]
    let height: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .trailing, spacing: 8) {
                    ForEach(Array(history.enumerated()), id: \.element) { index, calculation in
                        Text(calculation)
                            .font(.system(size: 20))
                            .foregroundColor(.gray)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    Spacer(minLength: 0)
                }
                .padding()
            }
        }
        .frame(height: height, alignment: .bottom)
        .clipped()
    }
}

struct CalculatorDisplayView: View {
    let text: String
    let height: CGFloat
    let onDoubleTap: () -> Void
    
    var body: some View {
        Text(text)
            .font(.system(size: 70))
            .minimumScaleFactor(0.5)
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .frame(height: height)
            .padding()
            .foregroundColor(.white)
            .textSelection(.enabled)
            .onTapGesture(count: 2, perform: onDoubleTap)
    }
}

struct CalculatorButtonView: View {
    let symbol: String
    let size: CGFloat
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(symbol)
                .font(.system(size: 32))
                .frame(width: size, height: size)
                .background(Color.orange)
                .foregroundColor(.white)
        }
    }
}

// MARK: - Extensions

extension AppearanceMode {
    var systemAppearance: ColorScheme? {
        switch self {
        case .dark: return .dark
        case .light: return .light
        case .system: return nil
        }
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
    @Binding var appearanceMode: AppearanceMode
    let onClearHistory: () -> Void
    
    var body: some View {
        Button(action: { showingMenu.toggle() }) {
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
            Button(appearanceMode == .dark ? "Light Mode" : "Dark Mode") {
                appearanceMode = appearanceMode == .dark ? .light : .dark
            }
            Button("System Appearance") {
                appearanceMode = .system
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
