//
//  OB6SolutionView.swift
//  OneTapSafe
//

import SwiftUI

struct OB6SolutionView: View {
    @ObservedObject var vm: OnboardingViewModel

    private let solutionRows: [(pain: String, solution: String, icon: String)] = [
        ("Worrying between calls",       "Daily confirmation, every morning -- you'll know by 9am",      "sunrise.fill"),
        ("They don't answer",            "No call needed. They tap one button on their lock screen",     "hand.tap.fill"),
        ("Feels like nagging",           "Silent system. You only hear from us if they miss a day",      "bell.slash.fill"),
        ("Not great with tech",          "No unlocking. No apps. No passcode. Just a button on screen",  "iphone"),
    ]

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 8) {
                Text("Here's exactly\nhow we fix that.")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)

            ScrollView {
                VStack(spacing: 16) {
                    ForEach(solutionRows, id: \.pain) { row in
                        SolutionRow(pain: row.pain, solution: row.solution, icon: row.icon)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 8)
            }

            Button(action: { vm.advance() }) {
                Text("Sounds good ->")
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

private struct SolutionRow: View {
    let pain: String
    let solution: String
    let icon: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.green)
                .frame(width: 32)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(pain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(solution)
                    .font(.subheadline.bold())
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    OB6SolutionView(vm: OnboardingViewModel())
}
