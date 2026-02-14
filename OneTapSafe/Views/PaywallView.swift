//
//  PaywallView.swift
//  OneTapSafe
//
//  Created by OneTap OK on 2/13/26.
//

import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var subscriptionManager = SubscriptionManager.shared
    
    @State private var selectedProduct: Product?
    @State private var isPurchasing = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection
                    
                    // Features
                    featuresSection
                    
                    // Pricing Options
                    if !subscriptionManager.products.isEmpty {
                        pricingSection
                    } else {
                        ProgressView("Loading...")
                            .padding()
                    }
                    
                    // Purchase Button
                    purchaseButton
                    
                    // Footer Links
                    footerLinks
                }
                .padding()
            }
            .navigationTitle("OneTap OK Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
            .alert("Purchase Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            // Load products if not already loaded
            Task {
                if subscriptionManager.products.isEmpty {
                    await subscriptionManager.loadProducts()
                }
                // Pre-select annual plan (best value) after products load
                if selectedProduct == nil {
                    selectedProduct = subscriptionManager.products.first { $0.id == SubscriptionManager.ProductID.annual.rawValue }
                    ?? subscriptionManager.products.first
                }
            }
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "star.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.green.gradient)
            
            Text("Keep Everyone Safe")
                .font(.title.bold())
            
            Text("Upgrade to unlock unlimited contacts and premium safety features")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    // MARK: - Features Section
    
    private var featuresSection: some View {
        VStack(spacing: 16) {
            FeatureRow(icon: "person.3.fill", title: "Unlimited Contacts", description: "Add as many emergency contacts as you need")
            FeatureRow(icon: "envelope.fill", title: "Email Alerts", description: "Automatic email notifications when you miss check-ins")
            FeatureRow(icon: "clock.fill", title: "Daily Check-Ins", description: "Set your preferred check-in time")
            FeatureRow(icon: "chart.line.uptrend.xyaxis", title: "Safety History", description: "Track your check-in history")
            FeatureRow(icon: "bell.fill", title: "Smart Reminders", description: "Never miss your daily check-in")
            FeatureRow(icon: "heart.fill", title: "Peace of Mind", description: "Keep your loved ones informed and safe")
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
    
    // MARK: - Pricing Section
    
    private var pricingSection: some View {
        VStack(spacing: 12) {
            ForEach(subscriptionManager.products, id: \.id) { product in
                PricingCard(
                    product: product,
                    isSelected: selectedProduct?.id == product.id,
                    savings: savingsText(for: product)
                ) {
                    selectedProduct = product
                }
            }
        }
    }
    
    // MARK: - Purchase Button
    
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            Button(action: purchaseSelected) {
                if isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(purchaseButtonText)
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 50)
            .background(selectedProduct != nil ? Color.green : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(12)
            .disabled(selectedProduct == nil || isPurchasing)
            
            Button("Restore Purchases") {
                Task {
                    await subscriptionManager.restorePurchases()
                }
            }
            .font(.subheadline)
            .foregroundColor(.green)
        }
    }
    
    // MARK: - Footer Links
    
    private var footerLinks: some View {
        HStack(spacing: 20) {
            Link("Privacy Policy", destination: URL(string: "https://yourwebsite.com/privacy")!)
            Text("•")
            Link("Terms of Service", destination: URL(string: "https://yourwebsite.com/terms")!)
        }
        .font(.caption)
        .foregroundColor(.secondary)
    }
    
    // MARK: - Helper Methods
    
    private var purchaseButtonText: String {
        guard let product = selectedProduct else {
            return "Select a Plan"
        }
        return "Continue - \(product.displayPrice)"
    }
    
    private func savingsText(for product: Product) -> String? {
        if product.id == SubscriptionManager.ProductID.annual.rawValue {
            return "Save 37%"
        } else if product.id == SubscriptionManager.ProductID.lifetime.rawValue {
            return "Best Value"
        }
        return nil
    }
    
    private func purchaseSelected() {
        guard let product = selectedProduct else { return }
        
        isPurchasing = true
        
        Task {
            do {
                let success = try await subscriptionManager.purchase(product)
                isPurchasing = false
                
                if success {
                    // Dismiss paywall on successful purchase
                    dismiss()
                }
            } catch {
                isPurchasing = false
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Pricing Card

struct PricingCard: View {
    let product: Product
    let isSelected: Bool
    let savings: String?
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(product.displayName)
                            .font(.headline)
                        
                        if let savings = savings {
                            Text(savings)
                                .font(.caption.bold())
                                .foregroundColor(.green)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(8)
                        }
                    }
                    
                    Text(subscriptionPeriod)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(product.displayPrice)
                        .font(.title3.bold())
                    
                    if let period = pricePerMonth {
                        Text(period)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.green.opacity(0.1) : Color.clear)
                    )
            )
        }
        .buttonStyle(.plain)
    }
    
    private var subscriptionPeriod: String {
        if product.id.contains("monthly") {
            return "Billed monthly"
        } else if product.id.contains("annual") {
            return "Billed annually"
        } else {
            return "One-time purchase"
        }
    }
    
    private var pricePerMonth: String? {
        if product.id.contains("annual"), let price = product.price as? Double {
            let monthly = price / 12.0
            return String(format: "$%.2f/month", monthly)
        }
        return nil
    }
}

// MARK: - Preview

#Preview {
    PaywallView()
}
