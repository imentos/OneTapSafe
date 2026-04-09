//
//  OnboardingView.swift
//  OneTapSafe
//

import SwiftUI

struct OnboardingView: View {
    @StateObject private var vm = OnboardingViewModel()
    @StateObject private var dataStore = DataStore.shared
    var onComplete: () -> Void

    var body: some View {
        ZStack(alignment: .top) {
            // Background
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 0) {
                // Progress bar
                progressBar
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                // Step content
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color(.systemGray5))
                    .frame(height: 4)
                Capsule()
                    .fill(Color.green)
                    .frame(width: geo.size.width * vm.progressFraction, height: 4)
                    .animation(.easeInOut(duration: 0.3), value: vm.progressFraction)
            }
        }
        .frame(height: 4)
    }

    // MARK: - Step Routing

    @ViewBuilder
    private var stepContent: some View {
        switch vm.currentStep {
        case 1:
            OB1WelcomeView(vm: vm)
        case 2:
            OB2GoalView(vm: vm)
        case 3:
            OB3PainPointsView(vm: vm)
        case 4:
            OB4SocialProofView(vm: vm)
        case 5:
            OB5TinderCardsView(vm: vm)
        case 6:
            OB6SolutionView(vm: vm)
        case 7:
            OB7TimePickerView(vm: vm)
        case 8:
            OB8NotificationPrimingView(vm: vm)
        case 9:
            OB9ProcessingView(vm: vm)
        case 10:
            OB10DemoView(vm: vm)
        case 11:
            OB11PaywallView(vm: vm, onComplete: {
                vm.complete(dataStore: dataStore)
                onComplete()
            })
        default:
            EmptyView()
        }
    }
}

#Preview {
    OnboardingView(onComplete: {})
}
