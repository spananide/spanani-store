//
//  SplashView.swift
//  SideStore
//
//  Created by Magesh K on 14/8/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import SpananiUI
import SwiftUI

@MainActor
final class SplashViewModel: ObservableObject {
    @Published var status: String = ""

    func updateStatus(_ text: String) {
        status = text
    }
}

struct SplashView: View {
    @ObservedObject var viewModel: SplashViewModel
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            #if !os(tvOS)
                Color.paper
                    .ignoresSafeArea()
            #else
                Color.black
                    .ignoresSafeArea()
            #endif

            VStack(spacing: 20) {
                Spacer()

                SpananiMark()
                    .frame(width: 96, height: 96)
                    .foregroundStyle(Color.brand)
                    .shadow(color: Color.brand.opacity(0.35), radius: 18, x: 0, y: 8)
                    .scaleEffect(isPulsing ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.8).repeatForever(autoreverses: true),
                        value: isPulsing
                    )

                Text(NSLocalizedString("spanani Store", comment: ""))
                    .font(.brand(28, .extrabold))
                    .foregroundColor(.ink)

                Spacer()

                if !viewModel.status.isEmpty {
                    Text(localizedStatus(viewModel.status))
                        .font(.system(size: 14))
                        .foregroundColor(.inkSoft)
                        .transition(.opacity)
                }
            }
            .padding(.bottom, 48)
        }
        .onAppear {
            // needs proper testing on physical device
            SpananiFont.register()
            isPulsing = true
        }
    }

    private func localizedStatus(_ status: String) -> String {
        switch status {
        case "Starting…", "Starting...":
            return NSLocalizedString("Wird gestartet…", comment: "")
        case "Loading apps…", "Loading apps...":
            return NSLocalizedString("Apps werden geladen…", comment: "")
        case "Updating sources…", "Updating sources...":
            return NSLocalizedString("Quellen werden aktualisiert…", comment: "")
        case "Almost there…", "Almost there...":
            return NSLocalizedString("Gleich fertig…", comment: "")
        default:
            return status
        }
    }
}
