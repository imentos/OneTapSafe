//
//  OB2GoalView.swift
//  OneTapSafe
//

import SwiftUI

struct OB2GoalView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("Who are you setting\nthis up for?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("We'll personalise your experience.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            // Options list
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.goals, id: \.label) { goal in
                        GoalOptionRow(
                            emoji: goal.emoji,
                            label: goal.label,
                            isSelected: vm.selectedGoal == goal.label
                        ) {
                            vm.selectedGoal = goal.label
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
            }

            Spacer()

            // CTA — only visible after selection
            if !vm.selectedGoal.isEmpty {
                Button(action: { vm.advance() }) {
                    Text("That's me")
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
                .animation(.easeInOut(duration: 0.2), value: vm.selectedGoal)
            }
        }
    }
}

// MARK: - Goal Option Row

private struct GoalOptionRow: View {
    let emoji: String
    let label: String
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                Text(emoji)
                    .font(.title2)
                Text(label)
                    .font(.body)
                    .foregroundColor(.primary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
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
}

#Preview {
    OB2GoalView(vm: OnboardingViewModel())
}
