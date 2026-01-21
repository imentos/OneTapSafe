//
//  CheckInLiveActivity.swift
//  OneTapSafe
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

struct CheckInLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: CheckInActivityAttributes.self) { context in
            // Lock screen/banner UI
            LockScreenLiveActivityView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                }
                
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text(context.state.deadline, style: .timer)
                            .font(.title3)
                            .monospacedDigit()
                            .foregroundColor(context.state.isOverdue ? .red : .primary)
                    }
                }
                
                DynamicIslandExpandedRegion(.bottom) {
                    Button(intent: CheckInIntent()) {
                        HStack {
                            Image(systemName: "hand.thumbsup.fill")
                            Text("I'm OK")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
            } compactLeading: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
            } compactTrailing: {
                Text(context.state.deadline, style: .timer)
                    .monospacedDigit()
                    .font(.caption2)
                    .foregroundColor(context.state.isOverdue ? .red : .primary)
            } minimal: {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(context.state.isOverdue ? .red : .green)
            }
        }
    }
}

struct LockScreenLiveActivityView: View {
    let context: ActivityViewContext<CheckInActivityAttributes>
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "checkmark.shield.fill")
                    .foregroundColor(.green)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Daily Safety Check-In")
                        .font(.headline)
                    Text("Tap to confirm you're safe")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if context.state.isOverdue {
                        Text("Overdue!")
                            .font(.caption)
                            .foregroundColor(.red)
                            .bold()
                    }
                    Text(context.state.deadline, style: .timer)
                        .monospacedDigit()
                        .font(.title3)
                        .foregroundColor(context.state.isOverdue ? .red : .primary)
                }
            }
            
            Button(intent: CheckInIntent()) {
                HStack {
                    Image(systemName: "hand.thumbsup.fill")
                    Text("I'm OK")
                        .font(.headline)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
}
