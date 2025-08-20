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
    @State private var showPaywall = false
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            VStack(spacing: 20) {
                Image(systemName: storeManager.isSubscribed ? "crown.fill" : "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(storeManager.isSubscribed ? .yellow : .gray)
                
                Text(storeManager.isSubscribed ? "Premium Account" : "Free Account")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text(storeManager.isSubscribed ? "Enjoy unlimited access to all features" : "Upgrade to unlock all features")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            if !storeManager.isSubscribed {
                Button(action: {
                    showPaywall = true
                }) {
                    Text("Upgrade to Premium")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(isPresented: $showPaywall)
                .environmentObject(storeManager)
        }
        .task {
            await storeManager.updateSubscriptionStatus()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(StoreManager())
}
