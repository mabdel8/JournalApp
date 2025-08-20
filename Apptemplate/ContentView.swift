//
//  ContentView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var storeManager: StoreManager
    @Environment(\.modelContext) private var modelContext
    @AppStorage("isPasscodeEnabled") private var isPasscodeEnabled = false
    @AppStorage("passcode") private var savedPasscode = ""
    @State private var showPaywall = false
    @State private var isUnlocked = false
    @State private var showPasscodeScreen = false
    
    var body: some View {
        Group {
            if isPasscodeEnabled && !isUnlocked && !savedPasscode.isEmpty {
                PasscodeLockView(isUnlocked: $isUnlocked, savedPasscode: savedPasscode)
            } else {
                JournalHomeView()
                    .environmentObject(storeManager)
                    .modelContainer(for: JournalEntry.self)
            }
        }
        .onAppear {
            checkPasscode()
        }
    }
    
    private func checkPasscode() {
        if isPasscodeEnabled && !savedPasscode.isEmpty {
            showPasscodeScreen = true
        } else {
            isUnlocked = true
        }
    }
}


#Preview {
    ContentView()
        .environmentObject(StoreManager())
}
