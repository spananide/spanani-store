import SwiftUI

// MARK: - SourcesView

struct SourcesView: View {
    @EnvironmentObject private var model: StoreModel
    @State private var isAddSheetPresented = false
    @State private var sourceToRemove: SourceItem?

    var body: some View {
        Group {
            if model.sources.isEmpty {
                ContentUnavailableView("No Sources", systemImage: "tray", description: Text("Tap + to add a source."))
            } else {
                List {
                    ForEach(model.sources) { source in
                        HStack {
                            VStack(alignment: .leading, spacing: Spacing.xs) {
                                Text(source.name)
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                Text(source.url)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(source.appCount == 1 ? "1 App" : "\(source.appCount) Apps")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                sourceToRemove = source
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Sources")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    isAddSheetPresented = true
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add Source")
            }
        }
        .sheet(isPresented: $isAddSheetPresented) {
            AddSourceSheet()
                .tint(.spananiAccent)
                .environmentObject(model)
                .presentationDetents([.medium, .large])
        }
        .confirmationDialog(
            "Remove Source?",
            isPresented: Binding(
                get: { sourceToRemove != nil },
                set: { if !$0 { sourceToRemove = nil } }
            ),
            titleVisibility: .visible,
            presenting: sourceToRemove
        ) { source in
            Button("Remove", role: .destructive) {
                model.removeSource(source)
            }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Apps from this source will no longer be listed.")
        }
    }
}

// MARK: - AddSourceSheet

struct AddSourceSheet: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss

    @State private var urlString: String = ""
    @State private var errorMessage: String? = nil
    @State private var isLoading: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("https://example.com/source.json", text: $urlString)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } footer: {
                    if let errorMessage {
                        Text(errorMessage)
                            .foregroundStyle(.red)
                    } else {
                        Text("Enter the URL of a compatible source.")
                    }
                }
            }
            .navigationTitle("Add Source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        addSource()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Add")
                        }
                    }
                    .disabled(isLoading || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .tint(.spananiAccent)
    }

    private func addSource() {
        isLoading = true
        errorMessage = nil
        Task {
            do {
                try await model.addSource(urlString)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
                isLoading = false
            }
        }
    }
}

// MARK: - SettingsView

struct SettingsView: View {
    @EnvironmentObject private var model: StoreModel
    @State private var showSignOutConfirmation = false

    var body: some View {
        Form {
            Section("Apple Account") {
                LabeledContent("Apple ID", value: model.account.appleID ?? "Not signed in")

                if let appleID = model.account.appleID {
                    Button("Sign Out", role: .destructive) {
                        showSignOutConfirmation = true
                    }
                    .confirmationDialog(
                        "Sign out of \(appleID)?",
                        isPresented: $showSignOutConfirmation,
                        titleVisibility: .visible
                    ) {
                        Button("Sign Out", role: .destructive) {
                            model.signOut()
                        }
                        Button("Cancel", role: .cancel) {}
                    }
                }
            }

            Section("Connection") {
                LabeledContent("Pairing File", value: model.account.isPaired ? "Loaded" : "Missing")
                    .foregroundStyle(.primary, .secondary)
                LabeledContent("VPN Loopback", value: model.account.vpnOn ? "Active" : "Inactive")
                    .foregroundStyle(.primary, .secondary)
            }

            Section("About") {
                LabeledContent(
                    "Version",
                    value: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "–"
                )
                .foregroundStyle(.primary, .secondary)

                LabeledContent("License", value: "Open source (AGPL-3.0)")
                    .foregroundStyle(.primary, .secondary)
            }
        }
        .navigationTitle("Settings")
    }
}
