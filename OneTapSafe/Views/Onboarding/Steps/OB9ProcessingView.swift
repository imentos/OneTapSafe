//
//  OB9ProcessingView.swift
//  OneTapSafe
//

import SwiftUI

struct OB9ProcessingView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let steps = [
        "Check-in time confirmed",
        "Notification preferences saved",
        "Lock screen button ready",
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Spinning icon
            Image(systemName: "shield.lefthalf.filled")
                .font(.system(size: 80))
                .foregroundStyle(.green.gradient)
                .rotationEffect(.degrees(vm.processingStep > 0 ? 360 : 0))
                .animation(
                    vm.processingStep > 0 ? .linear(duration: 1.5).repeatForever(autoreverses: false) : .default,
                    value: vm.processingStep
                )
                .padding(.bottom, 32)

            Text("Setting up your\nsafety plan...")
                .font(.title.bold())
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            VStack(alignment: .leading, spacing: 16) {
                ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                    HStack(spacing: 14) {
                        if vm.processingStep > index {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                                .transition(.scale.combined(with: .opacity))
                        } else {
                            Circle()
                                .fill(Color(.systemGray4))
                                .frame(width: 22, height: 22)
                        }
                        Text(step)
                            .font(.subheadline)
                            .foregroundColor(vm.processingStep > index ? .primary : .secondary)
                    }
                    .animation(.easeInOut(duration: 0.3), value: vm.processingStep)
                }
            }
            .padding(20)
            .background(Color(.systemGray6))
            .cornerRadius(16)
            .padding(.horizontal, 32)
            .padding(.top, 28)

            Spacer()
        }
        .onAppear {
            vm.runProcessingAnimation {
                vm.advance()
            }
        }
    }
}

#Preview {
    OB9ProcessingView(vm: OnboardingViewModel())
}
