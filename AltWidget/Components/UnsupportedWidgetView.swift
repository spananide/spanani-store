//
//  UnsupportedWidgetView.swift
//  AltWidget
//
//  Created by Magesh K on 8/8/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SwiftUI
import WidgetKit

struct UnsupportedEntry: TimelineEntry {
    let date: Date = Date()
}

struct UnsupportedTimelineProvider: TimelineProvider {
    func placeholder(in context: Context) -> UnsupportedEntry {
        UnsupportedEntry()
    }

    func getSnapshot(in context: Context, completion: @escaping (UnsupportedEntry) -> Void) {
        completion(UnsupportedEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<UnsupportedEntry>) -> Void) {
        let timeline = Timeline(entries: [UnsupportedEntry()], policy: .never)
        completion(timeline)
    }
}

struct UnsupportedWidgetView: View {
    let requiredVersion: String

    init(requiredVersion: String = "iOS 17") {
        self.requiredVersion = requiredVersion
    }

    var body: some View {
        VStack(spacing: 4) {
            Text("This widget needs iOS 17 or later.")
                .font(.system(.subheadline, weight: .semibold))
                .foregroundStyle(Color.spananiPrimaryText)
                .multilineTextAlignment(.center)
        }
        .padding(8)
    }
}
