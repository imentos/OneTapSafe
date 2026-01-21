//
//  HistoryView.swift
//  OneTapSafe
//

import SwiftUI

struct HistoryView: View {
    @StateObject private var dataStore = DataStore.shared
    @State private var selectedDays = 7
    
    var recentCheckIns: [CheckIn] {
        dataStore.getRecentCheckIns(days: selectedDays)
    }
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Period", selection: $selectedDays) {
                        Text("7 Days").tag(7)
                        Text("14 Days").tag(14)
                        Text("30 Days").tag(30)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section {
                    if recentCheckIns.isEmpty {
                        ContentUnavailableView(
                            "No Check-Ins Yet",
                            systemImage: "clock.badge.questionmark",
                            description: Text("Your check-in history will appear here")
                        )
                    } else {
                        ForEach(recentCheckIns) { checkIn in
                            CheckInRow(checkIn: checkIn)
                        }
                    }
                } header: {
                    HStack {
                        Text("Recent Check-Ins")
                        Spacer()
                        Text("\(recentCheckIns.count) total")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}

struct CheckInRow: View {
    let checkIn: CheckIn
    
    var body: some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(checkIn.timestamp, style: .date)
                    .font(.subheadline)
                    .bold()
                Text(checkIn.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(checkIn.method.rawValue)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.green.opacity(0.2))
                .foregroundColor(.green)
                .cornerRadius(8)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HistoryView()
}
