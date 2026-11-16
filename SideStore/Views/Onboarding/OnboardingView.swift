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
                                Circle().stroke(Color.white.opacity(0.08), lineWidth: 1)
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

// MARK: - Hero Glow Helper

private struct HeroGlow: View {
    var color: Color = .brand

    var body: some View {
        Circle()
            .fill(
                RadialGradient(
                    colors: [
                        color.opacity(0.35),
                        color.opacity(0.12),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 8,
                    endRadius: 75
                )
            )
            .frame(width: 150, height: 150)
            .blur(radius: 12)
    }
}

// MARK: - Welcome Step

private struct WelcomeStep: View {
    let onNext: () -> Void
    @State private var isBreathing = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            heroIcon

            headerTexts

            featureTiles

            Spacer()

            startButton
        }
    }

    private var heroIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.brand.opacity(0.35),
                            Color.brand.opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 10,
                        endRadius: 90
                    )
                )
                .frame(width: 180, height: 180)
                .blur(radius: 12)

            Image(uiImage: UIImage(named: "AppIcon") ?? UIImage(named: "AppIcon60x60") ?? UIImage(systemName: "app.fill")!)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
                .shadow(color: Color.brand.opacity(0.35), radius: 18, x: 0, y: 8)
                .scaleEffect(isBreathing ? 1.05 : 1.0)
                .animation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true), value: isBreathing)
        }
        .onAppear {
            isBreathing = true
        }
    }

    private var headerTexts: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("Willkommen im spanani Store", comment: ""))
                .font(.brand(32, .extrabold))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)

            Text(NSLocalizedString("Apps direkt auf deinem iPhone installieren und auffrischen, ganz ohne Computer.", comment: ""))
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
                title: NSLocalizedString("Direktes Sideloading", comment: ""),
                description: NSLocalizedString("Installiere und aktualisiere Apps über einen lokalen VPN-Tunnel direkt auf deinem Gerät.", comment: "")
            )

            FeatureTile(
                icon: "doc.badge.gearshape",
                color: .accent,
                title: NSLocalizedString("Geräte-Kopplung", comment: ""),
                description: String(
                    format: NSLocalizedString("Eine einmalige Pairing-Datei verbindet den Store mit den Diensten deines %@.", comment: ""),
                    ProcessInfo.processInfo.platformName
                )
            )

            FeatureTile(
                icon: "person.crop.circle.badge.checkmark",
                color: .success,
                title: NSLocalizedString("Eigene Signierung", comment: ""),
                description: NSLocalizedString("Verwende deine eigene Apple-ID, um Apps mit Standard-Entwicklerzertifikaten zu signieren.", comment: "")
            )
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 24)
    }

    private var startButton: some View {
        SwiftUI.Button(action: onNext) {
            Text(NSLocalizedString("Los geht's", comment: ""))
                .font(.brand(17, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(Color.brand)
                .clipShape(Capsule())
                .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 4)
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
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Pairing File Step

private struct PairingFileStep: View {
    let onNext: () -> Void
    @State private var hasPairingFile = PairingFileManager.shared.hasPairingFile()
    @State private var isShowingFilePicker = false
    @State private var errorMessage: String? = nil

    private let contentTypes: [UTType] = PairingFileManager.supportedContentTypes

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            heroIcon

            headerTexts

            statusAndActions

            Spacer()

            bottomButtons
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

    private var heroIcon: some View {
        ZStack {
            HeroGlow(color: hasPairingFile ? .success : .brand)

            Image(systemName: hasPairingFile ? "checkmark.seal.fill" : "doc.badge.gearshape.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(hasPairingFile ? .success : .brand)
                .animation(.easeInOut, value: hasPairingFile)
        }
    }

    private var headerTexts: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("Pairing-Datei", comment: ""))
                .font(.brand(32, .extrabold))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)

            Text(String(
                format: NSLocalizedString("Der Store benötigt eine Pairing-Datei (.mobiledevicepairing oder .plist) von deinem Computer, um mit den %@-Diensten zu kommunizieren.", comment: ""),
                ProcessInfo.processInfo.platformName
            ))
            .font(.system(size: 15))
            .foregroundColor(.inkSoft)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var statusAndActions: some View {
        VStack(spacing: 12) {
            if hasPairingFile {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text(NSLocalizedString("Pairing-Datei erkannt und geladen.", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.ink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.success.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.success.opacity(0.25), lineWidth: 1)
                )
            }

            #if !os(tvOS)
            SwiftUI.Button(action: { isShowingFilePicker = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.arrow.down")
                    Text(hasPairingFile
                        ? NSLocalizedString("Andere Datei wählen", comment: "")
                        : NSLocalizedString("Pairing-Datei auswählen", comment: ""))
                }
                .font(.brand(16, .semibold))
                .foregroundColor(.brand)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 48)
                .background(Color.paperRaised)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.brand.opacity(0.3), lineWidth: 1)
                )
            }

            SwiftUI.Button(action: {
                UIApplication.shared.open(AppConstants.URLs.pairingDocumentation)
            }) {
                Text(NSLocalizedString("Wie erhalte ich eine Pairing-Datei?", comment: ""))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.accent)
            }
            #endif

            if let errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 24)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Weiter", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(hasPairingFile ? Color.brand : Color.brand.opacity(0.35))
                    .clipShape(Capsule())
                    .shadow(color: hasPairingFile ? Color.brand.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 4)
            }
            .disabled(!hasPairingFile)

            if !hasPairingFile {
                SwiftUI.Button(action: onNext) {
                    Text(NSLocalizedString("Später einrichten", comment: ""))
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

            heroIcon

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

    private var heroIcon: some View {
        ZStack {
            HeroGlow(color: isConnected ? .success : .brand)

            ZStack(alignment: .bottomTrailing) {
                if let uiImage = UIImage(named: "LocalDevVPN") {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 88, height: 88)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(Color.white.opacity(0.12), lineWidth: 1)
                        )
                        .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 4)
                } else {
                    Image(systemName: "network")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundColor(.brand)
                }

                if isConnected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.success)
                        .background(Circle().fill(Color.paper))
                        .offset(x: 4, y: 4)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut, value: isConnected)
        }
    }

    private var headerTexts: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("LocalDevVPN", comment: ""))
                .font(.brand(32, .extrabold))
                .foregroundColor(.ink)

            Text(NSLocalizedString("Der Store kommuniziert über ein lokales Loopback-VPN mit Diensten auf dem Gerät. Aktiviere LocalDevVPN vor der Überprüfung.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var statusAndActions: some View {
        VStack(spacing: 12) {
            if isConnected {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.success)
                    Text(NSLocalizedString("LocalDevVPN ist verbunden.", comment: ""))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.ink)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.success.opacity(0.12))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(Color.success.opacity(0.25), lineWidth: 1)
                )
            } else {
                SwiftUI.Button(action: verifyVPN) {
                    HStack(spacing: 8) {
                        Image(systemName: "bolt.horizontal.fill")
                        Text(NSLocalizedString("VPN überprüfen", comment: ""))
                    }
                    .font(.brand(16, .semibold))
                    .foregroundColor(.brand)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 48)
                    .background(Color.paperRaised)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.brand.opacity(0.3), lineWidth: 1)
                    )
                }
            }

            if let errorMessage {
                VStack(spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.warning)
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.inkSoft)
                    }
                    .multilineTextAlignment(.center)

                    if !isInstalled {
                        SwiftUI.Button(action: {
                            UIApplication.shared.open(appStoreURL)
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.down.app")
                                Text(NSLocalizedString("LocalDevVPN im App Store laden", comment: ""))
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.accent)
                        }
                    }
                }
                .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 24)
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Weiter", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(isConnected ? Color.brand : Color.brand.opacity(0.35))
                    .clipShape(Capsule())
                    .shadow(color: isConnected ? Color.brand.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 4)
            }
            .disabled(!isConnected)

            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Später einrichten", comment: ""))
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
            if isInstalled, errorMessage == NSLocalizedString("LocalDevVPN ist auf diesem Gerät nicht installiert.", comment: "") {
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
                    errorMessage = NSLocalizedString("LocalDevVPN ist auf diesem Gerät nicht installiert.", comment: "")
                }
            }
        } else {
            UIApplication.shared.open(vpnConnectURL, options: [:]) { success in
                if !success {
                    errorMessage = NSLocalizedString("LocalDevVPN ist auf diesem Gerät nicht installiert.", comment: "")
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

            heroIcon

            headerTexts

            statusAndActions

            Spacer()

            bottomButtons
        }
    }

    private var heroIcon: some View {
        ZStack {
            HeroGlow(color: isAuthenticated ? .success : .brand)

            Image(systemName: isAuthenticated ? "person.crop.circle.badge.checkmark" : "person.crop.circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(isAuthenticated ? .success : .brand)
                .animation(.easeInOut, value: isAuthenticated)
        }
    }

    private var headerTexts: some View {
        VStack(spacing: 8) {
            Text(NSLocalizedString("Apple-ID", comment: ""))
                .font(.brand(32, .extrabold))
                .foregroundColor(.ink)

            Text(NSLocalizedString("Der Store benötigt eine Apple-ID, um Entwicklerzertifikate und Bereitstellungsprofile zum Signieren von Apps zu erstellen.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder
    private var statusAndActions: some View {
        if isAuthenticated {
            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.success)
                Text(AuthManager.shared.currentAppleID ?? NSLocalizedString("Angemeldet", comment: ""))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.success.opacity(0.12))
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(Color.success.opacity(0.25), lineWidth: 1)
            )
        } else {
            VStack(spacing: 12) {
                SwiftUI.Button(action: signIn) {
                    HStack(spacing: 8) {
                        if isSigningIn {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 4)
                        } else {
                            Image(systemName: "key.fill")
                        }
                        Text(NSLocalizedString("Mit Apple-ID anmelden", comment: ""))
                    }
                    .font(.brand(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(Color.brand)
                    .clipShape(Capsule())
                    .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 4)
                }
                .disabled(isSigningIn)

                if let errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundColor(.danger)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
            }
            .frame(maxWidth: 420)
            .padding(.horizontal, 24)
        }
    }

    private var bottomButtons: some View {
        VStack(spacing: 12) {
            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Weiter", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 52)
                    .background(isAuthenticated ? Color.brand : Color.brand.opacity(0.35))
                    .clipShape(Capsule())
                    .shadow(color: isAuthenticated ? Color.brand.opacity(0.3) : Color.clear, radius: 12, x: 0, y: 4)
            }
            .disabled(!isAuthenticated && !isSigningIn)

            SwiftUI.Button(action: onNext) {
                Text(NSLocalizedString("Später einrichten", comment: ""))
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

            heroIcon

            headerTexts

            summaryCard

            Spacer()

            finishButton
        }
    }

    private var heroIcon: some View {
        ZStack {
            HeroGlow(color: hasPairingFile ? .success : .warning)

            Image(systemName: hasPairingFile ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
                .foregroundColor(hasPairingFile ? .success : .warning)
        }
    }

    private var headerTexts: some View {
        VStack(spacing: 8) {
            Text(hasPairingFile
                ? NSLocalizedString("Alles bereit!", comment: "")
                : NSLocalizedString("Einrichtung unvollständig", comment: ""))
                .font(.brand(32, .extrabold))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)

            Text(hasPairingFile
                ? NSLocalizedString("Die Einrichtung ist abgeschlossen. Du kannst jetzt Apps installieren und auffrischen.", comment: "")
                : NSLocalizedString("Du kannst den spanani Store öffnen, aber eine Pairing-Datei ist erforderlich, um Apps zu installieren oder aufzufrischen.", comment: ""))
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
    }

    private var summaryCard: some View {
        VStack(spacing: 14) {
            summaryRow(
                title: NSLocalizedString("Pairing-Datei", comment: ""),
                isConfigured: hasPairingFile,
                warning: NSLocalizedString("Erforderlich vor dem Installieren oder Auffrischen von Apps", comment: "")
            )

            Divider()
                .overlay(Color.white.opacity(0.08))

            summaryRow(
                title: NSLocalizedString("Apple-ID", comment: ""),
                isConfigured: isAuthenticated,
                warning: NSLocalizedString("Kann jederzeit in den Einstellungen hinzugefügt werden", comment: "")
            )
        }
        .padding(18)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
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
                    Text(NSLocalizedString("Konfiguriert", comment: ""))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.success)
                } else {
                    Text(NSLocalizedString("Nicht konfiguriert", comment: ""))
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
            Text(NSLocalizedString("spanani Store öffnen", comment: ""))
                .font(.brand(17, .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
                .background(Color.brand)
                .clipShape(Capsule())
                .shadow(color: Color.brand.opacity(0.3), radius: 12, x: 0, y: 4)
        }
        .frame(maxWidth: 420)
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
}
