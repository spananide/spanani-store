//
//  AuthenticationViewController.swift
//  AltStore
//
//  Created for spanani Store.
//

@preconcurrency import UIKit
import SwiftUI
import SideSign
import SpananiUI

#if !os(tvOS)

private enum AuthenticationField: Hashable
{
    case email
    case password
}

@MainActor
final class AuthenticationViewModel: ObservableObject
{
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var isAuthenticated: Bool = false
    @Published var errorMessage: String? = nil

    var authenticationHandler: ((String, String, @escaping (Result<(ALTAccount, ALTAppleAPISession), Error>) -> Void) -> Void)?
    var completionHandler: (((ALTAccount, ALTAppleAPISession, String)?) -> Void)?
    var onCancel: (() -> Void)?

    var trimmedCredentials: (String, String)?
    {
        let trimmedEmail = self.email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = self.password.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !trimmedPassword.isEmpty else {
            return nil
        }
        return (trimmedEmail, trimmedPassword)
    }

    var canSubmit: Bool
    {
        return self.trimmedCredentials != nil && !self.isLoading && !self.isAuthenticated
    }

    func authenticate()
    {
        // needs proper testing on physical device
        guard let (trimmedEmail, trimmedPassword) = self.trimmedCredentials,
              !self.isLoading,
              !self.isAuthenticated
        else {
            return
        }

        self.isLoading = true
        self.errorMessage = nil

        guard let authHandler = self.authenticationHandler else {
            self.isLoading = false
            self.errorMessage = "Authentifizierung fehlgeschlagen: Kein Handler konfiguriert."
            return
        }

        authHandler(trimmedEmail, trimmedPassword) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }

                switch result {
                case .failure(let error):
                    if let devError = error as? DeveloperPortalError {
                        switch devError {
                        case .userCancelled:
                            debugLog("AuthenticationViewController: Two-factor authentication cancelled by user.")
                            self.isLoading = false
                            return
                        case .accountRepairRequired(_, _):
                            debugLog("AuthenticationViewController: Account repair cancelled by user.")
                            self.isLoading = false
                            return
                        default:
                            break
                        }
                    }

                    debugLog("AuthenticationViewController: Authentication failed with error: \(error)")
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription

                case .success((let account, let session)):
                    debugLog("AuthenticationViewController: Successfully authenticated.")
                    self.isLoading = false
                    self.isAuthenticated = true
                    self.completionHandler?((account, session, trimmedPassword))
                }
            }
        }
    }

    func cancel()
    {
        self.onCancel?()
    }
}

private struct AuthenticationView: View
{
    @ObservedObject var viewModel: AuthenticationViewModel
    @FocusState private var focusedField: AuthenticationField?

