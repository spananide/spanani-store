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
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, Spacing.m)
                    .padding(.top, Spacing.s)

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
        .tint(.spananiAccent)
        .onAppear {
            SpananiFont.register()
        }
    }

    private var topBar: some View {
        VStack(alignment: .leading, spacing: Spacing.s) {
            ProgressView(value: Double(currentStep + 1), total: Double(totalSteps))

            HStack {
                if currentStep > 0 && currentStep < totalSteps - 1 {
                    SwiftUI.Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            currentStep -= 1
                        }
                    }) {
                        Label(NSLocalizedString("Back", comment: ""), systemImage: "chevron.left")
                            .labelStyle(.titleAndIcon)
                    }
                }
                Spacer()
            }
            .frame(height: 44)
        }
    }

    private func complete() {
        UserDefaults.standard.hasCompletedOnboarding = true
        UserDefaults.standard.synchronize()
        onFinish?()
    }
}

// MARK: - Welcome Step

private struct WelcomeStep: View {
    let onNext: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(Color.spananiAccent)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(NSLocalizedString("spanani Store", comment: ""))
                    .font(.title.bold())

                Text(NSLocalizedString("Install and refresh apps directly on your device without a computer.", comment: ""))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label(NSLocalizedString("Direct Sideloading", comment: ""), systemImage: "arrow.triangle.2.circlepath")
                        .font(.headline)
                    Text(NSLocalizedString("Install and refresh apps over a local VPN tunnel directly on your device.", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label(NSLocalizedString("Pairing File", comment: ""), systemImage: "doc.badge.gearshape")
                        .font(.headline)
                    Text(String(
                        format: NSLocalizedString("A one-time pairing file connects the store to services on your %@.", comment: ""),
                        ProcessInfo.processInfo.platformName
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label(NSLocalizedString("On-Device Signing", comment: ""), systemImage: "person.crop.circle.badge.checkmark")
                        .font(.headline)
                    Text(NSLocalizedString("Sign apps with your Apple ID using standard developer certificates.", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Continue", comment: ""))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.m)
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
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: hasPairingFile ? "checkmark.seal.fill" : "doc.badge.gearshape")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(hasPairingFile ? .green : Color.spananiAccent)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(NSLocalizedString("Pairing File", comment: ""))
                    .font(.title.bold())

                Text(String(
                    format: NSLocalizedString("The store requires a pairing file (.mobiledevicepairing or .plist) from your computer to communicate with %@ services.", comment: ""),
                    ProcessInfo.processInfo.platformName
                ))
                .font(.body)
                .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                if hasPairingFile {
                    Label(NSLocalizedString("Pairing file detected and loaded.", comment: ""), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                }

                #if !os(tvOS)
                    SwiftUI.Button(action: { isShowingFilePicker = true }) {
                        Label(
                            hasPairingFile
                                ? NSLocalizedString("Choose Different File", comment: "")
                                : NSLocalizedString("Import Pairing File", comment: ""),
                            systemImage: "square.and.arrow.down"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)

                    SwiftUI.Button(action: {
                        UIApplication.shared.open(AppConstants.URLs.pairingDocumentation)
                    }) {
                        Text(NSLocalizedString("How do I get a pairing file?", comment: ""))
                    }
                    .buttonStyle(.plain)
                #endif

                if let errorMessage {
                    Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                        .font(.footnote)
                        .foregroundStyle(.red)
                }
            }

            Spacer()

            VStack(spacing: Spacing.s) {
                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Continue", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!hasPairingFile)

                if !hasPairingFile {
                    SwiftUI.Button(action: onNext) {
                        Text(NSLocalizedString("Set Up Later", comment: ""))
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.m)
        .onAppear { hasPairingFile = PairingFileManager.shared.adoptPlacedPairingFile() }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            hasPairingFile = PairingFileManager.shared.adoptPlacedPairingFile()
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
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: isConnected ? "checkmark.circle.fill" : "network")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(isConnected ? .green : Color.spananiAccent)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(NSLocalizedString("LocalDevVPN", comment: ""))
                    .font(.title.bold())

                Text(NSLocalizedString("The store communicates with on-device services through a local loopback VPN. Enable LocalDevVPN before continuing.", comment: ""))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                if isConnected {
                    Label(NSLocalizedString("LocalDevVPN is connected.", comment: ""), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    SwiftUI.Button(action: verifyVPN) {
                        Label(NSLocalizedString("Open LocalDevVPN", comment: ""), systemImage: "bolt.horizontal.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }

                if let errorMessage {
                    VStack(alignment: .leading, spacing: Spacing.s) {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.orange)

                        if !isInstalled {
                            SwiftUI.Button(action: {
                                UIApplication.shared.open(appStoreURL)
                            }) {
                                Label(NSLocalizedString("Get LocalDevVPN on App Store", comment: ""), systemImage: "arrow.down.app")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Spacer()

            VStack(spacing: Spacing.s) {
                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Continue", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isConnected)

                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Set Up Later", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.m)
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
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: isAuthenticated ? "checkmark.circle.fill" : "person.crop.circle")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(isAuthenticated ? .green : Color.spananiAccent)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(NSLocalizedString("Apple ID", comment: ""))
                    .font(.title.bold())

                Text(NSLocalizedString("The store uses your Apple ID to generate developer certificates and provisioning profiles to sign apps.", comment: ""))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                if isAuthenticated {
                    Label(AuthManager.shared.currentAppleID ?? NSLocalizedString("Signed In", comment: ""), systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                } else {
                    SwiftUI.Button(action: signIn) {
                        HStack(spacing: Spacing.s) {
                            if isSigningIn {
                                ProgressView()
                            } else {
                                Image(systemName: "key.fill")
                            }
                            Text(NSLocalizedString("Sign In with Apple ID", comment: ""))
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    .disabled(isSigningIn)

                    if let errorMessage {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }
            }

            Spacer()

            VStack(spacing: Spacing.s) {
                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Continue", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!isAuthenticated && !isSigningIn)

                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Set Up Later", comment: ""))
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                .disabled(isSigningIn)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.m)
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
        VStack(alignment: .leading, spacing: Spacing.l) {
            Image(systemName: hasPairingFile ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .imageScale(.large)
                .foregroundStyle(hasPairingFile ? .green : .orange)

            VStack(alignment: .leading, spacing: Spacing.s) {
                Text(hasPairingFile
                    ? NSLocalizedString("All Set", comment: "")
                    : NSLocalizedString("Setup Incomplete", comment: ""))
                    .font(.title.bold())

                Text(hasPairingFile
                    ? NSLocalizedString("Setup is complete. You can now install and refresh apps.", comment: "")
                    : NSLocalizedString("You can open the store, but a pairing file is required to install or refresh apps.", comment: ""))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: Spacing.m) {
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label {
                        Text(NSLocalizedString("Pairing File", comment: ""))
                            .font(.headline)
                    } icon: {
                        Image(systemName: hasPairingFile ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(hasPairingFile ? .green : .orange)
                    }

                    Text(hasPairingFile
                        ? NSLocalizedString("Configured", comment: "")
                        : NSLocalizedString("Required before installing or refreshing apps", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(hasPairingFile ? .secondary : .orange)
                        .padding(.leading, Spacing.l)
                }

                VStack(alignment: .leading, spacing: Spacing.xs) {
                    Label {
                        Text(NSLocalizedString("Apple ID", comment: ""))
                            .font(.headline)
                    } icon: {
                        Image(systemName: isAuthenticated ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                            .foregroundStyle(isAuthenticated ? .green : .orange)
                    }

                    Text(isAuthenticated
                        ? NSLocalizedString("Signed In", comment: "")
                        : NSLocalizedString("Can be added anytime in Settings", comment: ""))
                        .font(.subheadline)
                        .foregroundStyle(isAuthenticated ? .secondary : .orange)
                        .padding(.leading, Spacing.l)
                }
            }

            Spacer()

            SwiftUI.Button(action: onFinish) {
                Text(NSLocalizedString("Done", comment: ""))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Spacing.m)
        .padding(.bottom, Spacing.m)
    }
}
