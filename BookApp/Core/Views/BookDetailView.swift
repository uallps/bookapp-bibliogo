import SwiftUI

/// Detalle de un libro. Recibe un enlace (@Binding) al libro de la lista:
/// lo que se edita aquí cambia el libro del ViewModel, sin copias.
struct BookDetailView: View {
    @Binding var book: Book
    /// F1 Progreso: nil en el producto sin el trait Progreso.
    let progress: Binding<ReadingProgress>?
    /// F2 Notas y citas: notas de este libro.
    @Binding var notes: [BookNote]
    /// F4 Valoraciones y reseñas: valoraciones de este libro.
    @Binding var reviews: [BookReview]

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleDetailBody
#else
        openUIDetailBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleDetailBody: some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    heroHeaderCard
                    bookInfoCard

#if Progreso
                    if let progress {
                        ProgressSection(progress: progress)
                    }
#endif
                    NotesSection(notes: $notes, bookID: book.id)
                    RatingsSection(reviews: $reviews, bookID: book.id)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 18)
                .frame(maxWidth: 740)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(book.title.isEmpty ? "Detalle" : book.title)
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var horizontalPadding: CGFloat {
#if os(macOS)
        return 28
#else
        return 18
#endif
    }

    private var averageRating: Double? {
        guard !reviews.isEmpty else { return nil }
        let total = reviews.reduce(0) { $0 + $1.rating }
        return Double(total) / Double(reviews.count)
    }

    private var heroHeaderCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                BookCoverView(title: book.title, author: book.author, width: 84, height: 122)

                VStack(alignment: .leading, spacing: 6) {
                    Text(book.title.isEmpty ? "Sin título" : book.title)
                        .font(.system(.title2, design: .serif).bold())
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)

                    if let author = book.author, !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Autor sin especificar")
                            .font(.subheadline)
                            .foregroundColor(.secondary.opacity(0.7))
                            .italic()
                    }

                    if let avg = averageRating {
                        HStack(spacing: 5) {
                            Image(systemName: "star.fill")
                                .font(.caption)
                                .foregroundColor(.bookStar)
                            Text(String(format: "%.1f", avg))
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.bookStar)
                            Text("· \(reviews.count) \(reviews.count == 1 ? "reseña" : "reseñas")")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(Color.bookStarSurface(for: colorScheme))
                        )
                        .padding(.top, 2)
                    }
                }
                Spacer(minLength: 0)
            }

            // Selector rápido de estado de lectura estilo píldoras
            HStack(spacing: 8) {
                ForEach(ReadingStatus.allCases, id: \.self) { status in
                    let isSelected = book.status == status
                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            book.status = status
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Image(systemName: status.systemImage)
                                .font(.caption)
                            Text(status.rawValue)
                                .font(.caption.weight(isSelected ? .semibold : .medium))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .foregroundColor(isSelected ? .white : Color.bookSageForeground(for: colorScheme))
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(isSelected ? Color.bookAccent : Color.bookSageSurface(for: colorScheme))
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 20, padding: 18)
    }

    private var bookInfoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Información del libro", systemImage: "book.closed")
                .font(.caption.weight(.bold))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))

            VStack(alignment: .leading, spacing: 6) {
                Text("Título")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Título del libro", text: $book.title)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.bookBackground(for: colorScheme))
                    )
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Autor")
                    .font(.caption)
                    .foregroundColor(.secondary)
                TextField("Autor (opcional)", text: authorBinding)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 9)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.bookBackground(for: colorScheme))
                    )
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }
#endif

    private var openUIDetailBody: some View {
        Form {
            Section(header: Text("Información del libro")) {
                TextField("Título del libro", text: $book.title)
                TextField("Autor (opcional)", text: authorBinding)
                Picker("Estado", selection: $book.status) {
                    Text(ReadingStatus.pendiente.rawValue).tag(ReadingStatus.pendiente)
                    Text(ReadingStatus.leyendo.rawValue).tag(ReadingStatus.leyendo)
                    Text(ReadingStatus.terminado.rawValue).tag(ReadingStatus.terminado)
                }
            }
#if Progreso
            if let progress {
                ProgressSection(progress: progress)
            }
#endif
            NotesSection(notes: $notes, bookID: book.id)
            RatingsSection(reviews: $reviews, bookID: book.id)
        }
        .navigationTitle(book.title)
    }

    /// El autor es opcional: el campo vacío se guarda como nil.
    private var authorBinding: Binding<String> {
        Binding(
            get: { book.author ?? "" },
            set: { book.author = $0.isEmpty ? nil : $0 }
        )
    }
}
