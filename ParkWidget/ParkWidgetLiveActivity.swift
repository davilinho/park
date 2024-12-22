//
//  ParkWidgetLiveActivity.swift
//  ParkWidget
//
//  Created by David Martin Nevado on 16/12/24.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct ParkWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct ParkWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ParkWidgetAttributes.self) { context in
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

extension ParkWidgetAttributes {
    fileprivate static var preview: ParkWidgetAttributes {
        ParkWidgetAttributes(name: "World")
    }
}

extension ParkWidgetAttributes.ContentState {
    fileprivate static var smiley: ParkWidgetAttributes.ContentState {
        ParkWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ParkWidgetAttributes.ContentState {
         ParkWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: ParkWidgetAttributes.preview) {
   ParkWidgetLiveActivity()
} contentStates: {
    ParkWidgetAttributes.ContentState.smiley
    ParkWidgetAttributes.ContentState.starEyes
}
