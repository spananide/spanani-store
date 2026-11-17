//
//  AppDetailWidget.swift
//  AltWidgetExtension
//
//  Created by Riley Testut on 9/14/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import WidgetKit
import SwiftUI

struct AppDetailWidget: Widget
{
    private let kind: String = "AppDetail"
    
    init() {
        debugLog("[AppDetailWidget] Initialized widget kind: AppDetail")
    }
    
    public var body: some WidgetConfiguration {
        // On iOS 16+ use AppIntentConfiguration — it correctly supports
        // containerBackground and contentMarginsDisabled(), unlike the legacy
        // IntentConfiguration which breaks on iOS 17+ with the
        // "Please adopt containerBackground" error.
        if #available(iOSApplicationExtension 17, *)
        {
            return AppIntentConfiguration(
                kind: kind,
                intent: SelectAppIntent.self,
                provider: SelectAppTimelineProvider()
            ) { entry in
                AppDetailWidgetView(apps: entry.apps, date: entry.date, isPlaceholder: entry.isPlaceholder)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("App Status")
            .description("View remaining days until your sideloaded apps expire. Tap the countdown timer to refresh them in the background.")
            .contentMarginsDisabled()
        }
        else
        {
            // Legacy path for iOS 15.
            return IntentConfiguration(
                kind: kind,
                intent: ViewAppIntent.self,
                provider: AppsTimelineProvider()
            ) { entry in
                AppDetailWidgetView(apps: entry.apps, date: entry.date, isPlaceholder: entry.isPlaceholder)
            }
            .supportedFamilies([.systemSmall])
            .configurationDisplayName("App Status")
            .description("View remaining days until your sideloaded apps expire. Tap the countdown timer to refresh them in the background.")
        }
    }
}

private struct AppDetailWidgetView: View
{
    let apps: [AppSnapshot]
    let date: Date
    let isPlaceholder: Bool
    
    @Environment(\.colorScheme)
    private var colorScheme

    @Environment(\.widgetRenderingMode)
    private var renderingMode
    
    var body: some View {
        Group {
            if let app = apps.first
            {
                let daysRemaining = app.expirationDate.numberOfCalendarDays(since: date)
                    
                GeometryReader { (geometry) in
                    Group {
                        VStack(alignment: .leading) {
                            VStack(alignment: .leading, spacing: 5) {
                                let imageHeight = geometry.size.height * 0.4
                                
                                AppIconView(icon: app.icon, imageHeight: imageHeight)
                                
                                Text(app.name.uppercased())
                                    .font(.system(.caption, weight: .semibold))
                                    .foregroundColor(Color.spananiPrimaryText)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.5)
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .widgetAccentableIfAvailable()
                            
                            Spacer(minLength: 0)
                            
                            HStack(alignment: .center) {
                                let expirationText: Text = {
                                    switch daysRemaining
                                    {
                                    case ..<0: return Text("Expired")
                                    case 1: return Text("1 day")
                                    default: return Text("\(daysRemaining) days")
                                    }
                                }()
                                
                                (
                                    Text("Expires in\n")
                                        .font(.system(.caption, weight: .semibold))
                                        .foregroundColor(.secondary) +
                                    
                                    expirationText
                                        .font(.system(.subheadline, weight: .semibold))
                                        .foregroundColor(Color.spananiPrimaryText)
                                )
                                .lineLimit(2)
                                .lineSpacing(1.0)
                                .minimumScaleFactor(0.5)
                                
                                Spacer()
                                
                                if daysRemaining >= 0
                                {
                                    Countdown(startDate: app.refreshedDate,
                                              endDate: app.expirationDate,
                                              currentDate: date)
                                        .font(.system(.title3, weight: .semibold))
                                        .fixedSize(horizontal: true, vertical: false)
                                        .offset(x: 5)
                                        .invalidatableContentIfAvailable()
                                }
                            }
                            .fixedSize(horizontal: false, vertical: true)
                            .activatesRefreshAllAppsIntent()
                            .widgetAccentableIfAvailable()
                        }
                        .padding()
                    }
                }
            }
            else
            {
                VStack(spacing: 4) {
                    Text("No active apps")
                        .font(.system(.subheadline, weight: .semibold))
                        .foregroundStyle(Color.spananiPrimaryText)
                    Text("Open spanani Store to install one.")
                        .font(.system(.caption2))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding()
                .unredacted()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .foregroundStyle(Color.spananiPrimaryText)
        .widgetBackground(backgroundView)
        .onAppear {
            debugLog("[AppDetailWidgetView] onAppear: isPlaceholder=\(isPlaceholder), appsCount=\(apps.count), firstApp=\(apps.first?.name ?? "none"), date=\(date)")
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        if renderingMode == .accented {
            Color.black
        } else if colorScheme == .dark {
            Color.spananiWidgetBackgroundDark
        } else {
            Color.spananiWidgetBackgroundLight
        }
    }
}

// In tinted/clear mode: luminanceToAlpha converts pixel brightness → opacity so
// the system can overlay the accent colour. Must come BEFORE the mask so the
// squircle corners are clipped after conversion (reverse order = corner bleed).
// widgetAccentable() opts the result into the accent group.
private struct AppIconView: View
{
    let icon: UIImage?
    let imageHeight: CGFloat

    var body: some View {
        let image = icon ?? UIImage(named: "SideStore") ?? UIImage(systemName: "app.fill")!
        let cornerRadius = imageHeight / 5.0
        Image(uiImage: image)
            .resizable()
            .aspectRatio(CGSize(width: 1, height: 1), contentMode: .fit)
            .frame(height: imageHeight)
            .luminanceToAlphaInAccentedMode()
            .mask(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.primary.opacity(0.15), lineWidth: 1.5)
            )
            .widgetAccentableIfAvailable()
    }
}

@available(iOS 17, *)
#Preview(as: .systemSmall) {
    AppDetailWidget()
} timeline: {
    let expiredDate = Date().addingTimeInterval(1 * 60 * 60 * 24 * 7)
    let (altstore, _, _, longAltStore, _, _) = AppSnapshot.makePreviewSnapshots()
    AppsEntry<Void>(date: Date(), apps: [altstore])
    AppsEntry<Void>(date: Date(), apps: [longAltStore])
    
    AppsEntry<Void>(date: expiredDate, apps: [altstore])
    
    AppsEntry<Void>(date: Date(), apps: [])
    AppsEntry<Void>(date: Date(), apps: [], isPlaceholder: true)
}
