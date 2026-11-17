//
//  OnboardingView.swift
//  SideStore
//
//  Created by SternXD on 9/13/26.
//  Copyright © 2026 SideStore. All rights reserved.
//

import Minimuxer
import SpananiUI
import SwiftUI
import UniformTypeIdentifiers

struct OnboardingView: View {
    var onFinish: (() -> Void)? = nil
    @State private var currentStep = 0
    private let totalSteps = 5

    var body: some View {
        ZStack {
            #if !os(tvOS)
                Color.paper.ignoresSafeArea()
            #else
                Color.black.ignoresSafeArea()
            #endif

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                TabView(selection: $currentStep) {
                    WelcomeStep(onNext: { currentStep += 1 })
                        .tag(0)

                    PairingFileStep(onNext: { currentStep += 1 })
                        .tag(1)

                    LocalDevVPNStep(onNext: { currentStep += 1 })
                        .tag(2)

                    AppleIDStep(onNext: { currentStep += 1 })
                        .tag(3)

                    CompleteStep(onFinish: complete)
                        .tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut(duration: 0.25), value: currentStep)
                #if !os(tvOS)
                    .highPriorityGesture(
                        DragGesture().onEnded { value in
                            if value.translation.width > 50, currentStep > 0, currentStep < totalSteps - 1 {
                                withAnimation(.easeInOut(duration: 0.25)) {
                                    currentStep -= 1
                                }
                            }
                        }
                    )
                #endif
            }
        }
        .onAppear {
            SpananiFont.register()
        }
    }

    private var topBar: some View {
        ZStack {
            HStack(spacing: 6) {
                ForEach(0 ..< totalSteps, id: \.self) { index in
                    Capsule()
                        .fill(index <= currentStep ? Color.brand : Color.inkFaint.opacity(0.25))
                        .frame(width: index == currentStep ? 20 : 6, height: 6)
                        .animation(.spring(response: 0.35, dampingFraction: 0.75), value: currentStep)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.paperSunk)
            .clipShape(Capsule())

            if currentStep > 0 && currentStep < totalSteps - 1 {
                HStack {
                    SwiftUI.Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep -= 1
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.ink)
                            .frame(width: 34, height: 34)
                            .background(Color.paperRaised)
                            .clipShape(Circle())
                            .overlay(
                                Circle().stroke(Color.paperSunk, lineWidth: 1)
                            )
                    }
                    Spacer()
                }
            }
        }
        .frame(height: 44)
    }

    private func complete() {
        UserDefaults.standard.hasCompletedOnboarding = true
        UserDefaults.standard.synchronize()
        onFinish?()
    }
}

// MARK: - Step Icon Tile

private struct StepIconTile: View {
    let symbol: String
    var color: Color = .brand
    var size: CGFloat = 88
    var cornerRadius: CGFloat = 20

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .frame(width: size, height: size)
                .offset(x: 5, y: 5)

