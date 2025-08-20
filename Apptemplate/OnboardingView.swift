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
            
            Image(systemName: "book.fill")
                .font(.system(size: 100))
                .foregroundStyle(Color(red: 0.4, green: 0.5, blue: 0.6))
            
            VStack(spacing: 20) {
                Text("30-Day Reflection")
                    .font(.custom("Noteworthy-Bold", size: 32))
                    .fontWeight(.bold)
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.3))
                
                Text("Answer one thoughtful question each day for 30 days, then see how you've grown")
                    .font(.custom("Noteworthy-Light", size: 18))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.3).opacity(0.8))
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