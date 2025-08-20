//
//  SettingsView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var storeManager: StoreManager
    @AppStorage("isPasscodeEnabled") private var isPasscodeEnabled = false
    @AppStorage("passcode") private var savedPasscode = ""
    @State private var showingPasscodeSetup = false
    @State private var showingCustomQuestions = false
    @State private var showingPaywall = false
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var showPasscodeError = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        ZStack {
            paperColor
                .ignoresSafeArea()
            
            List {
                // Premium Features Section
                Section {
                    if storeManager.isSubscribed {
                        // Passcode Protection
                        Toggle(isOn: $isPasscodeEnabled) {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Passcode Protection")
                                        .font(.custom("Noteworthy-Bold", size: 16))
                                    Text("Secure your journal with a passcode")
                                        .font(.custom("Noteworthy-Light", size: 12))
                                        .foregroundColor(inkColor.opacity(0.6))
                                }
                            } icon: {
                                Image(systemName: "lock.fill")
                                    .foregroundColor(accentColor)
                            }
                        }
                        .onChange(of: isPasscodeEnabled) { _, newValue in
                            if newValue {
                                showingPasscodeSetup = true
                            } else {
                                savedPasscode = ""
                            }
                        }
                        
                        // Custom Questions
                        Button(action: { showingCustomQuestions = true }) {
                            Label {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Custom Questions")
                                        .font(.custom("Noteworthy-Bold", size: 16))
                                    Text("Add your own reflection questions")
                                        .font(.custom("Noteworthy-Light", size: 12))
                                        .foregroundColor(inkColor.opacity(0.6))
                                }
                            } icon: {
                                Image(systemName: "pencil.circle.fill")
                                    .foregroundColor(accentColor)
                            }
                        }
                        .foregroundColor(inkColor)
                    } else {
                        // Premium Upsell
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Premium Features", systemImage: "crown.fill")
                                .font(.custom("Noteworthy-Bold", size: 18))
                                .foregroundColor(.yellow)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                SettingsFeatureRow(icon: "lock.fill", text: "Passcode Protection")
                                SettingsFeatureRow(icon: "pencil.circle.fill", text: "Custom Questions")
                                SettingsFeatureRow(icon: "flame.fill", text: "Streak Tracking")
                            }
                            
                            Button(action: { showingPaywall = true }) {
                                Text("Upgrade to Premium")
                                    .font(.custom("Noteworthy-Bold", size: 16))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .cornerRadius(10)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                } header: {
                    Text(storeManager.isSubscribed ? "Premium Features" : "Unlock Premium")
                        .font(.custom("Noteworthy-Light", size: 14))
                }
                .listRowBackground(Color.white.opacity(0.5))
                
                // About Section
                Section {
                    HStack {
                        Text("Version")
                            .font(.custom("Noteworthy-Light", size: 16))
                        Spacer()
                        Text("1.0.0")
                            .font(.custom("Noteworthy-Light", size: 16))
                            .foregroundColor(inkColor.opacity(0.6))
                    }
                    
                    Link(destination: URL(string: "https://example.com/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                                .font(.custom("Noteworthy-Light", size: 16))
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor)
                        }
                    }
                    .foregroundColor(inkColor)
                    
                    Link(destination: URL(string: "https://example.com/terms")!) {
                        HStack {
                            Text("Terms of Service")
                                .font(.custom("Noteworthy-Light", size: 16))
                            Spacer()
                            Image(systemName: "arrow.up.right.square")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor)
                        }
                    }
                    .foregroundColor(inkColor)
                } header: {
                    Text("About")
                        .font(.custom("Noteworthy-Light", size: 14))
                }
                .listRowBackground(Color.white.opacity(0.5))
                
                // Support Section
                Section {
                    Button(action: { }) {
                        HStack {
                            Text("Contact Support")
                                .font(.custom("Noteworthy-Light", size: 16))
                            Spacer()
                            Image(systemName: "envelope")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor)
                        }
                    }
                    .foregroundColor(inkColor)
                    
                    Button(action: { }) {
                        HStack {
                            Text("Rate App")
                                .font(.custom("Noteworthy-Light", size: 16))
                            Spacer()
                            Image(systemName: "star")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor)
                        }
                    }
                    .foregroundColor(inkColor)
                } header: {
                    Text("Support")
                        .font(.custom("Noteworthy-Light", size: 14))
                }
                .listRowBackground(Color.white.opacity(0.5))
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showingPasscodeSetup) {
            PasscodeSetupView(
                isPresented: $showingPasscodeSetup,
                isPasscodeEnabled: $isPasscodeEnabled,
                savedPasscode: $savedPasscode
            )
        }
        .sheet(isPresented: $showingCustomQuestions) {
            CustomQuestionsView()
                .environmentObject(storeManager)
        }
        .sheet(isPresented: $showingPaywall) {
            PaywallView(isPresented: $showingPaywall)
                .environmentObject(storeManager)
        }
    }
}

