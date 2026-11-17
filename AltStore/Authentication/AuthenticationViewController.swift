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
            SwiftUI.Button {
                self.viewModel.cancel()
            } label: {
                Text(NSLocalizedString("Close", comment: ""))
                    .font(.brand(14, .semibold))
                    .foregroundColor(.inkSoft)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.paperRaised)
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().stroke(Color.paperSunk, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Spacer()
        }
    }

    private var headerSection: some View
    {
        VStack(alignment: .leading, spacing: 16) {
            Mark3DTile(size: 88)

            VStack(alignment: .leading, spacing: 8) {
                Text(NSLocalizedString("Sign in with your Apple ID", comment: ""))
                    .font(.brand(30, .extrabold))
                    .foregroundColor(.ink)

                Text(NSLocalizedString("Used to sign apps for this device.", comment: ""))
                    .font(.system(size: 15))
                    .foregroundColor(.inkSoft)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
            Text("APPLE ID")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkFaint)

            TextField("name@example.com", text: self.$viewModel.email)
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    self.focusedField == .email ? Color.brand : Color.paperSunk,
                    lineWidth: 1
                )
        )
    }

    private var passwordField: some View
    {
        VStack(alignment: .leading, spacing: 6) {
            Text("PASSWORD")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkFaint)

            SecureField(NSLocalizedString("Password", comment: ""), text: self.$viewModel.password)
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
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    self.focusedField == .password ? Color.brand : Color.paperSunk,
                    lineWidth: 1
                )
        )
    }

    private func errorCard(message: String) -> some View
    {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.danger)

            VStack(alignment: .leading, spacing: 2) {
                Text(NSLocalizedString("Sign-in failed", comment: ""))
                    .font(.brand(15, .semibold))
                    .foregroundColor(.danger)

                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 13))
                        .foregroundColor(.danger)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var submitSection: some View
    {
        SwiftUI.Button {
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

                Text(self.viewModel.isAuthenticated ? NSLocalizedString("Signed In", comment: "") : NSLocalizedString("Sign In", comment: ""))
                    .font(.brand(17, .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 54)
            .background(self.buttonBackground)
            .clipShape(Capsule())
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

    private var infoCard: some View
    {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.brand)

                Text(NSLocalizedString("Why is this needed?", comment: ""))
                    .font(.brand(14, .semibold))
                    .foregroundColor(.ink)
            }

            Text(NSLocalizedString("Used to sign apps for this device. Your credentials are stored in the Keychain and only sent to Apple.", comment: ""))
                .font(.system(size: 13))
                .foregroundColor(.inkSoft)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.surface, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.surface, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
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
