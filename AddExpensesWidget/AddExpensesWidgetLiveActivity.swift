//
//  AddExpensesWidgetLiveActivity.swift
//  AddExpensesWidget
//
//  Created by Adesh Hemwani on 15/02/26.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct AddExpensesWidgetAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct AddExpensesWidgetLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AddExpensesWidgetAttributes.self) { context in
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

extension AddExpensesWidgetAttributes {
    fileprivate static var preview: AddExpensesWidgetAttributes {
        AddExpensesWidgetAttributes(name: "World")
    }
}

extension AddExpensesWidgetAttributes.ContentState {
    fileprivate static var smiley: AddExpensesWidgetAttributes.ContentState {
        AddExpensesWidgetAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: AddExpensesWidgetAttributes.ContentState {
         AddExpensesWidgetAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: AddExpensesWidgetAttributes.preview) {
   AddExpensesWidgetLiveActivity()
} contentStates: {
    AddExpensesWidgetAttributes.ContentState.smiley
    AddExpensesWidgetAttributes.ContentState.starEyes
}
