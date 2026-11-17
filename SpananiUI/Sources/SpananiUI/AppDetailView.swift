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
                    headerSection
                    whatsNewSection
                    screenshotsSection
                    descriptionSection
                    infoGridSection
                    permissionsSection
                }
                .padding(.bottom, 140)
            }

            topCloseBar
        }
    }

    // MARK: - Close Bar

    private var topCloseBar: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    Haptics.impact(.light)
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.inkFaint)
                        .background(Circle().fill(Color.paperRaised))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 20)
                .padding(.top, 16)
            }
            Spacer()
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack(alignment: .top) {
            GradientBackdrop(tint: app.tint)

            VStack(spacing: 12) {
                Spacer()
                    .frame(height: 36)

                AppIconView(
                    tint: app.tint,
                    symbol: app.symbol,
                    iconURL: app.iconURL,
                    size: 112
                )
                .padding(.top, 8)

                Text(app.name)
                    .font(.brand(30, .extrabold))
                    .foregroundColor(.ink)
                    .multilineTextAlignment(.center)

                Text(app.developer)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.accent)

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

                HStack(spacing: 6) {
                    Text("Version \(app.versionString)")
                    Text("•")
                    Text(Formatters.fileSize(app.sizeBytes))
                    Text("•")
                    Text("Quelle: \(app.sourceName)")
                }
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.inkFaint)
                .padding(.top, 2)
            }
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Was ist neu Section

    private var whatsNewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Was ist neu")

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Version \(app.versionString)")
                        .font(.brand(14, .semibold))
                        .foregroundColor(.accent)

                    Spacer()

                    Text("Kürzlich")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.inkFaint)
                }

                Text(app.whatsNew)
                    .font(.system(size: 14))
                    .foregroundColor(.inkSoft)
                    .lineSpacing(3)
            }
            .padding(18)
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
            .softShadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 3)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Screenshots Section

    private var screenshotsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Vorschau",
                subtitle: "Einblicke in die Benutzeroberfläche"
            )
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    if !app.screenshotURLs.isEmpty {
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
                                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                            .softShadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 5)
                        }
                    } else {
                        ForEach(0..<5, id: \.self) { index in
                            MockPhoneScreenView(
                                app: app,
                                pageIndex: index
                            )
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Beschreibung")

            Text(app.description)
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .lineSpacing(4)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 20)
    }

    // MARK: - Info Grid Section

    private var infoGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "Informationen")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                infoTile(label: "Version", value: app.versionString)
                infoTile(label: "Größe", value: Formatters.fileSize(app.sizeBytes))
                infoTile(label: "Kategorie", value: app.category)
                infoTile(label: "Quelle", value: app.sourceName)
            }
        }
        .padding(.horizontal, 20)
    }

    private func infoTile(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.inkFaint)

            Text(value)
                .font(.brand(15, .semibold))
                .foregroundColor(.ink)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    // MARK: - Permissions Section

    private var permissionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(
                title: "Berechtigungen",
                subtitle: "Vom Paket angeforderte Zugriffsrechte"
            )

            VStack(alignment: .leading, spacing: 10) {
                if app.permissions.isEmpty {
                    Text("Keine besonderen Berechtigungen erforderlich.")
                        .font(.system(size: 14))
                        .foregroundColor(.inkSoft)
                } else {
                    ForEach(app.permissions, id: \.self) { permission in
                        HStack(spacing: 10) {
                            Image(systemName: "checkmark.shield.fill")
                                .font(.system(size: 17))
                                .foregroundColor(.success)

                            Text(permission)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.ink)
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.tile, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
    }
}

// MARK: - Mock Phone Screen View

private struct MockPhoneScreenView: View {
    let app: StoreItem
    let pageIndex: Int

    var body: some View {
        ZStack {
            phoneBackground
            watermarkSymbol
            mockInterfaceContent
            mockNotchPill
        }
        .frame(width: 190, height: 412)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(phoneBorder)
        .softShadow(color: Color.black.opacity(0.18), radius: 12, x: 0, y: 5)
    }

    private var phoneBackground: some View {
        LinearGradient(
            colors: [
                app.tint.opacity(0.85),
                Color.paperRaised
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var watermarkSymbol: some View {
        Image(systemName: app.symbol)
            .font(.system(size: 72, weight: .bold))
            .foregroundColor(.white)
            .opacity(0.12)
    }

    private var mockNotchPill: some View {
        VStack {
            Capsule()
                .fill(Color.black.opacity(0.55))
                .frame(width: 52, height: 13)
                .padding(.top, 10)
            Spacer()
        }
    }

    private var mockInterfaceContent: some View {
        VStack(spacing: 12) {
            Spacer()
                .frame(height: 38)

            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.20))
                .frame(height: 18)
                .padding(.horizontal, 20)

            RoundedRectangle(cornerRadius: 6)
                .fill(Color.white.opacity(0.12))
                .frame(width: 100, height: 10)

            Spacer()

            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 48)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.10))
                    .frame(height: 48)
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 48)
            }
            .padding(.horizontal, 14)

            Spacer()
                .frame(height: 16)
        }
    }

    private var phoneBorder: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
    }
}
