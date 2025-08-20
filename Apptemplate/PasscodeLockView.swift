//
//  PasscodeLockView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import LocalAuthentication

struct PasscodeLockView: View {
    @Binding var isUnlocked: Bool
    let savedPasscode: String
    @State private var enteredPasscode = ""
    @State private var showError = false
    @State private var attempts = 0
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        ZStack {
            paperColor
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                VStack(spacing: 20) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(accentColor)
                    
                    Text("Enter Passcode")
                        .font(.custom("Noteworthy-Bold", size: 24))
                        .foregroundColor(inkColor)
                    
                    HStack(spacing: 15) {
                        ForEach(0..<4, id: \.self) { index in
                            Circle()
                                .fill(index < enteredPasscode.count ? inkColor : Color.gray.opacity(0.3))
                                .frame(width: 15, height: 15)
                        }
                    }
                    
                    if showError {
                        Text("Incorrect passcode")
                            .font(.custom("Noteworthy-Light", size: 14))
                            .foregroundColor(.red)
                    }
                }
                
                Spacer()
                
                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 20) {
                    ForEach(1...9, id: \.self) { number in
                        NumberButton(number: "\(number)") {
                            addNumber("\(number)")
                        }
                    }
                    
                    // Face ID / Touch ID button
                    Button(action: authenticateWithBiometrics) {
                        Image(systemName: "faceid")
                            .font(.system(size: 30))
                            .foregroundColor(accentColor)
                            .frame(width: 70, height: 70)
                    }
                    
                    NumberButton(number: "0") {
                        addNumber("0")
                    }
                    
                    Button(action: deleteNumber) {
                        Image(systemName: "delete.left.fill")
                            .font(.system(size: 24))
                            .foregroundColor(inkColor)
                            .frame(width: 70, height: 70)
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            authenticateWithBiometrics()
        }
    }
    
    private func addNumber(_ number: String) {
        if enteredPasscode.count < 4 {
            enteredPasscode += number
            
            if enteredPasscode.count == 4 {
                checkPasscode()
            }
        }
    }
    
    private func deleteNumber() {
        if !enteredPasscode.isEmpty {
            enteredPasscode.removeLast()
        }
        showError = false
    }
    
    private func checkPasscode() {
        if enteredPasscode == savedPasscode {
            withAnimation {
                isUnlocked = true
            }
        } else {
            withAnimation {
                showError = true
                attempts += 1
            }
            
            // Clear after wrong attempt
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                enteredPasscode = ""
            }
        }
    }
    
    private func authenticateWithBiometrics() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Unlock your journal"
            
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, _ in
                DispatchQueue.main.async {
                    if success {
                        isUnlocked = true
                    }
                }
            }
        }
    }
}

struct NumberButton: View {
    let number: String
    let action: () -> Void
    
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    
    var body: some View {
        Button(action: action) {
            Text(number)
                .font(.custom("Noteworthy-Bold", size: 24))
                .foregroundColor(inkColor)
                .frame(width: 70, height: 70)
                .background(Color.white.opacity(0.5))
                .cornerRadius(35)
        }
    }
}