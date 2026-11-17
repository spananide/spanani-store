//
//  Countdown.swift
//  AltWidgetExtension
//
//  Created by Riley Testut on 7/6/20.
//  Copyright © 2020 Riley Testut. All rights reserved.
//

import SwiftUI
import WidgetKit
import UIKit

// MARK: - Spanani Colors

extension Color {
    static let spananiWidgetBackgroundDark = Color(red: 0.086, green: 0.071, blue: 0.114)
    static let spananiWidgetBackgroundLight = Color(red: 0.957, green: 0.949, blue: 0.969)
    static let spananiAccent = Color(red: 0.6, green: 0.333, blue: 0.906)
    static let spananiTextLight = Color(red: 0.102, green: 0.086, blue: 0.133)

    static let spananiWidgetBackground = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor(red: 0.086, green: 0.071, blue: 0.114, alpha: 1.0)
            : UIColor(red: 0.957, green: 0.949, blue: 0.969, alpha: 1.0)
    })

    static let spananiPrimaryText = Color(uiColor: UIColor { traitCollection in
        traitCollection.userInterfaceStyle == .dark
            ? UIColor.white
            : UIColor(red: 0.102, green: 0.086, blue: 0.133, alpha: 1.0)
    })
}

struct Countdown: View
{
    var startDate: Date?
    var endDate: Date?
    var currentDate: Date = Date()
    
    var strokeWidth: Double = 4.0
    
    @Environment(\.font) private var font
    @Environment(\.widgetRenderingMode) private var renderingMode
    
    private var numberOfDays: Int {
        guard let date = self.endDate else { return 0 }
        
        let numberOfDays = date.numberOfCalendarDays(since: self.currentDate)
        return max(numberOfDays, 0) // Never show negative values.
    }
    
    private var fractionComplete: CGFloat {
        guard let startDate = self.startDate, let endDate = self.endDate else { return 1.0 }
        
        let totalNumberOfDays = endDate.numberOfCalendarDays(since: startDate)
        let fractionComplete = CGFloat(self.numberOfDays) / CGFloat(totalNumberOfDays)
        return fractionComplete
    }
        
    @ViewBuilder
    private func overlay(progress: CGFloat) -> some View
    {
        let strokeStyle = StrokeStyle(lineWidth: self.strokeWidth, lineCap: .round, lineJoin: .round)
        
        if self.numberOfDays > 9 || self.numberOfDays < 0 {
            Capsule(style: .continuous)
                .trim(from: 0.0, to: progress)
                .stroke(style: strokeStyle)
        }
        else {
            Circle()
                .trim(from: 0.0, to: progress)
                .rotation(Angle(degrees: -90), anchor: .center)
                .stroke(style: strokeStyle)
        }
    }
    
    var body: some View {
        Text("\(numberOfDays)")
            .font((font ?? .title).monospacedDigit())
            .bold()
            .opacity(endDate != nil ? 1 : 0)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .overlay(
                ZStack {
                    overlay(progress: 1.0)
                        .foregroundStyle(Color.primary.opacity(0.18))
                    
                    if renderingMode == .accented {
                        overlay(progress: fractionComplete)
                    } else {
                        overlay(progress: fractionComplete)
                            .foregroundStyle(Color.spananiAccent)
                    }
                }
            )
    }
}

struct Countdown_Previews: PreviewProvider {
    static var previews: some View {
        let startDate = Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        Group {
            Countdown(startDate: startDate, endDate: Calendar.current.date(byAdding: .day, value: 7, to: startDate))
            Countdown(startDate: startDate, endDate: Calendar.current.date(byAdding: .day, value: 365, to: startDate))
        }
        .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