            ZStack {
                Color.paperRaised
                Image(systemName: symbol)
                    .font(.system(size: size * 0.42, weight: .bold))
                    .foregroundColor(color)
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Welcome Step

private struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            Mark3DTile(size: 132)

            headerTexts

            featureTiles

            Spacer()

            startButton
        }
    }

    private var headerTexts: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("Welcome to spanani Store", comment: ""))
                .font(.brand(30, .extrabold))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)

            Text(NSLocalizedString("Install and refresh apps directly on your device, without a computer.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var featureTiles: some View {
        VStack(alignment: .leading, spacing: 12) {
            FeatureTile(
                icon: "arrow.triangle.2.circlepath",
                color: .brand,
                title: NSLocalizedString("Direct Sideloading", comment: ""),
                description: NSLocalizedString("Install and refresh apps directly on your device using a local VPN tunnel.", comment: "")
            )

            FeatureTile(
                icon: "doc.badge.gearshape",
                color: .accent,
                title: NSLocalizedString("Device Pairing", comment: ""),
                description: String(
                    format: NSLocalizedString("A one-time pairing file connects the store with services on your %@.", comment: ""),
                    ProcessInfo.processInfo.platformName
                )
            )

            FeatureTile(
                icon: "person.crop.circle.badge.checkmark",
                color: .success,
                title: NSLocalizedString("Personal Signing", comment: ""),
                description: NSLocalizedString("Use your own Apple ID to sign apps with standard developer certificates.", comment: "")
            )
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 24)
    }

    private var startButton: some View {
        SwiftUI.Button(action: onNext) {
            Text(NSLocalizedString("Continue", comment: ""))
                .font(.brand(17, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(Color.brand)
                .clipShape(Capsule())
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

private struct FeatureTile: View {
    let icon: String
    let color: Color
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(color.opacity(0.16))
                    .frame(width: 40, height: 40)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.brand(16, .semibold))
                    .foregroundColor(.ink)
                Text(description)
                    .font(.system(size: 13))
                    .foregroundColor(.inkSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
    }
}

// MARK: - Pairing File Step

private struct PairingFileStep: View {
    let onNext: () -> Void
    @State private var hasPairingFile = PairingFileManager.shared.adoptPlacedPairingFile()
    @State private var isShowingFilePicker = false
    @State private var errorMessage: String? = nil

    private let contentTypes: [UTType] = PairingFileManager.supportedContentTypes

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            StepIconTile(
                symbol: hasPairingFile ? "checkmark.seal.fill" : "doc.badge.gearshape.fill",
                color: hasPairingFile ? .success : .brand
            )

            headerTexts

            statusAndActions

            Spacer()

            bottomButtons
        }
        .onAppear {
            hasPairingFile = PairingFileManager.shared.adoptPlacedPairingFile()
            startEngineIfNeeded()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            hasPairingFile = PairingFileManager.shared.adoptPlacedPairingFile()
            startEngineIfNeeded()
        }
        #if !os(tvOS)
        .fileImporter(
            isPresented: $isShowingFilePicker,
            allowedContentTypes: contentTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case let .success(urls):
                guard let url = urls.first else { return }
                do {
                    try PairingFileManager.shared.importPairingFile(from: url)
                    hasPairingFile = true
                    errorMessage = nil
                    startEngineIfNeeded()
                    onNext()
                } catch {
                    errorMessage = error.localizedDescription
                }
            case let .failure(error):
                errorMessage = error.localizedDescription
            }
        }
        #endif
    }

    private func startEngineIfNeeded() {
        Task { _ = await AppBootManager.shared.ensureMinimuxerStarted() }
    }

    private var headerTexts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Pairing File", comment: ""))
                .font(.brand(30, .extrabold))
                .foregroundColor(.ink)

            Text(String(
                format: NSLocalizedString("The store requires a pairing file (.mobiledevicepairing or .plist) from your computer to communicate with %@ services.", comment: ""),
                ProcessInfo.processInfo.platformName
            ))
            .font(.system(size: 15))
            .foregroundColor(.inkSoft)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var statusAndActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if hasPairingFile {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text(NSLocalizedString("Pairing file detected and loaded.", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.success)
                }
            }

            #if !os(tvOS)
            SwiftUI.Button(action: { isShowingFilePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text(hasPairingFile
                        ? NSLocalizedString("Choose different file", comment: "")
                        : NSLocalizedString("Import pairing file", comment: ""))
                }
                .font(.brand(16, .semibold))
                .foregroundColor(.brand)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(Color.paperRaised)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.paperSunk, lineWidth: 1)
                )
            }

            HStack {
                Spacer()
                SwiftUI.Button(action: {
                    UIApplication.shared.open(AppConstants.URLs.pairingDocumentation)
                }) {
                    Text(NSLocalizedString("How do I get a pairing file?", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.accent)
                }
                Spacer()
            }
            #endif

            if let errorMessage {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.danger)
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.danger)
                }
            }
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Continue", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(hasPairingFile ? Color.brand : Color.brand.opacity(0.35))
                    .clipShape(Capsule())
            }
            .disabled(!hasPairingFile)

            if !hasPairingFile {
                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Set up later", comment: ""))
                        .font(.brand(15, .semibold))
                        .foregroundColor(.inkSoft)
                }
            }
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - LocalDevVPN Step

