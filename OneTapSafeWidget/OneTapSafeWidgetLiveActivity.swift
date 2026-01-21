//
//  OneTapSafeWidgetLiveActivity.swift
//  OneTapSafeWidget
//
//  Created by Kuo, Ray on 1/19/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct OneTapSafeWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct OneTapSafeWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: OneTapSafeWidgetAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension OneTapSafeWidgetAttributes {
    fileprivate static var preview: OneTapSafeWidgetAttributes {
        OneTapSafeWidgetAttributes(name: "World")
    }
}

extension OneTapSafeWidgetAttributes.ContentState {
    fileprivate static var smiley: OneTapSafeWidgetAttributes.ContentState {
        OneTapSafeWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: OneTapSafeWidgetAttributes.ContentState {
         OneTapSafeWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: OneTapSafeWidgetAttributes.preview) {
   OneTapSafeWidgetLiveActivity()
} contentStates: {
    OneTapSafeWidgetAttributes.ContentState.smiley
    OneTapSafeWidgetAttributes.ContentState.starEyes
}
