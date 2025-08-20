//
//  OnboardingView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI

struct OnboardingView: View {
    @Binding var hasCompletedOnboarding: Bool
    
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            Image("applogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .cornerRadius(20)
            
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
            
            Image("jointhousands")
                .resizable()
                .scaledToFit()
                .frame(width: 120)
            
            Spacer()
            
            Button(action: {
                hasCompletedOnboarding = true
            }) {
                Text("Continue")
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
            .padding(.horizontal, 40)
            .padding(.bottom, 50)
        }
        .background(Color(UIColor.systemBackground))
    }
}