private struct LocalDevVPNStep: View {
    let onNext: () -> Void
    @State private var isConnected = false
    @State private var errorMessage: String? = nil

    private let vpnSchemeURL = URL(string: "localdevvpn://")!
    private let vpnConnectURL = URL(string: "localdevvpn://enable?scheme=sidestore")!
    private let appStoreURL = URL(string: "https://apps.apple.com/app/localdevvpn/id6755608044")!

    private var isInstalled: Bool {
        UIApplication.shared.canOpenURL(vpnSchemeURL)
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            StepIconTile(
                symbol: isConnected ? "checkmark.circle.fill" : "network",
                color: isConnected ? .success : .brand
            )

            headerTexts

            statusAndActions

            Spacer()

            bottomButtons
        }
        .onAppear {
            checkStatus()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            checkStatus()
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                checkStatus()
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                checkStatus()
            }
        }
    }

    private var headerTexts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("LocalDevVPN", comment: ""))
                .font(.brand(30, .extrabold))
                .foregroundColor(.ink)

            Text(NSLocalizedString("The store communicates with on-device services through a local loopback VPN. Enable LocalDevVPN before verifying.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var statusAndActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text(NSLocalizedString("LocalDevVPN is connected.", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.success)
                }
            } else {
                SwiftUI.Button(action: verifyVPN) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.horizontal.fill")
                        Text(NSLocalizedString("Open LocalDevVPN", comment: ""))
                    }
                    .font(.brand(16, .semibold))
                    .foregroundColor(.brand)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(Color.paperRaised)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.paperSunk, lineWidth: 1)
                    )
                }
            }

            if let errorMessage {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.warning)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.inkSoft)
                    }

                    if !isInstalled {
                        SwiftUI.Button(action: {
                            UIApplication.shared.open(appStoreURL)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.app")
                                Text(NSLocalizedString("Get LocalDevVPN from App Store", comment: ""))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accent)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Continue", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(isConnected ? Color.brand : Color.brand.opacity(0.35))
                    .clipShape(Capsule())
            }
            .disabled(!isConnected)

            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Set up later", comment: ""))
                    .font(.brand(15, .semibold))
                    .foregroundColor(.inkSoft)
            }
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func checkStatus() {
        // needs proper testing on physical device with LocalDevVPN
        let interfaces = Minimuxer.shared.network.activeInterfaces
        let hasVpnTunnel = interfaces.contains { info in
            info.name.lowercased().hasPrefix("utun") && info.ip.hasPrefix("10.7.")
        }

        if hasVpnTunnel {
            isConnected = true
            errorMessage = nil
            return
        }

        let targetIp = ConnectionConfig.shared.tunnelPeerIp ?? "10.7.0.1"
        if !targetIp.isEmpty, Minimuxer.shared.core.testDeviceConnection(ifaddr: targetIp, timeout: 200) {
            isConnected = true
            errorMessage = nil
        } else {
            isConnected = false
            if isInstalled, errorMessage == NSLocalizedString("LocalDevVPN is not installed on this device.", comment: "") {
                errorMessage = nil
            }
        }
    }

    private func verifyVPN() {
        checkStatus()
        if isConnected {
            errorMessage = nil
            return
        }

        if isInstalled {
            errorMessage = nil
            UIApplication.shared.open(vpnConnectURL, options: [:]) { success in
                if !success {
                    errorMessage = NSLocalizedString("LocalDevVPN is not installed on this device.", comment: "")
                }
            }
        } else {
            UIApplication.shared.open(vpnConnectURL, options: [:]) { success in
                if !success {
                    errorMessage = NSLocalizedString("LocalDevVPN is not installed on this device.", comment: "")
                }
            }
        }
    }
}

// MARK: - Apple ID Step

private struct AppleIDStep: View {
    let onNext: () -> Void
    @State private var isAuthenticated = AuthManager.shared.isAuthenticated
    @State private var isSigningIn = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            StepIconTile(
                symbol: isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle",
                color: isAuthenticated ? .success : .brand
            )

            headerTexts

            statusAndActions

            Spacer()

