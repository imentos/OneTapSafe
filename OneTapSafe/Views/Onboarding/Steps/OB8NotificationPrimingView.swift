//
//  OB8NotificationPrimingView.swift
//  OneTapSafe
//

import SwiftUI
import UserNotifications

struct OB8NotificationPrimingView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var requestingPermission = false

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Icon
            Image(systemName: "bell.badge.fill")
                .font(.system(size: 72))
                .foregroundStyle(.green.gradient)
                .padding(.bottom, 24)

            VStack(spacing: 8) {
                Text("Be the first to know\nthey're safe.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Or the first to know\nsomething's wrong.")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 14) {
                BenefitRow(icon: "checkmark.circle.fill",  color: .green,  text: "Get a silent confirmation when they check in")
                BenefitRow(icon: "exclamationmark.triangle.fill", color: .orange, text: "Immediate alert if they miss their daily check-in")
                BenefitRow(icon: "clock.fill",             color: .blue,   text: "Reminders so they never forget to tap")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 24)
            .padding(.top, 28)

            Text("We only send what matters. No spam, no marketing.")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
                .padding(.top, 12)

            Spacer()

            VStack(spacing: 12) {
                Button(action: requestNotifications) {
                    Group {
                        if requestingPermission {
                            ProgressView().tint(.white)
                        } else {
                            Text("Turn on notifications ->")
                                .font(.headline)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                }

                Button(action: { vm.advance() }) {
                    Text("Not now")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 16)
        }
    }

    private func requestNotifications() {
        requestingPermission = true
        Task {
            await NotificationManager.shared.requestAuthorization()
            await MainActor.run {
                requestingPermission = false
                vm.advance()
            }
        }
    }
}

private struct BenefitRow: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 28)
            Text(text)
                .font(.subheadline)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    OB8NotificationPrimingView(vm: OnboardingViewModel())
}
