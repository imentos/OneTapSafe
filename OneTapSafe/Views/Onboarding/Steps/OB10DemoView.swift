//
//  OB10DemoView.swift
//  OneTapSafe
//

import SwiftUI

struct OB10DemoView: View {
    @ObservedObject var vm: OnboardingViewModel
    @State private var showSuccess = false
    @State private var pulseScale: CGFloat = 1.0

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("This is what they'll\nsee every day.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Tap the button below -- just like they would.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            Spacer()

            if showSuccess {
                // Success state
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.green)
                        .transition(.scale.combined(with: .opacity))

                    Text("Check-in recorded!")
                        .font(.title2.bold())

                    Text("Your family has been notified\nyou're safe.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    Text("In the real app, this happens from the actual\nlock screen -- no unlocking needed.")
                        .font(.caption)
                        .foregroundColor(Color(.systemGray2))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 4)
                }
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.4), value: showSuccess)

            } else {
                // Mock lock screen
                mockLockScreen
                    .transition(.scale.combined(with: .opacity))
            }

            Spacer()

            if showSuccess {
                Button(action: { vm.advance() }) {
                    Text("See your plan ->")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3).delay(0.5), value: showSuccess)
            }
        }
    }

    // MARK: - Mock Lock Screen

    private var mockLockScreen: some View {
        ZStack {
            // Phone frame
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.1, green: 0.15, blue: 0.35),
                                 Color(red: 0.05, green: 0.08, blue: 0.2)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 240, height: 320)
                .shadow(color: .black.opacity(0.4), radius: 24, y: 12)

            VStack(spacing: 0) {
                // Clock
                VStack(spacing: 2) {
                    Text(currentTimeString)
                        .font(.system(size: 48, weight: .ultraLight))
                        .foregroundColor(.white)
                    Text(currentDateString)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.top, 24)

                Spacer()

                // Live Activity container
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Image(systemName: "shield.fill")
                            .foregroundColor(.green)
                            .font(.caption)
                        Text("OneTapSafe")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.8))
                        Spacer()
                        Text("8h left")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // THE BUTTON
                    Button(action: tapDemoButton) {
                        HStack(spacing: 8) {
                            Image(systemName: "hand.thumbsup.fill")
                                .font(.subheadline)
                            Text("I'm OK")
                                .font(.subheadline.bold())
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .scaleEffect(pulseScale)
                    }
                    .buttonStyle(.plain)
                    .onAppear { startPulse() }
                }
                .padding(14)
                .background(Color.white.opacity(0.12))
                .cornerRadius(18)
                .padding(.horizontal, 14)

                Spacer().frame(height: 24)
            }
            .frame(width: 240, height: 320)
        }
    }

    private func tapDemoButton() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            pulseScale = 0.92
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                pulseScale = 1.0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            withAnimation(.easeInOut(duration: 0.4)) {
                showSuccess = true
            }
        }
    }

    private func startPulse() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.04
        }
    }

    private var currentTimeString: String {
        let f = DateFormatter()
        f.dateFormat = "h:mm"
        return f.string(from: Date())
    }

    private var currentDateString: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMMM d"
        return f.string(from: Date())
    }
}

#Preview {
    OB10DemoView(vm: OnboardingViewModel())
}