            bottomButtons
        }
    }

    private var headerTexts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(NSLocalizedString("Apple ID", comment: ""))
                .font(.brand(30, .extrabold))
                .foregroundColor(.ink)

            Text(NSLocalizedString("The store requires an Apple ID to create developer certificates and provisioning profiles for signing apps.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    @ViewBuilder
    private var statusAndActions: some View {
        VStack(alignment: .leading, spacing: 12) {
            if isAuthenticated {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text(AuthManager.shared.currentAppleID ?? NSLocalizedString("Signed In", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.success)
                }
            } else {
                SwiftUI.Button(action: signIn) {
                    HStack(spacing: 8) {
                        if isSigningIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "key.fill")
                        }
                        Text(NSLocalizedString("Sign in with your Apple ID", comment: ""))
                    }
                    .font(.brand(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(Color.brand)
                    .clipShape(Capsule())
                }
                .disabled(isSigningIn)

                if let errorMessage {
                    HStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.danger)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.danger)
                    }
                }
            }
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Continue", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 54)
                    .background(isAuthenticated ? Color.brand : Color.brand.opacity(0.35))
                    .clipShape(Capsule())
            }
            .disabled(!isAuthenticated && !isSigningIn)

            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Set up later", comment: ""))
                    .font(.brand(15, .semibold))
                    .foregroundColor(.inkSoft)
            }
            .disabled(isSigningIn)
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }

    private func signIn() {
        Task {
            isSigningIn = true
            errorMessage = nil
            defer { isSigningIn = false }

            do {
                _ = try await AuthManager.shared.signIn(
                    presentingViewController: UIApplication.shared.topViewController(),
                    skipResign: true,
                    skipHowTos: true
                )
                isAuthenticated = true
                onNext()
            } catch {
                if !(error is CancellationError) {
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Complete Step

private struct CompleteStep: View {
    let onFinish: () -> Void

    private var hasPairingFile: Bool {
        PairingFileManager.shared.hasPairingFile()
    }

    private var isAuthenticated: Bool {
        AuthManager.shared.isAuthenticated
    }

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            StepIconTile(
                symbol: hasPairingFile ? "checkmark.circle.fill" : "exclamationmark.triangle.fill",
                color: hasPairingFile ? .success : .warning
            )

            headerTexts

            summaryCard

            Spacer()

            finishButton
        }
    }

    private var headerTexts: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(hasPairingFile
                ? NSLocalizedString("All Done!", comment: "")
                : NSLocalizedString("Setup Incomplete", comment: ""))
                .font(.brand(30, .extrabold))
                .foregroundColor(.ink)

            Text(hasPairingFile
                ? NSLocalizedString("Setup is complete. You can now install and refresh apps.", comment: "")
                : NSLocalizedString("You can open spanani Store, but a pairing file is required to install or refresh apps.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
        }
        .frame(maxWidth: 420)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            summaryRow(
                title: NSLocalizedString("Pairing File", comment: ""),
                isConfigured: hasPairingFile,
                warning: NSLocalizedString("Required before installing or refreshing apps", comment: "")
            )

            Divider()
                .overlay(Color.paperSunk)

            summaryRow(
                title: NSLocalizedString("Apple ID", comment: ""),
                isConfigured: isAuthenticated,
                warning: NSLocalizedString("Can be added anytime in Settings", comment: "")
            )
        }
        .padding(18)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.surface, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.surface, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
    }

    private func summaryRow(title: String, isConfigured: Bool, warning: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: isConfigured ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundColor(isConfigured ? .success : .warning)
                .font(.system(size: 22))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.brand(16, .semibold))
                    .foregroundColor(.ink)

                if isConfigured {
                    Text(NSLocalizedString("Configured", comment: ""))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.success)
                } else {
                    Text(NSLocalizedString("Not configured", comment: ""))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.warning)

                    Text(warning)
                        .font(.system(size: 12))
                        .foregroundColor(.inkSoft)
                }
            }

            Spacer()
        }
    }

    private var finishButton: some View {
        SwiftUI.Button(action: onFinish) {
            Text(NSLocalizedString("Done", comment: ""))
                .font(.brand(17, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 54)
                .background(Color.brand)
                .clipShape(Capsule())
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
