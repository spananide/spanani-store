import SwiftUI

struct AppDetailView: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss
    let app: StoreItem

    var body: some View {
        ZStack {
            Color.paper
                .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    topZone
                    titleAndActionSection
                    statStrip

                    if !app.whatsNew.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        whatsNewSection
                    }

                    if !app.screenshotURLs.isEmpty {
                        previewSection
                    }

                    if !app.description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        aboutSection
                    }

                    permissionsSection
                }
                .padding(.bottom, 60)
            }
        }
    }

    // MARK: - Top Block

    private var topZone: some View {
        ZStack {
            app.tint

            AppIconView(
                tint: app.tint,
                symbol: app.symbol,
                iconURL: app.iconURL,
                size: 112
            )

            VStack {
                HStack {
                    Button {
                        Haptics.selection()
                        model.toggleFavorite(app.id)
                    } label: {
                        Image(systemName: model.isFavorite(app.id) ? "star.fill" : "star")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(model.isFavorite(app.id) ? .brand : .inkSoft)
                            .frame(width: 44, height: 44)
                            .background(Color.paperRaised)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Favourite")

                    Spacer()

                    Button {
                        Haptics.impact(.light)
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.ink)
                            .frame(width: 44, height: 44)
                            .background(Color.paperRaised)
                            .clipShape(Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)

                Spacer()
            }
        }
        .frame(height: 210)
    }

    // MARK: - Title and Action Section

    private var titleAndActionSection: some View {
        VStack(spacing: 8) {
            Text(app.name)
                .font(.brand(30, .extrabold))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Text(app.developer)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.brand)

            InstallButton(
                state: model.state(for: app),
                minHeight: 48,
                fontSize: 17
            ) {
                model.install(app)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 6)

            if case .failed(let message) = model.state(for: app) {
                Text(message)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.danger)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.top, 2)
            }
        }
    }

    // MARK: - Stat Strip

    private var statStrip: some View {
        HStack(spacing: 0) {
            VStack(spacing: 3) {
                Text("Version")
                    .font(.system(size: 12))
                    .foregroundColor(.inkFaint)
                Text(app.versionString)
                    .font(.brand(16, .semibold))
                    .foregroundColor(.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(width: 1, height: 32)

            VStack(spacing: 3) {
                Text("Size")
                    .font(.system(size: 12))
                    .foregroundColor(.inkFaint)
                Text(Formatters.fileSize(app.sizeBytes))
                    .font(.brand(16, .semibold))
                    .foregroundColor(.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.paperSunk)
                .frame(width: 1, height: 32)

            VStack(spacing: 3) {
                Text("Source")
                    .font(.system(size: 12))
                    .foregroundColor(.inkFaint)
                Text(app.sourceName)
                    .font(.brand(16, .semibold))
                    .foregroundColor(.ink)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - What's New Section

    private var whatsNewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "What's new")
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 8) {
                Text("Version \(app.versionString)")
                    .font(.brand(14, .semibold))
                    .foregroundColor(.brand)

                Text(app.whatsNew)
                    .font(.system(size: 14))
                    .foregroundColor(.inkSoft)
                    .lineSpacing(3)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Preview Section

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Preview")
                .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(app.screenshotURLs, id: \.self) { url in
                        AsyncImage(url: url) { phase in
                            if let image = phase.image {
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                            } else if phase.error != nil {
                                ZStack {
                                    Color.paperRaised
                                    Image(systemName: "photo")
                                        .font(.system(size: 32))
                                        .foregroundColor(.inkFaint)
                                }
                            } else {
                                ZStack {
                                    Color.paperRaised
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .brand))
                                }
                            }
                        }
                        .frame(width: 190, height: 412)
                        .background(Color.paperRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .stroke(Color.paperSunk, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - About Section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "About")
                .padding(.horizontal, 20)

            Text(app.description)
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
        }
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Permissions")
                .padding(.horizontal, 20)

            VStack(alignment: .leading, spacing: 10) {
                if app.permissions.isEmpty {
                    Text("No special permissions.")
                        .font(.system(size: 14))
                        .foregroundColor(.inkSoft)
                } else {
                    ForEach(app.permissions, id: \.self) { permission in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.shield")
                                .font(.system(size: 17))
                                .foregroundColor(.success)

                            Text(permission)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.ink)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
        }
    }
}