struct SettingsFeatureRow: View {
    let icon: String
    let text: String
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(inkColor)
        }
    }
}

struct PasscodeSetupView: View {
    @Binding var isPresented: Bool
    @Binding var isPasscodeEnabled: Bool
    @Binding var savedPasscode: String
    @State private var passcode = ""
    @State private var confirmPasscode = ""
    @State private var showError = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(accentColor)
                        .padding(.top, 40)
                    
                    Text("Set Your Passcode")
                        .font(.custom("Noteworthy-Bold", size: 24))
                        .foregroundColor(inkColor)
                    
                    VStack(spacing: 20) {
                        SecureField("Enter 4-digit passcode", text: $passcode)
                            .font(.custom("Noteworthy-Light", size: 18))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: passcode) { _, newValue in
                                if newValue.count > 4 {
                                    passcode = String(newValue.prefix(4))
                                }
                            }
                        
                        SecureField("Confirm passcode", text: $confirmPasscode)
                            .font(.custom("Noteworthy-Light", size: 18))
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.numberPad)
                            .onChange(of: confirmPasscode) { _, newValue in
                                if newValue.count > 4 {
                                    confirmPasscode = String(newValue.prefix(4))
                                }
                            }
                    }
                    .padding(.horizontal, 40)
                    
                    if showError {
                        Text("Passcodes don't match")
                            .font(.custom("Noteworthy-Light", size: 14))
                            .foregroundColor(.red)
                    }
                    
                    Spacer()
                    
                    Button(action: savePasscode) {
                        Text("Save Passcode")
                            .font(.custom("Noteworthy-Bold", size: 18))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(accentColor)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                    .disabled(passcode.count != 4 || confirmPasscode.count != 4)
                }
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPasscodeEnabled = false
                    isPresented = false
                }
            )
        }
    }
    
    private func savePasscode() {
        if passcode == confirmPasscode && passcode.count == 4 {
            savedPasscode = passcode
            isPresented = false
        } else {
            showError = true
        }
    }
}

struct CustomQuestionsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager
    @State private var customQuestions: [String] = UserDefaults.standard.stringArray(forKey: "customQuestions") ?? []
    @State private var newQuestion = ""
    @State private var showingAddQuestion = false
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                List {
                    Section {
                        if customQuestions.isEmpty {
                            Text("No custom questions yet")
                                .font(.custom("Noteworthy-Light", size: 16))
                                .foregroundColor(inkColor.opacity(0.6))
                                .padding(.vertical, 20)
                        } else {
                            ForEach(customQuestions, id: \.self) { question in
                                Text(question)
                                    .font(.custom("Noteworthy-Light", size: 16))
                                    .foregroundColor(inkColor)
                                    .padding(.vertical, 4)
                            }
                            .onDelete(perform: deleteQuestion)
                        }
                    } header: {
                        Text("Your Custom Questions")
                            .font(.custom("Noteworthy-Light", size: 14))
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                    
                    Section {
                        Button(action: { showingAddQuestion = true }) {
                            Label("Add New Question", systemImage: "plus.circle.fill")
                                .font(.custom("Noteworthy-Bold", size: 16))
                                .foregroundColor(accentColor)
                        }
                    }
                    .listRowBackground(Color.white.opacity(0.5))
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Custom Questions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .alert("Add Custom Question", isPresented: $showingAddQuestion) {
                TextField("Enter your question", text: $newQuestion)
                    .textInputAutocapitalization(.sentences)
                
                Button("Cancel", role: .cancel) {
                    newQuestion = ""
                }
                
                Button("Add") {
                    if !newQuestion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        customQuestions.append(newQuestion)
                        UserDefaults.standard.set(customQuestions, forKey: "customQuestions")
                        newQuestion = ""
                    }
                }
            }
        }
    }
    
    private func deleteQuestion(at offsets: IndexSet) {
        customQuestions.remove(atOffsets: offsets)
        UserDefaults.standard.set(customQuestions, forKey: "customQuestions")
    }
}