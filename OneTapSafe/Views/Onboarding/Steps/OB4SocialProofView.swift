//
//  OB4SocialProofView.swift
//  OneTapSafe
//

import SwiftUI

struct OB4SocialProofView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let testimonials: [(name: String, persona: String, quote: String)] = [
        (
            "Sarah K.",
            "Adult daughter, caregiver",
            "Mom lives four hours away. I used to call every morning. Now I just get a quiet notification and I know she's fine."
        ),
        (
            "Robert M.",
            "75, retired teacher",
            "My daughter set this up for me. I just tap the button on my lock screen. I don't even need to unlock my phone. It's perfect."
        ),
        (
            "David L.",
            "Son, lives out of state",
            "My dad has mild memory issues and forgets to call. This takes the pressure off both of us."
        ),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("You're not alone\nin this.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Thousands of families use OneTapSafe\nfor daily peace of mind.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(testimonials, id: \.name) { t in
                        TestimonialCard(name: t.name, persona: t.persona, quote: t.quote)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
            }

            Button(action: { vm.advance() }) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }
}

private struct TestimonialCard: View {
    let name: String
    let persona: String
    let quote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption2)
                }
            }
            Text("\"\(quote)\"")
                .font(.subheadline)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 8) {
                Circle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(String(name.prefix(1)))
                            .font(.subheadline.bold())
                            .foregroundColor(.green)
                    )
                VStack(alignment: .leading, spacing: 2) {
                    Text(name)
                        .font(.caption.bold())
                    Text(persona)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }
}

#Preview {
    OB4SocialProofView(vm: OnboardingViewModel())
}
