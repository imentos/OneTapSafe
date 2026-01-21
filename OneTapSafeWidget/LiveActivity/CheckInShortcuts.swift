//
//  CheckInShortcuts.swift
//  OneTapSafe
//

import AppIntents

struct CheckInShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CheckInIntent(),
            phrases: [
                "Check in with \(.applicationName)",
                "I'm safe on \(.applicationName)"
            ],
            shortTitle: "Check In",
            systemImageName: "checkmark.shield.fill"
        )
    }
}
