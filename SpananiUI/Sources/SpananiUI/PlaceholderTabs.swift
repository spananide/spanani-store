import SwiftUI

// MARK: - SourcesView

struct SourcesView: View {
    @EnvironmentObject private var model: StoreModel
    @State private var isAddSheetPresented = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                sourcesListSection
                addSourceRow
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
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Verwaltung")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.inkSoft)

            Text("Quellen")
                .font(.brand(38, .extrabold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
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
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(source.tint.opacity(0.18))
                    .frame(width: 44, height: 44)

                SpananiLogo.markImage()
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 22, height: 22)
                    .foregroundColor(source.tint)
            }

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

            Text(source.appCount == 1 ? "1 App" : "\(source.appCount) Apps")
                .font(.brand(12, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.paperSunk)
                .clipShape(Capsule())

            Menu {
                Button(role: .destructive) {
                    model.removeSource(source)
                } label: {
                    Label("Entfernen", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.inkSoft)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(16)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .softShadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
    }

    private var addSourceRow: some View {
        Button {
            Haptics.impact(.medium)
            isAddSheetPresented = true
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.brand)

                Text("Quelle hinzufügen")
                    .font(.brand(16, .semibold))
                    .foregroundColor(.brand)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color.paperSunk.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(
                        Color.brand.opacity(0.4),
                        style: StrokeStyle(lineWidth: 1.5, dash: [6, 6])
                    )
            )
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
                Text("Gib die URL einer AltStore- oder SideStore-kompatiblen Quelle ein.")
                    .font(.system(size: 14))
                    .foregroundColor(.inkSoft)

                VStack(alignment: .leading, spacing: 8) {
                    TextField("https://beispiel.de/source.json", text: $urlString)
                        .font(.system(size: 15))
                        .foregroundColor(.ink)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                        .autocorrectionDisabled(true)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.paperSunk)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(errorMessage != nil ? Color.danger : Color.white.opacity(0.08), lineWidth: 1)
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
                        Text("Hinzufügen")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 14)
                    .background(Color.brand)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isLoading || urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
            }
            .padding(20)
            .background(Color.paper)
            .navigationTitle("Quelle hinzufügen")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbrechen") {
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
    @AppStorage("useClassicUI") private var useClassicUI: Bool = false

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                headerSection
                accountSection
                interfaceSection
                connectionSection
                aboutSection
            }
            .padding(.top, 16)
            .padding(.bottom, 140)
        }
        .background(Color.paper)
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Optionen")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.inkSoft)

            Text("Einstellungen")
                .font(.brand(38, .extrabold))
                .foregroundColor(.ink)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Apple-Account")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Apple-ID")
                            .font(.system(size: 13))
                            .foregroundColor(.inkFaint)

                        Text(model.account.appleID ?? "Nicht verbunden")
                            .font(.brand(16, .semibold))
                            .foregroundColor(.ink)
                    }

                    Spacer()

                    statusPill(
                        text: model.account.appleID != nil ? "Verbunden" : "Nicht verbunden",
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
                        model.signOut()
                    } label: {
                        HStack {
                            Text("Abmelden")
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
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .softShadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Interface Section

    private var interfaceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Oberfläche")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                Toggle(isOn: $useClassicUI) {
                    Text("Klassische Oberfläche verwenden (nach Neustart)")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)
                }
                .tint(.brand)
                .padding(16)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .softShadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Connection Section

    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Verbindung & Loopback")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                HStack {
                    Text("Pairing-Datei")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    statusPill(
                        text: model.account.isPaired ? "Geladen ✓" : "Fehlt",
                        color: model.account.isPaired ? .success : .danger
                    )
                }
                .padding(16)

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                HStack {
                    Text("VPN-Loopback")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.ink)

                    Spacer()

                    statusPill(
                        text: model.account.vpnOn ? "Aktiv ✓" : "Inaktiv",
                        color: model.account.vpnOn ? .success : .warning
                    )
                }
                .padding(16)
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .softShadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Über spanani Store")
                .font(.brand(16, .semibold))
                .foregroundColor(.inkSoft)
                .padding(.horizontal, 20)

            VStack(spacing: 0) {
                settingsRow(title: "Version", value: "1.0 (Demo)")

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                settingsRow(title: "Basis", value: "SideStore (AGPL-3.0)")

                Rectangle()
                    .fill(Color.paperSunk)
                    .frame(height: 1)
                    .padding(.horizontal, 16)

                settingsRow(title: "Design", value: "spanani.de Design System")
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .softShadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
            .padding(.horizontal, 20)
        }
    }

    private func settingsRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.ink)

            Spacer()

            Text(value)
                .font(.brand(14, .semibold))
                .foregroundColor(.inkSoft)
        }
        .padding(16)
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
