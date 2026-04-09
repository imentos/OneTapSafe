//
//  OnboardingViewModel.swift
//  OneTapSafe
//

import SwiftUI
import Combine

@MainActor
final class OnboardingViewModel: ObservableObject {

    // MARK: - Navigation

    static let totalSteps = 11
    @Published var currentStep: Int = 1

    var progressFraction: Double {
        Double(currentStep) / Double(Self.totalSteps)
    }

    func advance() {
        guard currentStep < Self.totalSteps else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep += 1
        }
    }

    func goBack() {
        guard currentStep > 1 else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            currentStep -= 1
        }
        // Reset demo state when navigating back from or through the demo screen
        if currentStep < 10 {
            demoTapped = false
        }
    }

    // MARK: - Screen 2: Goal

    let goals: [(emoji: String, label: String)] = [
        ("👴", "My parent living alone"),
        ("👴👵", "My parents (both of them)"),
        ("🧓", "Myself — I want family to know I'm safe"),
        ("👫", "My spouse or partner"),
        ("🏥", "Someone I care for"),
    ]

    @Published var selectedGoal: String = ""

    // MARK: - Screen 3: Pain Points

    let painPoints: [(emoji: String, label: String)] = [
        ("😟", "Not hearing from them for too long"),
        ("📱", "They don't always answer their phone"),
        ("😔", "I feel guilty calling to check up all the time"),
        ("🤔", "They forget to reach out, even when fine"),
        ("📵", "They struggle with apps and technology"),
        ("🌙", "Something could happen overnight and I'd miss it"),
        ("💭", "The constant worry in the back of my mind"),
    ]

    @Published var selectedPainPoints: Set<String> = []

    func togglePainPoint(_ label: String) {
        if selectedPainPoints.contains(label) {
            selectedPainPoints.remove(label)
        } else {
            selectedPainPoints.insert(label)
        }
    }

    // MARK: - Screen 5: Tinder Cards

    let tinderStatements: [String] = [
        "I lie awake wondering if they're okay — even when there's no reason to worry.",
        "Calling to check in feels like nagging. But NOT calling feels worse.",
        "They say they're fine. But I'd feel better with something more... definite.",
        "I just want one quiet confirmation each day that they made it through okay.",
        "They're independent. They don't want me hovering. But I can't help it.",
    ]

    @Published var tinderIndex: Int = 0
    @Published var tinderOffset: CGSize = .zero
    @Published var tinderRotation: Double = 0

    var tinderComplete: Bool { tinderIndex >= tinderStatements.count }

    func swipeTinderCard(agreed: Bool) {
        withAnimation(.easeOut(duration: 0.3)) {
            tinderOffset = CGSize(width: agreed ? 400 : -400, height: 0)
            tinderRotation = agreed ? 15 : -15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            self.tinderOffset = .zero
            self.tinderRotation = 0
            self.tinderIndex += 1
        }
    }

    // MARK: - Screen 7: Reminder Time

    @Published var reminderTime: Date = Calendar.current.date(
        from: DateComponents(hour: 9, minute: 0)
    ) ?? Date()

    // MARK: - Screen 9: Processing

    @Published var processingStep: Int = 0
    private var processingWorkItems: [DispatchWorkItem] = []

    func runProcessingAnimation(completion: @escaping () -> Void) {
        processingWorkItems.forEach { $0.cancel() }
        processingWorkItems.removeAll()
        processingStep = 0
        let delays = [0.5, 1.1, 1.7]
        for (i, delay) in delays.enumerated() {
            let item = DispatchWorkItem { [weak self] in
                withAnimation { self?.processingStep = i + 1 }
            }
            processingWorkItems.append(item)
            DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
        }
        let finalItem = DispatchWorkItem { completion() }
        processingWorkItems.append(finalItem)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: finalItem)
    }

    // MARK: - Screen 10: Demo

    @Published var demoTapped: Bool = false

    func tapDemoButton() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
            demoTapped = true
        }
    }

    // MARK: - Completion

    func complete(dataStore: DataStore) {
        // Save questionnaire answers
        dataStore.completeOnboarding(
            goal: selectedGoal,
            painPoints: Array(selectedPainPoints)
        )
        // Save reminder time
        dataStore.updateReminderTime(reminderTime)
        // Schedule daily reminder
        if dataStore.reminderEnabled {
            NotificationManager.shared.scheduleDailyReminder(at: reminderTime)
        }
    }
}
