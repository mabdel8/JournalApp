//
//  ApptemplateApp.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI

@main
struct ApptemplateApp: App {
    @StateObject private var storeManager = StoreManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showPaywall = false
    
    var body: some Scene {
        WindowGroup {
            if !hasCompletedOnboarding {
                OnboardingView(hasCompletedOnboarding: $hasCompletedOnboarding)
                    .onChange(of: hasCompletedOnboarding) { _, newValue in
                        if newValue {
                            Task {
                                await storeManager.updateSubscriptionStatus()
                                if !storeManager.isSubscribed {
                                    showPaywall = true
                                }
                            }
                        }
                    }
            } else {
                ContentView()
                    .environmentObject(storeManager)
                    .sheet(isPresented: $showPaywall) {
                        PaywallView(isPresented: $showPaywall)
                            .environmentObject(storeManager)
                    }
                    .task {
                        await storeManager.updateSubscriptionStatus()
                        if !storeManager.isSubscribed {
                            showPaywall = true
                        }
                    }
            }
        }
    }
}
