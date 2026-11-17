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

                Mark3DTile(size: 112)

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
        }
    }

    private func localizedStatus(_ status: String) -> String {
        switch status {
        case "Starting…", "Starting...":
            return NSLocalizedString("Starting…", comment: "")
        case "Loading apps…", "Loading apps...":
            return NSLocalizedString("Loading apps…", comment: "")
        case "Updating sources…", "Updating sources...":
            return NSLocalizedString("Updating sources…", comment: "")
        case "Almost there…", "Almost there...":
            return NSLocalizedString("Almost there…", comment: "")
        default:
            return status
        }
    }
}