    var body: some View
    {
        ZStack(alignment: .top) {
            Color.paper
                .ignoresSafeArea()

            GradientBackdrop(tint: .brand)
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    self.topBar

                    self.headerSection

                    self.fieldsSection

                    if let errorMessage = self.viewModel.errorMessage {
                        self.errorCard(message: errorMessage)
                    }

                    self.submitSection

                    self.infoCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .frame(maxWidth: 420)
                .frame(maxWidth: .infinity)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var topBar: some View
    {
        HStack {
            Button {
                self.viewModel.cancel()
            } label: {
                Text("Schließen")
                    .font(.brand(14, .semibold))
                    .foregroundColor(.inkSoft)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.paperRaised)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var headerSection: some View
    {
        VStack(spacing: 16) {
            self.brandChip

            VStack(spacing: 8) {
                Text("Mit Apple-ID anmelden")
                    .font(.brand(30, .extrabold))
                    .foregroundColor(.ink)
                    .multilineTextAlignment(.center)

                Text("Damit der Store Apps auf deinem iPhone signieren kann.")
                    .font(.system(size: 15))
                    .foregroundColor(.inkSoft)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 16)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var brandChip: some View
    {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.brand)
                .frame(width: 72, height: 72)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.brand.opacity(0.35), radius: 14, x: 0, y: 6)

            SpananiMark()
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
        }
    }

    private var fieldsSection: some View
    {
        VStack(spacing: 12) {
            self.appleIDField
            self.passwordField
        }
    }

    private var appleIDField: some View
    {
        VStack(alignment: .leading, spacing: 6) {
            Text("APPLE-ID")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkFaint)

            TextField("name@beispiel.de", text: self.$viewModel.email)
                .font(.system(size: 16))
                .foregroundColor(.ink)
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .focused(self.$focusedField, equals: .email)
                .submitLabel(.next)
                .onSubmit {
                    self.focusedField = .password
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    self.focusedField == .email ? Color.brand.opacity(0.55) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }

    private var passwordField: some View
    {
        VStack(alignment: .leading, spacing: 6) {
            Text("PASSWORT")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkFaint)

            SecureField("Passwort", text: self.$viewModel.password)
                .font(.system(size: 16))
                .foregroundColor(.ink)
                .textContentType(.password)
                .focused(self.$focusedField, equals: .password)
                .submitLabel(.go)
                .onSubmit {
                    if self.viewModel.canSubmit {
                        self.focusedField = nil
                        self.viewModel.authenticate()
                    }
                }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(
                    self.focusedField == .password ? Color.brand.opacity(0.55) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
        )
    }

    private func errorCard(message: String) -> some View
    {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.danger)

                Text("Anmeldung fehlgeschlagen")
                    .font(.brand(15, .semibold))
                    .foregroundColor(.danger)
            }

            Text(message)
                .font(.system(size: 13))
                .foregroundColor(.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.danger.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.danger.opacity(0.28), lineWidth: 1)
        )
    }

    private var submitSection: some View
    {
        Button {
            self.focusedField = nil
            self.viewModel.authenticate()
        } label: {
            HStack(spacing: 8) {
                if self.viewModel.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else if self.viewModel.isAuthenticated {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(self.viewModel.isAuthenticated ? "Angemeldet" : "Anmelden")
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(self.buttonBackground)
            .clipShape(Capsule())
            .shadow(color: self.buttonShadowColor, radius: 12, x: 0, y: 4)
        }
        .disabled(!self.viewModel.canSubmit && !self.viewModel.isAuthenticated)
        .buttonStyle(.plain)
    }

    private var buttonBackground: Color
    {
        if self.viewModel.isAuthenticated {
            return Color.success
        } else if self.viewModel.canSubmit {
            return Color.brand
        } else {
            return Color.brand.opacity(0.35)
        }
    }

    private var buttonShadowColor: Color
    {
        if self.viewModel.isAuthenticated {
            return Color.success.opacity(0.3)
        } else if self.viewModel.canSubmit {
            return Color.brand.opacity(0.3)
        } else {
            return Color.clear
        }
    }

    private var infoCard: some View
    {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)

                Text("Warum brauchen wir das?")
                    .font(.brand(14, .semibold))
                    .foregroundColor(.ink)
            }

            Text("Mit deiner Apple-ID richten wir Apps auf diesem Gerät ein. Deine Zugangsdaten werden sicher im Schlüsselbund gespeichert und nur an Apple gesendet.")
                .font(.system(size: 13))
                .foregroundColor(.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.paperRaised.opacity(0.65))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}

final class AuthenticationViewController: UIViewController
{
    var authenticationHandler: ((String, String, @escaping (Result<(ALTAccount, ALTAppleAPISession), Error>) -> Void) -> Void)? {
        didSet {
            self.viewModel.authenticationHandler = self.authenticationHandler
        }
    }

    var completionHandler: (((ALTAccount, ALTAppleAPISession, String)?) -> Void)? {
        didSet {
            self.viewModel.completionHandler = self.completionHandler
        }
    }

    private let viewModel = AuthenticationViewModel()

    override func viewDidLoad()
    {
        super.viewDidLoad()

        // fetch anisette servers asap when loading Auth Screen (if list is empty)
        Task {
            if await AnisetteServersManager.shared.getActiveServerURLs().isEmpty {
                let sourceURL = UserDefaults.standard.menuAnisetteList
                do {
                    _ = try await AnisetteServersManager.shared.syncWithRemote(sourceURLString: sourceURL, forceRemote: true)
                    debugLog("AuthenticationViewController: Server list refresh request completed for sourceURL: \(sourceURL)")
                } catch {
                    debugLog("AuthenticationViewController: Server list refresh request Failed for sourceURL: \(sourceURL) Error: \(error)")
                }
            }
        }

        SpananiFont.register()

        self.view.backgroundColor = .clear

        self.viewModel.authenticationHandler = self.authenticationHandler
        self.viewModel.completionHandler = self.completionHandler
        self.viewModel.onCancel = { [weak self] in
            self?.dismiss(animated: true) { [weak self] in
                self?.completionHandler?(nil)
            }
        }

        let authView = AuthenticationView(viewModel: self.viewModel)
        let hostingController = UIHostingController(rootView: authView)
        hostingController.view.backgroundColor = .clear

        self.addChild(hostingController)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(hostingController.view)

        NSLayoutConstraint.activate([
            hostingController.view.topAnchor.constraint(equalTo: self.view.topAnchor),
            hostingController.view.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
        ])

        hostingController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        self.viewModel.isLoading = false
    }
}

#else

final class AuthenticationViewController: UIViewController
{
    var authenticationHandler: ((String, String, @escaping (Result<(ALTAccount, ALTAppleAPISession), Error>) -> Void) -> Void)?
    var completionHandler: (((ALTAccount, ALTAppleAPISession, String)?) -> Void)?
}

#endif
