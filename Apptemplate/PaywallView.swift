//
//  PaywallView.swift
//  Apptemplate
//
//  Created by Mohamed Abdelmagid on 8/19/25.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    // MARK: - Properties
    @EnvironmentObject var storeManager: StoreManager
    @Binding var isPresented: Bool
    @State private var currentTestimonial = 0
    @State private var selectedPlan: String = "template_weekly"
    @State private var testimonialTimer: Timer?
    
    // Journal app theme colors
    let paperColor = Color(red: 0.98, green: 0.96, blue: 0.91)
    let inkColor = Color(red: 0.2, green: 0.2, blue: 0.3)
    let accentColor = Color(red: 0.4, green: 0.5, blue: 0.6)
    
    // MARK: - Constants
    private struct Constants {
        static let appIconSize: CGFloat = 80
        static let cardHeight: CGFloat = 80
        static let testimonialHeight: CGFloat = 80
        static let animationDuration: Double = 0.5
        static let testimonialInterval: Double = 3.0
    }
    
    private let testimonials = [
        Testimonial(text: "This journal has helped me build a consistent reflection habit. I love seeing my growth over the cycles!", author: "Emma L."),
        Testimonial(text: "The 30-day cycle format keeps me engaged and motivated. Finally found a journaling app that works!", author: "David M."),
        Testimonial(text: "Being able to see my previous answers really shows how much I've grown. It's incredibly powerful.", author: "Sarah K.")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ZStack {
                paperColor
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        appIconSection
                        featuresSection
                        testimonialsSection
                        subscriptionPlansSection
                        purchaseButtonSection
                        bottomLinksSection
                    }
                    .padding(.horizontal, 20)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .font(.custom("Noteworthy-Bold", size: 16))
                    .foregroundColor(accentColor)
                }
            }
            .onChange(of: storeManager.isSubscribed) { _, newValue in
                if newValue {
                    isPresented = false
                }
            }
            .onDisappear {
                testimonialTimer?.invalidate()
            }
        }
    }
    
    // MARK: - View Components
    private var appIconSection: some View {
        Image("applogo")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: Constants.appIconSize, height: Constants.appIconSize)
            .cornerRadius(16)
            .padding(.top, 20)
    }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            FeatureRow(icon: "lock.fill", text: "Passcode Protection", inkColor: inkColor, accentColor: accentColor)
            FeatureRow(icon: "questionmark.diamond", text: "Edit & Customize Questions", inkColor: inkColor, accentColor: accentColor)
            FeatureRow(icon: "memories", text: "See Previous Answers", inkColor: inkColor, accentColor: accentColor)
        }
    }
    
    private var testimonialsSection: some View {
        VStack(spacing: 12) {
            starsView
            
            VStack(spacing: 8) {
                testimonialTabView
                pageIndicator
            }
        }
    }
    
    private var starsView: some View {
        HStack(spacing: 4) {
            ForEach(0..<5, id: \.self) { _ in
                Image(systemName: "star.fill")
                    .foregroundColor(accentColor)
                    .font(.caption)
            }
        }
    }
    
    private var testimonialTabView: some View {
        TabView(selection: $currentTestimonial) {
            ForEach(Array(testimonials.enumerated()), id: \.offset) { index, testimonial in
                VStack(spacing: 8) {
                    Text("\"\(testimonial.text)\"")
                        .font(.custom("Noteworthy-Light", size: 16))
                        .foregroundColor(inkColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("— \(testimonial.author)")
                        .font(.custom("Noteworthy-Light", size: 12))
                        .foregroundColor(inkColor.opacity(0.6))
                }
                .tag(index)
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
        .frame(height: Constants.testimonialHeight)
        .onAppear {
            startTestimonialTimer()
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<testimonials.count, id: \.self) { index in
                Circle()
                    .fill(index == currentTestimonial ? accentColor : inkColor.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
    }
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: 12) {
            PlanCardView(
                title: "Lifetime Plan",
                price: lifetimeProduct?.displayPrice ?? "$19.99",
                originalPrice: "$149",
                badge: "BEST DEAL",
                isSelected: selectedPlan == "template_lifetime",
                onTap: { selectedPlan = "template_lifetime" },
                inkColor: inkColor,
                accentColor: accentColor
            )
            
            PlanCardView(
                title: "3-Day Trial",
                subtitle: "then $2.99 per week",
                isSelected: selectedPlan == "template_weekly",
                onTap: { selectedPlan = "template_weekly" },
                inkColor: inkColor,
                accentColor: accentColor
            )
        }
    }
    
    private var purchaseButtonSection: some View {
        Button(action: purchaseSelectedPlan) {
            HStack(spacing: 8) {
                if storeManager.purchaseState == .purchasing {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(purchaseButtonText)
                    .font(.custom("Noteworthy-Bold", size: 18))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .disabled(storeManager.purchaseState == .purchasing)
    }
    
    private var bottomLinksSection: some View {
        HStack(spacing: 16) {
            Button("Restore", action: restorePurchases)
                .font(.custom("Noteworthy-Light", size: 14))
                .foregroundColor(inkColor.opacity(0.6))
            
            Text("•")
                .foregroundColor(inkColor.opacity(0.6))
            
            Button("Terms") {
                // TODO: Handle terms action
            }
            .font(.custom("Noteworthy-Light", size: 14))
            .foregroundColor(inkColor.opacity(0.6))
            
            Text("•")
                .foregroundColor(inkColor.opacity(0.6))
            
            Button("Privacy") {
                // TODO: Handle privacy action
            }
            .font(.custom("Noteworthy-Light", size: 14))
            .foregroundColor(inkColor.opacity(0.6))
        }
        .padding(.bottom, 20)
    }
    
    // MARK: - Computed Properties
    private var lifetimeProduct: Product? {
        storeManager.products.first { $0.id == "template_lifetime" }
    }
    
    private var purchaseButtonText: String {
        selectedPlan == "template_weekly" ? "Start 3-Day Free Trial" : "Purchase Lifetime"
    }
    
    // MARK: - Methods
    private func startTestimonialTimer() {
        testimonialTimer?.invalidate()
        testimonialTimer = Timer.scheduledTimer(withTimeInterval: Constants.testimonialInterval, repeats: true) { _ in
            withAnimation(.easeInOut(duration: Constants.animationDuration)) {
                currentTestimonial = (currentTestimonial + 1) % testimonials.count
            }
        }
    }
    
    private func purchaseSelectedPlan() {
        guard let product = storeManager.products.first(where: { $0.id == selectedPlan }) else { return }
        Task {
            await storeManager.purchase(product)
        }
    }
    
    private func restorePurchases() {
        Task {
            await storeManager.restorePurchases()
        }
    }
}

// MARK: - Supporting Views

struct FeatureRow: View {
    let icon: String
    let text: String
    let inkColor: Color
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(accentColor)
                .frame(width: 28)
            
            Text(text)
                .font(.custom("Noteworthy-Bold", size: 16))
                .foregroundColor(inkColor)
        }
    }
}

struct PlanCardView: View {
    let title: String
    var subtitle: String?
    var price: String?
    var originalPrice: String?
    var badge: String?
    let isSelected: Bool
    let onTap: () -> Void
    let inkColor: Color
    let accentColor: Color
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    titleWithBadge
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.custom("Noteworthy-Light", size: 14))
                            .foregroundColor(inkColor.opacity(0.6))
                    }
                    
                    if price != nil {
                        priceView
                    }
                }
                
                Spacer()
                
                selectionIndicator
            }
            .padding(16)
            .frame(height: 80)
            .background(Color.white.opacity(0.7))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? accentColor : inkColor.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var titleWithBadge: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.custom("Noteworthy-Bold", size: 18))
                .foregroundColor(inkColor)
            
            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [accentColor, accentColor.opacity(0.8)]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
            }
        }
    }
    
    private var priceView: some View {
        HStack(spacing: 8) {
            if let originalPrice = originalPrice {
                Text(originalPrice)
                    .font(.custom("Noteworthy-Light", size: 14))
                    .foregroundColor(inkColor.opacity(0.6))
                    .strikethrough()
            }
            Text(price!)
                .font(.custom("Noteworthy-Bold", size: 16))
                .foregroundColor(inkColor)
        }
    }
    
    private var selectionIndicator: some View {
        Circle()
            .fill(isSelected ? accentColor : Color.clear)
            .frame(width: 24, height: 24)
            .overlay(
                Circle()
                    .stroke(isSelected ? accentColor : inkColor.opacity(0.3), lineWidth: 2)
            )
            .overlay(
                Image(systemName: "checkmark")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .opacity(isSelected ? 1 : 0)
            )
    }
}

// MARK: - Models

struct Testimonial {
    let text: String
    let author: String
}
