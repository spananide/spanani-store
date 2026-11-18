import SwiftUI
import UniformTypeIdentifiers

struct SubmitSheet: View {
    @EnvironmentObject private var model: StoreModel
    @Environment(\.dismiss) private var dismiss

    @State private var pickedFileURL: URL?
    @State private var pickedFileName: String = ""
    @State private var pickedFileSize: Int64 = 0
    @State private var appName: String = ""
    @State private var note: String = ""
    @State private var isImporterPresented: Bool = false
    @State private var localError: String?

    private var isUploading: Bool {
        if case .uploading = model.submitState {
            return true
        }
        return false
    }

    private var currentErrorMessage: String? {
        if case .failed(let message) = model.submitState {
            return message
        }
        return localError
    }

    var body: some View {
        ZStack {
            Color.paper
                .ignoresSafeArea()

            if model.submitState == .done {
                successView
            } else {
                formContent
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .interactiveDismissDisabled(isUploading)
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [UTType(filenameExtension: "ipa") ?? .data],
            allowsMultipleSelection: false
        ) { result in
            handleFileImporter(result: result)
        }
        .onDisappear {
            if !isUploading {
                model.resetSubmit()
            }
        }
    }

    // MARK: - Success View

    private var successView: some View {
        VStack(spacing: 20) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64, weight: .bold))
                .foregroundColor(.success)

            Text("Thanks! We will have a look.")
                .font(.brand(24, .extrabold))
                .foregroundColor(.ink)
                .multilineTextAlignment(.center)

