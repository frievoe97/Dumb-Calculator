//
//  ContentView.swift
//  Dumb Calculator 2
//
//  Created by Friedrich Völkers on 21.01.25.
//

import SwiftUI

struct ContentView: View {
    @State private var displayText = "0"
    @State private var currentNumber = ""
    @State private var currentOperation: String?
    @State private var previousNumber: Double?
    @State private var fullExpression = ""
    @State private var history: [String] = []
    @State private var isNewCalculation = false
    
    let buttons: [[String]] = [
        ["7", "8", "9", "÷"],
        ["4", "5", "6", "×"],
        ["1", "2", "3", "-"],
        ["0", ",", "=", "+"]
    ]
    
    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 0) {
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
                    ForEach(buttons, id: \.self) { row in
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
    }

     

    
    func buttonPressed(_ button: String) {
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
    
    func resetCalculator() {
        displayText = "0"
        currentNumber = ""
        currentOperation = nil
        previousNumber = nil
        fullExpression = ""
        isNewCalculation = false
    }
    
    func updateFullExpression() {
        if let operation = currentOperation {
            fullExpression = "\(formatNumber(previousNumber!)) \(operation)\(currentNumber.isEmpty ? "" : " \(currentNumber)")"
        } else {
            fullExpression = currentNumber
        }
    }
    
    func calculate(_ a: Double, _ b: Double, _ operation: String) -> Double {
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

#Preview {
    ContentView()
}
