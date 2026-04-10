//
//  OB11PaywallView.swift
//  OneTapSafe
//

import SwiftUI
import StoreKit

struct OB11PaywallView: View {
    @ObservedObject var vm: OnboardingViewModel
    var onComplete: () -> Void

    @StateObject private var subscriptionManager = SubscriptionManager.shared
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "heart.shield.fill")
                        .font(.system(size: 64))
                        .foregroundStyle(.green.gradient)
                        .padding(.top, 8)

                    Text("Keep everyone safe.\nEvery day.")
                        .font(.title.bold())
                        .multilineTextAlignment(.center)

                    Text("Unlock unlimited contacts\nand full alert escalation.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 24)

                // Featured review
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 2) {
                        ForEach(0..<5, id: \.self) { _ in
                            Image(systemName: "star.fill").foregroundColor(.yellow).font(.caption)
                        }
                    }
                    Text("\"Worth every penny. I went from calling my mom twice a day to just checking my phone once. She loves that she doesn't have to answer anymore.\"")
                        .font(.subheadline)
                        .italic()
                    Text("-- Jennifer R.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                // Pro features
                VStack(spacing: 14) {
                    ProFeatureRow(icon: "person.3.fill",             text: "Unlimited emergency contacts (free: 1)")
                    ProFeatureRow(icon: "envelope.badge.fill",       text: "Email alerts to all contacts")
                    ProFeatureRow(icon: "lock.shield.fill",          text: "Lock screen check-in via Live Activity")
                    ProFeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Full 30-day safety history")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                .padding(.horizontal, 24)

                // Pricing plans
                if subscriptionManager.products.isEmpty {
                    ProgressView("Loading plans...")
                        .padding()
                } else {
                    VStack(spacing: 12) {
                        ForEach(subscriptionManager.products, id: \.id) { product in
                            OnboardingPricingCard(
                                product: product,
                                isSelected: selectedProduct?.id == product.id,
                                savingsText: savingsText(for: product)
                            ) {
                                selectedProduct = product
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Purchase CTA
                VStack(spacing: 12) {
                    Button(action: purchase) {
                        Group {
                            if isPurchasing {
                                ProgressView().tint(.white)
                            } else {
                                Text(ctaText)
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(selectedProduct != nil ? Color.green : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(selectedProduct == nil || isPurchasing)
                    .padding(.horizontal, 24)

                    Button("Maybe later") {
                        onComplete()
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                    if let disclaimer = trialDisclaimer {
                        Text(disclaimer)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Button("Restore Purchases") {
                        Task { await subscriptionManager.restorePurchases() }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)

                    HStack(spacing: 16) {
                        Link("Terms of Use", destination: URL(string: "https://imentos.github.io/OneTapSafe/terms-of-use")!)
                        Link("Privacy Policy", destination: URL(string: "https://imentos.github.io/OneTapSafe/privacy-policy")!)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .padding(.bottom, 32)
            }
        }
        .onAppear {
            Task {
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                if selectedProduct == nil {
                    selectedProduct = subscriptionManager.products.first {
                        $0.id == SubscriptionManager.ProductID.annual.rawValue
                    } ?? subscriptionManager.products.first
                }
            }
        }
        .alert("Purchase Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private var ctaText: String {
        guard let p = selectedProduct else { return "Select a Plan" }
        if p.id == SubscriptionManager.ProductID.annual.rawValue {
            return "Try Free for 7 Days, then \(p.displayPrice)/year"
        }
        return "Subscribe for \(p.displayPrice)"
    }

    private var trialDisclaimer: String? {
        guard let p = selectedProduct,
              p.id == SubscriptionManager.ProductID.annual.rawValue else { return nil }
        return "7-day free trial, then \(p.displayPrice)/year. Cancel anytime in Apple ID settings before trial ends to avoid charges."
    }

    private func savingsText(for product: Product) -> String? {
        if product.id == SubscriptionManager.ProductID.annual.rawValue { return "Save 37%" }
        if product.id == SubscriptionManager.ProductID.lifetime.rawValue { return "Best Value" }
        return nil
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        isPurchasing = true
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                isPurchasing = false
                if success { onComplete() }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

private struct ProFeatureRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .font(.title3)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
            Spacer()
        }
    }
}

private struct OnboardingPricingCard: View {
    let product: Product
    let isSelected: Bool
    let savingsText: String?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.displayName)
                            .font(.headline)
                        if let savings = savingsText {
                            Text(savings)
                                .font(.caption.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .cornerRadius(6)
                        }
                    }
                    Text(billingPeriod)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                    if let perMonth = pricePerMonth {
                        Text(perMonth)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.green : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.green.opacity(0.08) : Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var billingPeriod: String {
        if product.id.contains("monthly") { return "Billed monthly" }
        if product.id.contains("annual")  { return "Billed annually" }
        return "One-time purchase"
    }

    private var pricePerMonth: String? {
        guard product.id.contains("annual") else { return nil }
        let monthly = (product.price as NSDecimalNumber).doubleValue / 12.0
        return String(format: "$%.2f/month", monthly)
    }
}

#Preview {
    OB11PaywallView(vm: OnboardingViewModel(), onComplete: {})
}
