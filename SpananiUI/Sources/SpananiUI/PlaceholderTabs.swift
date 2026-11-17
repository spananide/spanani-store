import SwiftUI

// MARK: - SourcesView

struct SourcesView: View {
    @EnvironmentObject private var model: StoreModel
    @State private var isAddSheetPresented = false
    @State private var sourceToRemove: SourceItem? = nil
    @State private var isConfirmRemovePresented = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if model.sources.isEmpty {
                    emptySourcesView
                } else {
                    sourcesListSection
                    addSourceButton
                }
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(Color.paper)
        .sheet(isPresented: $isAddSheetPresented) {
            AddSourceSheet()
                .environmentObject(model)
                .presentationDetents([.medium])
        }
        .confirmationDialog(
            "Remove source?",
            isPresented: $isConfirmRemovePresented,
            titleVisibility: .visible
        ) {
            Button("Remove", role: .destructive) {
                if let source = sourceToRemove {
                    model.removeSource(source)
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sources")
                .font(.brand(34, .extrabold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
    }

    private var emptySourcesView: some View {
        VStack(spacing: 16) {
            Spacer()
                .frame(height: 32)

            Mark3DTile(size: 96)

            Text("No sources")
                .font(.brand(22, .extrabold))
                .foregroundColor(.ink)

            Text("Add a source to see apps here.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)

            Button {
                Haptics.impact(.medium)
                isAddSheetPresented = true
            } label: {
                Text("Add source")
                    .font(.brand(15, .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
    }

    private var sourcesListSection: some View {
        VStack(spacing: 12) {
            ForEach(model.sources) { source in
                sourceCard(source: source)
            }
        }
        .padding(.horizontal, 20)
    }

    private func sourceCard(source: SourceItem) -> some View {
        HStack(spacing: 14) {
            ZStack {
                source.tint
                Text(String(source.name.prefix(1)).uppercased())
                    .font(.brand(20, .extrabold))
                    .foregroundColor(.white)
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1.5)
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(source.name)
                    .font(.brand(17, .semibold))
                    .foregroundColor(.ink)

                Text(source.url)
                    .font(.system(size: 12))
                    .foregroundColor(.inkFaint)
                    .lineLimit(1)
            }

            Spacer()

            Text(source.appCount == 1 ? "1 app" : "\(source.appCount) apps")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.paperSunk)
                .clipShape(Capsule())

            Menu {
                Button(role: .destructive) {
                    sourceToRemove = source
                    isConfirmRemovePresented = true
                } label: {
                    Label("Remove", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.inkSoft)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .accessibilityLabel("Actions for \(source.name)")
        }
        .padding(16)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
    }

    private var addSourceButton: some View {
        Button {
            Haptics.impact(.medium)
            isAddSheetPresented = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                Text("Add source")
                    .font(.brand(16, .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.brand)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
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
            VStack(alignment: .leading, spacing: 20) {
                Text("Enter the address of a compatible source.")
                    .font(.system(size: 14))
                    .foregroundColor(.inkSoft)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("https://example.com/source.json", text: $urlString)
                        .font(.system(size: 15))
                        .foregroundColor(.ink)
                        .keyboardType(.URL)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.paperSunk)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(errorMessage != nil ? Color.danger : Color.paperSunk, lineWidth: 1)
                        )

                    if let errorMessage = errorMessage {
                        HStack(spacing: 6) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.system(size: 13))
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                        }
                        .foregroundColor(.danger)
                        .padding(.horizontal, 4)
                    }
                }

                Spacer()

                Button {
                    addSource()
                } label: {
                    HStack {
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .padding(.trailing, 6)
                        }
                        Text("Add")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isLoading || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(20)
            .background(Color.paper)
            .navigationTitle("Add source")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.brand)
                }
            }
        }
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
    @State private var isConfirmSignOutPresented = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                accountSection
                refreshingSection
                connectionSection
                aboutSection
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(Color.paper)
        .confirmationDialog(
            "Sign out of Apple ID?",
            isPresented: $isConfirmSignOutPresented,
            titleVisibility: .visible
        ) {
            Button("Sign out", role: .destructive) {
                model.signOut()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Settings")
                .font(.brand(34, .extrabold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apple ID")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Apple ID")
                            .font(.system(size: 13))
                            .foregroundColor(.inkFaint)

                        Text(model.account.appleID ?? "Not signed in")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.ink)
                    }

                    Spacer()

                    statusPill(
                        text: model.account.appleID != nil ? "Signed in" : "Not signed in",
                        color: model.account.appleID != nil ? .success : .warning
                    )
                }
                .padding(16)

                if model.account.appleID != nil {
                    Rectangle()
                        .fill(Color.paperSunk)
                        .frame(height: 1)
                        .padding(.horizontal, 16)

                    Button {
                        isConfirmSignOutPresented = true
                    } label: {
                        HStack {
                            Text("Sign out")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.danger)
                            Spacer()
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.danger)
                        }
                        .padding(16)
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Refreshing Section

    private var refreshingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Refreshing")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { model.autoRefreshEnabled },
                        set: { model.setAutoRefresh($0) }
                    )) {
                        Text("Refresh automatically")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.ink)
                    }
                    .tint(.brand)

                    Text("Refreshes apps in the background before they expire. iOS decides when it runs, so open the store now and then.")
                        .font(.system(size: 13))
                        .foregroundColor(.inkSoft)
                }
                .padding(16)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 8) {
                    Toggle(isOn: Binding(
                        get: { model.remindersEnabled },
                        set: { model.setReminders($0) }
                    )) {
                        Text("Expiry reminders")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.ink)
                    }
                    .tint(.brand)

                    Text("A notification 24 hours before an app expires.")
                        .font(.system(size: 13))
                        .foregroundColor(.inkSoft)
                }
                .padding(16)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Connection")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Pairing file")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    Text(model.account.isPaired ? "Loaded" : "Missing")
                        .font(.brand(14, .semibold))
                        .foregroundColor(model.account.isPaired ? .success : .danger)
                }
                .padding(16)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    Text("VPN loopback")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    Text(model.account.vpnOn ? "Active" : "Inactive")
                        .font(.brand(14, .semibold))
                        .foregroundColor(model.account.vpnOn ? .success : .warning)
                }
                .padding(16)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    Text("Widgets")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    Text(model.account.widgetsReady ? "Ready" : "Needs app group")
                        .font(.brand(14, .semibold))
                        .foregroundColor(model.account.widgetsReady ? .success : .warning)
                }
                .padding(16)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("About")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack(spacing: 16) {
                    Mark3DTile(size: 72)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("spanani Store")
                            .font(.brand(20, .extrabold))
                            .foregroundColor(.ink)

                        let versionString = (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
                        Text("Version \(versionString)")
                            .font(.system(size: 14))
                            .foregroundColor(.inkSoft)
                    }

                    Spacer()
                }
                .padding(16)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    Text("License")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    Text("Open source (AGPL-3.0)")
                        .font(.brand(14, .semibold))
                        .foregroundColor(.inkSoft)
                }
                .padding(16)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    private func statusPill(text: String, color: Color) -> some View {
        Text(text)
            .font(.brand(12, .semibold))
            .foregroundColor(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color.opacity(0.14))
            .clipShape(Capsule())
    }
}
