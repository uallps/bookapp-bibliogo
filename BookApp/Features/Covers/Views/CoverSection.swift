#if Portadas
import SwiftUI
#if !canImport(SwiftOpenUI)
import UniformTypeIdentifiers
#endif

/// O7 Foto de la portada en el detalle de cada libro: permite cambiar la portada
/// eligiendo una foto del dispositivo, buscándola de nuevo en internet o quitándola.
struct CoverSection: View {
    let book: Book

    @Environment(BookCoversPlugin.self) private var coversPlugin

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingImporter = false
#endif

    private var hasCover: Bool {
        coversPlugin.imageData(for: book.id) != nil
    }

    private var isCustom: Bool {
        coversPlugin.entry(for: book.id)?.isCustom == true
    }

    private var isLoading: Bool {
        coversPlugin.isLoading(book.id)
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleCoverCard
#else
        openUICoverSection
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleCoverCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Portada del libro", systemImage: "photo.on.rectangle")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                Text(hasCover ? (isCustom ? "Personalizada" : "De internet") : "Generada")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(hasCover ? Color.bookSageForeground(for: colorScheme) : .secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(hasCover ? Color.bookSageSurface(for: colorScheme) : Color.bookBackground(for: colorScheme))
                    )
            }

            HStack(spacing: 14) {
                BookCoverView(title: book.title, author: book.author, width: 64, height: 92)

                VStack(alignment: .leading, spacing: 8) {
                    Button {
                        showingImporter = true
                    } label: {
                        Label("Elegir foto…", systemImage: "photo")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 9)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.bookAccent)
                            )
                    }
                    .buttonStyle(.plain)

                    HStack(spacing: 8) {
                        Button {
                            Task {
                                await coversPlugin.fetchCoverFromInternet(for: book, isManual: true)
                            }
                        } label: {
                            HStack(spacing: 5) {
                                if isLoading {
                                    ProgressView().controlSize(.mini)
                                } else {
                                    Image(systemName: "globe")
                                }
                                Text(isLoading ? "Buscando…" : "Buscar en internet")
                            }
                            .font(.caption.weight(.semibold))
                            .foregroundColor(Color.bookSageForeground(for: colorScheme))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(Color.bookSageSurface(for: colorScheme))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(isLoading)

                        if hasCover {
                            Button {
                                withAnimation(.easeInOut(duration: 0.18)) {
                                    coversPlugin.removeCover(for: book.id)
                                }
                            } label: {
                                Image(systemName: "trash")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .frame(width: 36, height: 34)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(Color.bookBackground(for: colorScheme))
                                    )
                            }
                            .buttonStyle(.plain)
                            .help("Quitar portada")
                        }
                    }
                }
            }

            if let status = coversPlugin.statusMessage {
                Text(status)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
        .fileImporter(
            isPresented: $showingImporter,
            allowedContentTypes: [.image],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
    }

    private func handleFileImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            if let data = try? Data(contentsOf: url) {
                coversPlugin.setCover(data: data, for: book, isCustom: true)
                coversPlugin.statusMessage = "Portada personalizada guardada."
            }
        case .failure(let error):
            coversPlugin.statusMessage = "No se pudo abrir la imagen: \(error.localizedDescription)"
        }
    }
#endif

    private var openUICoverSection: some View {
        Section(header: Text("Portada")) {
            HStack {
                Text(hasCover ? "Portada guardada" : "Sin portada")
                    .bookCaption()
                Spacer()
                Button(isLoading ? "Buscando…" : "Buscar en internet") {
                    Task {
                        await coversPlugin.fetchCoverFromInternet(for: book, isManual: true)
                    }
                }
                if hasCover {
                    Button("Quitar") {
                        coversPlugin.removeCover(for: book.id)
                    }
                }
            }
        }
    }
}
#endif
