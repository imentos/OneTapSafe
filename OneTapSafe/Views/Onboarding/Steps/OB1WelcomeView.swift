//
//  OB1WelcomeView.swift
//  OneTapSafe
//

import SwiftUI

struct OB1WelcomeView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Hero illustration — mock lock screen
            lockScreenMock
                .padding(.bottom, 40)

            // Headline
            Text("Know they're okay.\nEvery day.")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Text("One tap from the lock screen.\nAutomatic alerts if they miss a day.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            // CTA
            Button(action: { vm.advance() }) {
                Text("Get Started")
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

    // MARK: - Mock Lock Screen

    private var lockScreenMock: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.2, blue: 0.4),
                                 Color(red: 0.05, green: 0.1, blue: 0.25)],
                        startPoint: .top, endPoint: .bottom
                    )
                )
                .frame(width: 220, height: 280)
                .shadow(color: .black.opacity(0.3), radius: 20, y: 10)

            VStack(spacing: 12) {
                // Time
                VStack(spacing: 2) {
                    Text("9:00")
                        .font(.system(size: 52, weight: .thin))
                        .foregroundColor(.white)
                    Text("Wednesday, April 8")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }

                // Live Activity pill
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text("Tap to check in →")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.15))
                .cornerRadius(20)

                // Big green button
                Text("I'm OK")
                    .font(.headline.bold())
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .cornerRadius(12)
                    .padding(.horizontal, 16)
            }
            .padding(.horizontal, 12)
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