            Text("Your app suggestion has been submitted. We check every file before it goes live.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()

            Button {
                dismiss()
                model.resetSubmit()
            } label: {
                Text("Close")
                    .font(.brand(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
        }
        .padding(24)
    }

    // MARK: - Form Content

    private var formContent: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                headerView
                filePickerCard
                textFieldsSection
                hintCard

                if let errorText = currentErrorMessage {
                    errorMessageView(errorText)
                }

                actionButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 24)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Header

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Suggest an app")
                    .font(.brand(28, .extrabold))
                    .foregroundColor(.ink)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.inkSoft)
                        .frame(width: 32, height: 32)
                        .background(Color.paperRaised)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.paperSunk, lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
                .opacity(isUploading ? 0 : 1)
            }

            Text("Send us an .ipa you would like to see in the store. We check every file before it goes live.")
                .font(.system(size: 14))
                .foregroundColor(.inkSoft)
                .lineSpacing(2)
        }
    }

    // MARK: - File Picker Card

    @ViewBuilder
    private var filePickerCard: some View {
        if pickedFileURL != nil {
            HStack(spacing: 14) {
                ZStack {
                    Color.brand.opacity(0.15)
                    Image(systemName: "doc.zipper")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.brand)
                }
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 2) {
                    Text(pickedFileName)
                        .font(.brand(15, .semibold))
                        .foregroundColor(.ink)
                        .lineLimit(1)

                    Text(Formatters.fileSize(pickedFileSize))
                        .font(.system(size: 13))
                        .foregroundColor(.inkSoft)
                }

                Spacer()

                Button {
                    isImporterPresented = true
                } label: {
                    Text("Change")
                        .font(.brand(14, .semibold))
                        .foregroundColor(.brand)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.brand.opacity(0.12))
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                .disabled(isUploading)
            }
            .padding(14)
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
        } else {
            Button {
                isImporterPresented = true
            } label: {
                VStack(spacing: 10) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(.brand)

                    Text("Choose file")
                        .font(.brand(16, .semibold))
                        .foregroundColor(.ink)

                    Text("Tap to browse files")
                        .font(.system(size: 13))
                        .foregroundColor(.inkSoft)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .background(Color.paperRaised)
                .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous)
                        .stroke(Color.brand, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                )
            }
            .buttonStyle(.plain)
            .disabled(isUploading)
        }
    }

    // MARK: - Text Fields

    private var textFieldsSection: some View {
        VStack(spacing: 12) {
            TextField("App name (optional)", text: $appName)
                .font(.system(size: 15))
                .foregroundColor(.ink)
                .autocorrectionDisabled(true)
                .disabled(isUploading)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.paperRaised)
                .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous)
                        .stroke(Color.paperSunk, lineWidth: 1)
                )
                .onChange(of: appName) { newValue in
                    if newValue.count > 60 {
                        appName = String(newValue.prefix(60))
                    }
                }

            VStack(alignment: .trailing, spacing: 4) {
                TextField("Note (optional)", text: $note, axis: .vertical)
                    .font(.system(size: 15))
                    .foregroundColor(.ink)
                    .lineLimit(3...6)
                    .disabled(isUploading)
                    .padding(.horizontal, 14)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .overlay(alignment: .bottomTrailing) {
                        Text("\(max(0, 300 - note.count))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.inkFaint)
                            .padding(.trailing, 12)
                            .padding(.bottom, 8)
                    }
                    .onChange(of: note) { newValue in
                        if newValue.count > 300 {
                            note = String(newValue.prefix(300))
                        }
                    }
            }
            .background(Color.paperRaised)
            .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous)
                    .stroke(Color.paperSunk, lineWidth: 1)
            )
        }
    }

    // MARK: - Hint Card

    private var hintCard: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 15))
                .foregroundColor(.inkSoft)
                .padding(.top, 2)

            Text("Only send apps you are allowed to share. Cracked or paid apps are declined. Accepted apps appear as Community apps, not made or checked by spanani.de beyond a basic review.")
                .font(.system(size: 13))
                .foregroundColor(.inkSoft)
                .lineSpacing(3)
        }
        .padding(14)
        .background(Color.paperRaised)
        .clipShape(RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: SpananiRadius.small, style: .continuous)
                .stroke(Color.paperSunk, lineWidth: 1)
        )
    }

    // MARK: - Error Message View

    private func errorMessageView(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(.danger)
                .padding(.top, 1)

            Text(message)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.danger)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.danger.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Action Button

    @ViewBuilder
    private var actionButton: some View {
        switch model.submitState {
        case .uploading(let progress):
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                Text("Uploading ... \(Int(progress * 100)) %")
                    .font(.brand(16, .semibold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.brand)
            .clipShape(Capsule())
        default:
            Button {
                guard let fileURL = pickedFileURL else { return }
                localError = nil
                model.submit(fileURL: fileURL, appName: appName, note: note)
            } label: {
                Text("Send")
                    .font(.brand(16, .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.brand)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(pickedFileURL == nil || isUploading)
            .opacity(pickedFileURL == nil ? 0.5 : 1.0)
        }
    }

    // MARK: - File Importer Handler

    private func handleFileImporter(result: Result<[URL], Error>) {
        // File security-scoped resource handling; needs proper testing on physical devices
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let hasAccess = url.startAccessingSecurityScopedResource()
            defer {
                if hasAccess {
                    url.stopAccessingSecurityScopedResource()
                }
            }

            guard url.pathExtension.lowercased() == "ipa" else {
                localError = "The selected file must be an .ipa file."
                Haptics.notify(.error)
                return
            }

            let size: Int64
            if let res = try? url.resourceValues(forKeys: [.fileSizeKey]), let s = res.fileSize {
                size = Int64(s)
            } else if let attrs = try? FileManager.default.attributesOfItem(atPath: url.path), let s = attrs[.size] as? Int64 {
                size = s
            } else {
                size = 0
            }

            if size > 104_857_600 {
                localError = "The file exceeds the 100 MB limit."
                Haptics.notify(.error)
                return
            }

            pickedFileURL = url
            pickedFileName = url.lastPathComponent
            pickedFileSize = size
            localError = nil
            Haptics.selection()

        case .failure(let error):
            localError = error.localizedDescription
            Haptics.notify(.error)
        }
    }
}
