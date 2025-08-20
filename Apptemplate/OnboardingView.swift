//
//  OnboardingView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image(systemName: "star.fill")
                .font(.system(size: 100))
                .foregroundStyle(.yellow)
            
            VStack(spacing: 20) {
                Text("Welcome to App")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Experience the best features with our premium subscription")
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            Button(action: {
                hasCompletedOnboarding = true
            }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemBackground))
    }
}