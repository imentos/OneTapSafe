//
//  OB3PainPointsView.swift
//  OneTapSafe
//

import SwiftUI

struct OB3PainPointsView: View {
    @ObservedObject var vm: OnboardingViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                Text("What worries you most?")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text("Pick everything that applies.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            // Options list — always scrollable
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(vm.painPoints, id: \.label) { point in
                        PainPointRow(
                            emoji: point.emoji,
                            label: point.label,
                            isSelected: vm.selectedPainPoints.contains(point.label)
                        ) {
                            vm.togglePainPoint(point.label)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
            }

            // CTA — always visible (user can skip / continue with 0 selected)
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

// MARK: - Pain Point Row (checkbox style)

private struct PainPointRow: View {
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
                    .multilineTextAlignment(.leading)
                Spacer()
                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(isSelected ? .green : Color(.systemGray3))
                    .font(.title3)
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
    OB3PainPointsView(vm: OnboardingViewModel())
}
