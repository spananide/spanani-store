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
        NavigationStack {
            Form {
                Section {
                    TextField("Apple ID", text: self.$viewModel.email)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .focused(self.$focusedField, equals: .email)
                        .submitLabel(.next)
                        .onSubmit {
                            self.focusedField = .password
                        }

                    SecureField("Password", text: self.$viewModel.password)
                        .textContentType(.password)
                        .focused(self.$focusedField, equals: .password)
                        .submitLabel(.go)
                        .onSubmit {
                            if self.viewModel.canSubmit {
                                self.focusedField = nil
                                self.viewModel.authenticate()
                            }
                        }
                } footer: {
                    Text("Your Apple ID is used to sign apps for this device. Credentials are stored in the Keychain and only sent to Apple.")
                }

                if let errorMessage = self.viewModel.errorMessage {
                    Section {
                        Label(errorMessage, systemImage: "exclamationmark.triangle.fill")
                            .foregroundStyle(.red)
                    } header: {
                        Text("Sign-in failed")
                    }
                }
            }
            .navigationTitle("Sign In")
            .navigationBarTitleDisplayMode(.large)
            .scrollDismissesKeyboard(.interactively)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    SwiftUI.Button("Cancel") {
                        self.viewModel.cancel()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    SwiftUI.Button {
                        self.focusedField = nil
                        self.viewModel.authenticate()
                    } label: {
                        if self.viewModel.isLoading {
                            ProgressView()
                        } else if self.viewModel.isAuthenticated {
                            Label("Signed In", systemImage: "checkmark.circle.fill")
                        } else {
                            Text("Sign In")
                        }
                    }
                    .disabled(!self.viewModel.canSubmit)
                }
            }
        }
        .tint(.spananiAccent)
        .background(Color(.systemGroupedBackground))
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
