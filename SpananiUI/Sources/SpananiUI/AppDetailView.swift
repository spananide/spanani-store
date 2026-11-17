import SwiftUI

struct AppDetailView: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss
    let app: StoreItem

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Spacing.m) {
                        AppIconView(
                            tint: app.tint,
                            symbol: app.symbol,
                            iconURL: app.iconURL,
                            size: 80
                        )

                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text(app.name)
                                .font(.title2)
                                .bold()
                                .foregroundStyle(.primary)

                            Text(app.developer)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)

                            InstallButton(
                                state: model.state(for: app),
                                minHeight: 44,
                                action: { model.install(app) }
                            )
                            .padding(.top, Spacing.xs)
                        }
                    }
                    .padding(.vertical, Spacing.xs)
                } footer: {
                    if case .failed(let message) = model.state(for: app) {
                        Text(message)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                }

                if !app.whatsNew.isEmpty {
                    Section("What's New") {
                        VStack(alignment: .leading, spacing: Spacing.xs) {
                            Text("Version \(app.versionString)")
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text(app.whatsNew)
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, Spacing.xs)
                    }
                }

                if !app.screenshotURLs.isEmpty {
                    Section("Preview") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: Spacing.m) {
                                ForEach(app.screenshotURLs, id: \.self) { url in
                                    AsyncImage(url: url) { phase in
                                        if let image = phase.image {
                                            image
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                        } else if phase.error != nil {
                                            ZStack {
                                                Color(.secondarySystemGroupedBackground)
                                                Image(systemName: "photo")
                                                    .font(.title2)
                                                    .foregroundStyle(.secondary)
                                            }
                                        } else {
                                            ZStack {
                                                Color(.secondarySystemGroupedBackground)
                                                ProgressView()
                                            }
                                        }
                                    }
                                    .frame(height: 360)
                                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                }
                            }
                            .padding(.horizontal, Spacing.m)
                            .padding(.vertical, Spacing.s)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    }
                }

                if !app.description.isEmpty {
                    Section("Description") {
                        Text(app.description)
                            .font(.body)
                    }
                }

                Section("Information") {
                    LabeledContent("Version", value: app.versionString)
                    LabeledContent("Size", value: Formatters.fileSize(app.sizeBytes))
                    LabeledContent("Category", value: app.category)
                    LabeledContent("Source", value: app.sourceName)
                }

                Section("Permissions") {
                    if app.permissions.isEmpty {
                        Text("No special permissions")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(app.permissions, id: \.self) { permission in
                            Label(permission, systemImage: "checkmark.shield")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(.spananiAccent)
    }
}
