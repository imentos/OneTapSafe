//
//  OB5TinderCardsView.swift
//  OneTapSafe
//

import SwiftUI

struct OB5TinderCardsView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Which of these\nsounds familiar?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Swipe right if it rings true, left to skip.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            Spacer()

            if vm.tinderComplete {
                // All cards swiped — auto-advance
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    Text("We get it.")
                        .font(.title2.bold())
                    Text("OneTapSafe was built for exactly this.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        vm.advance()
                    }
                }
            } else {
                // Card stack
                ZStack {
                    // Background cards
                    ForEach((0..<min(3, vm.tinderStatements.count - vm.tinderIndex)).reversed(), id: \.self) { offset in
                        if offset > 0 {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.systemGray6))
                                .frame(maxWidth: .infinity)
                                .frame(height: 220)
                                .scaleEffect(1.0 - Double(offset) * 0.04)
                                .offset(y: Double(offset) * 8)
                                .padding(.horizontal, 24 + CGFloat(offset) * 8)
                        }
                    }

                    // Top card
                    TinderCard(
                        statement: vm.tinderStatements[vm.tinderIndex],
                        offset: vm.tinderOffset,
                        rotation: vm.tinderRotation
                    ) { agreed in
                        vm.swipeTinderCard(agreed: agreed)
                    }
                }
                .padding(.horizontal, 24)

                // Swipe hint buttons
                HStack(spacing: 40) {
                    Button(action: { vm.swipeTinderCard(agreed: false) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.red.opacity(0.7))
                            Text("Not me")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    Button(action: { vm.swipeTinderCard(agreed: true) }) {
                        VStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 44))
                                .foregroundColor(.green)
                            Text("That's me")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.top, 24)

                // Card counter
                Text("\(vm.tinderIndex + 1) of \(vm.tinderStatements.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }

            Spacer()
        }
    }
}

private struct TinderCard: View {
    let statement: String
    let offset: CGSize
    let rotation: Double
    let onSwipe: (Bool) -> Void

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.12), radius: 12, y: 4)

            Text("\"\(statement)\"")
                .font(.title3)
                .multilineTextAlignment(.center)
                .padding(28)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .rotationEffect(.degrees(rotation))
        .offset(offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    // Visual feedback only — buttons handle actual swiping for accessibility
                }
                .onEnded { value in
                    if value.translation.width > 80 {
                        onSwipe(true)
                    } else if value.translation.width < -80 {
                        onSwipe(false)
                    }
                }
        )
    }
}

#Preview {
    OB5TinderCardsView(vm: OnboardingViewModel())
}
