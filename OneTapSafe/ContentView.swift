//
//  ContentView.swift
//  OneTapSafe
//

import SwiftUI

struct ContentView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var selectedTab = 0

    var body: some View {
        Group {
            if !dataStore.hasCompletedOnboarding {
                OnboardingView {
                    // onComplete: dismiss onboarding — dataStore flag is set inside vm.complete()
                }
            } else {
                TabView(selection: $selectedTab) {
                    HomeView()
                        .tabItem { Label("Home", systemImage: "house.fill") }
                        .tag(0)

                    HistoryView()
                        .tabItem { Label("History", systemImage: "clock.fill") }
                        .tag(1)

                    ContactsView()
                        .tabItem { Label("Contacts", systemImage: "person.2.fill") }
                        .tag(2)

                    SettingsView()
                        .tabItem { Label("Settings", systemImage: "gear") }
                        .tag(3)
                }
                .tint(.green)
            }
        }
    }
}

#Preview {
    ContentView()
}
