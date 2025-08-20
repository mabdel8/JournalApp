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
    
    // MARK: - Constants
    private struct Constants {
        static let appIconSize: CGFloat = 80
        static let cardHeight: CGFloat = 80
        static let testimonialHeight: CGFloat = 80
        static let animationDuration: Double = 0.5
        static let testimonialInterval: Double = 3.0
    }
    
    private let testimonials = [
        Testimonial(text: "Love tracking my reading stats and competing with friends. Makes reading so much more fun!", author: "Emma L."),
        Testimonial(text: "The AI-powered features help me discover books I never would have found otherwise.", author: "David M."),
        Testimonial(text: "Finally hit my reading goals thanks to the smart reminders and progress tracking.", author: "Sarah K.")
    ]
    
    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    appIconSection
                    featuresSection
                    testimonialsSection
                    subscriptionPlansSection
                    purchaseButtonSection
                    bottomLinksSection
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                    .foregroundStyle(.blue)
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
            FeatureRow(icon: "books.vertical.fill", text: "Unlimited Books")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Advanced Statistics")
            FeatureRow(icon: "sparkles", text: "AI-Powered Features")
        }
        .padding(.horizontal, 24)
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
                    .foregroundStyle(.yellow)
                    .font(.caption)
            }
        }
    }
    
    private var testimonialTabView: some View {
        TabView(selection: $currentTestimonial) {
            ForEach(Array(testimonials.enumerated()), id: \.offset) { index, testimonial in
                VStack(spacing: 8) {
                    Text("\"\(testimonial.text)\"")
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    
                    Text("— \(testimonial.author)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                    .fill(index == currentTestimonial ? Color.purple : Color.gray.opacity(0.3))
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
                onTap: { selectedPlan = "template_lifetime" }
            )
            
            PlanCardView(
                title: "3-Day Trial",
                subtitle: "then $2.99 per week",
                isSelected: selectedPlan == "template_weekly",
                onTap: { selectedPlan = "template_weekly" }
            )
        }
        .padding(.horizontal, 20)
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
                    .font(.headline)
                    .foregroundStyle(.white)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [Color.purple, Color.blue]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(12)
        }
        .padding(.horizontal, 20)
        .disabled(storeManager.purchaseState == .purchasing)
    }
    
    private var bottomLinksSection: some View {
        HStack(spacing: 16) {
            Button("Restore", action: restorePurchases)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            Text("•")
                .foregroundStyle(.secondary)
            
            Button("Terms") {
                // TODO: Handle terms action
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            
            Text("•")
                .foregroundStyle(.secondary)
            
            Button("Privacy") {
                // TODO: Handle privacy action
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
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
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.purple)
                .frame(width: 28)
            
            Text(text)
                .font(.headline)
                .foregroundStyle(.primary)
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
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    titleWithBadge
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
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
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private var titleWithBadge: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            
            if let badge = badge {
                Text(badge)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.purple, Color.blue]),
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
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .strikethrough()
            }
            Text(price!)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(.primary)
        }
    }
    
    private var selectionIndicator: some View {
        Circle()
            .fill(isSelected ? Color.purple : Color.clear)
            .frame(width: 24, height: 24)
            .overlay(
                Circle()
                    .stroke(isSelected ? Color.purple : Color.gray.opacity(0.3), lineWidth: 2)
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
