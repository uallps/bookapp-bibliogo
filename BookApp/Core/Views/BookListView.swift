import SwiftUI

struct BookListView: View {
    var viewModel = BookListViewModel()
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
    @State private var selectedFilter: LibraryFilter = .all
    @State private var searchText: String = ""

    private enum LibraryFilter: String, CaseIterable, Identifiable {
        case all = "Todas"
        case reading = "Leyendo"
        case pending = "Por leer"
        case completed = "Leídos"

        var id: String { rawValue }
    }
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleLibraryBody
#else
        openUILibraryBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleLibraryBody: some View {
        NavigationStack {
            ZStack {
                Color.bookBackground(for: colorScheme)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 18) {
                        editorialHeader
                        searchBar

                        VStack(alignment: .leading, spacing: 10) {
                            filterPills

                            // Lo que añaden los plugins encima de la lista (filtros, avisos...).
                            ForEach(PluginRegistry.shared.libraryViews()) { pluginView in
                                pluginView.view
                            }
                        }

                        if let hero = heroReadingBook {
                            heroReadingCard(book: hero)
                        }

                        collectionSection

                        if let quote = recentQuote {
                            recentQuoteCard(quote: quote)
                        }
                    }
                    .padding(.horizontal, horizontalPadding)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                    .frame(maxWidth: 840)
                    .frame(maxWidth: .infinity)
                }
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            viewModel.addBook()
                        }
                    } label: {
                        Label("Añadir libro", systemImage: "plus")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .navigationTitle("")
        }
    }

    private var horizontalPadding: CGFloat {
#if os(macOS)
        return 28
#else
        return 18
#endif
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.caption2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("ESPACIO SERENO")
                    .font(.caption2.weight(.bold))
                    .tracking(1.4)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }

            Text("Biblioteca Personal")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            Text("Tu momento de calma con las palabras. Sin prisa.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.subheadline)
                .foregroundColor(.secondary)

            TextField("Buscar por título o autor…", text: $searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.bookCard(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.bookBorder(for: colorScheme), lineWidth: 1)
        )
    }

    private var filterPills: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(LibraryFilter.allCases) { filter in
                    let isSelected = selectedFilter == filter
                    let count = countForFilter(filter)

                    Button {
                        withAnimation(.easeInOut(duration: 0.18)) {
                            selectedFilter = filter
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(filter.rawValue)
                                .font(.subheadline.weight(isSelected ? .semibold : .medium))
                            Text("\(count)")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(
                                    Capsule()
                                        .fill(isSelected ? Color.white.opacity(0.22) : Color.bookSageSurface(for: colorScheme))
                                )
                        }
                        .foregroundColor(isSelected ? .white : .primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(isSelected ? Color.bookAccent : Color.bookCard(for: colorScheme))
                        )
                        .overlay(
                            Capsule()
                                .stroke(isSelected ? Color.clear : Color.bookBorder(for: colorScheme), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.vertical, 2)
        }
    }

    private var filteredBooks: [Book] {
        visibleBooks.filter { book in
            let matchesStatus: Bool
            switch selectedFilter {
            case .all:       matchesStatus = true
            case .reading:   matchesStatus = book.status == .leyendo
            case .pending:   matchesStatus = book.status == .pendiente
            case .completed: matchesStatus = book.status == .terminado
            }

            guard matchesStatus else { return false }
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !query.isEmpty else { return true }
            return book.title.localizedCaseInsensitiveContains(query)
                || (book.author?.localizedCaseInsensitiveContains(query) ?? false)
        }
    }

    /// Libro destacado en "Lectura principal" cuando hay alguno en estado Leyendo.
    private var heroReadingBook: Book? {
        guard searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              selectedFilter == .all || selectedFilter == .reading else {
            return nil
        }
        return filteredBooks.first { $0.status == .leyendo }
    }

    /// Resto de libros que se muestran en la rejilla / lista debajo de la lectura principal.
    private var secondaryBooks: [Book] {
        guard let hero = heroReadingBook else { return filteredBooks }
        return filteredBooks.filter { $0.id != hero.id }
    }

    private func countForFilter(_ filter: LibraryFilter) -> Int {
        switch filter {
        case .all:       return visibleBooks.count
        case .reading:   return visibleBooks.filter { $0.status == .leyendo }.count
        case .pending:   return visibleBooks.filter { $0.status == .pendiente }.count
        case .completed: return visibleBooks.filter { $0.status == .terminado }.count
        }
    }

    private func heroReadingCard(book: Book) -> some View {
        let bookProgress = progress(for: book)
        let avg = viewModel.averageRating(for: book.id)
        let revCount = viewModel.reviews(for: book.id).count

        return VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                BookCoverView(title: book.title, author: book.author, width: 78, height: 112)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("LECTURA PRINCIPAL")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                        Spacer()
                        Image(systemName: "bookmark.fill")
                            .font(.subheadline)
                            .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                    }

                    Text(book.title.isEmpty ? "Sin título" : book.title)
                        .font(.system(.title3, design: .serif).bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if config.showAuthors, let author = book.author, !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 6) {
                        if config.showRatings, let avg, revCount > 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.caption2)
                                    .foregroundColor(.bookStar)
                                Text(String(format: "%.1f", avg))
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(.bookStar)
                                Text("(\(revCount))")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                Capsule().fill(Color.bookStarSurface(for: colorScheme))
                            )
                        }
                    }
                    .padding(.top, 2)

                    // Lo que añaden los plugins a la fila de este libro.
                    ForEach(PluginRegistry.shared.bookRowViews(for: book)) { pluginView in
                        pluginView.view
                    }
                }
            }

            if config.showProgress, let bookProgress, bookProgress.totalPages > 0 {
                VStack(alignment: .leading, spacing: 6) {
                    BiblioProgressBar(
                        progress: Double(bookProgress.percentage) / 100.0,
                        color: Color.bookAccentAdaptive(for: colorScheme),
                        height: 7
                    )
                    HStack {
                        Text("\(bookProgress.percentage)% completado")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("Pág. \(bookProgress.currentPage) de \(bookProgress.totalPages)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            HStack(spacing: 10) {
                NavigationLink(destination: bookDetailDestination(for: book)) {
                    HStack(spacing: 8) {
                        Image(systemName: "book.fill")
                            .font(.subheadline)
                        Text("Abrir lectura")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.bookAccent)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewModel.advanceStatus(id: book.id)
                    }
                } label: {
                    Image(systemName: "checkmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .frame(width: 44, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.bookSageSurface(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
                .help("Marcar como terminado")
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 20, padding: 18)
        .contextMenu {
            Button(role: .destructive) {
                viewModel.removeBook(id: book.id)
            } label: {
                Label("Eliminar libro", systemImage: "trash")
            }
        }
    }

    private var collectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !secondaryBooks.isEmpty {
                HStack {
                    Text(heroReadingBook == nil ? "TU BIBLIOTECA" : "OTROS LIBROS")
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(secondaryBooks.count) \(secondaryBooks.count == 1 ? "título" : "títulos")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                let columns: [GridItem] = {
#if os(macOS)
                    return [GridItem(.adaptive(minimum: 340), spacing: 14)]
#else
                    return [GridItem(.flexible(), spacing: 12)]
#endif
                }()

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(secondaryBooks) { book in
                        bookRow(book: book)
                    }
                }
            } else if heroReadingBook == nil {
                emptyStateCard
            }
        }
    }

    private var emptyStateCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "books.vertical")
                .font(.system(size: 36))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            Text(searchText.isEmpty ? "No hay libros en esta vista" : "Sin resultados")
                .font(.system(.headline, design: .serif))
            Text(searchText.isEmpty
                 ? "Añade un nuevo libro o cambia los filtros superiores para explorar tu colección."
                 : "No encontramos ningún libro que coincida con «\(searchText)».")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 28)
    }

    private func bookDetailDestination(for book: Book) -> BookDetailView {
        BookDetailView(
            book: binding(for: book),
            progress: progressBinding(for: book),
            notes: notesBinding(for: book),
            reviews: reviewsBinding(for: book)
        )
    }
#endif

    private var openUILibraryBody: some View {
        NavigationStack {
            List {
                // Lo que añaden los plugins encima de la lista (filtros, avisos...).
                ForEach(PluginRegistry.shared.libraryViews()) { pluginView in
                    pluginView.view
                }
                ForEach(visibleBooks) { book in
                    bookRow(book: book)
                }
                if visibleBooks.isEmpty, !viewModel.books.isEmpty {
                    Text("No hay libros con este filtro")
                        .bookCaption()
                }
                if let quote = recentQuote {
                    Section {
                        recentQuoteCard(quote: quote)
                    }
                }
            }
            .toolbar {
                Button("Añadir libro") {
                    viewModel.addBook()
                }
            }
            .navigationTitle("Biblioteca Personal")
        }
    }

    /// Una fila: enlace al detalle del libro, con menú contextual para borrarlo.
    private func bookRow(book: Book) -> some View {
        NavigationLink(destination: BookDetailView(
            book: binding(for: book),
            progress: progressBinding(for: book),
            notes: notesBinding(for: book),
            reviews: reviewsBinding(for: book)
        )) {
            BookRowView(
                book: book,
                progress: progress(for: book),
                averageRating: viewModel.averageRating(for: book.id),
                reviewsCount: viewModel.reviews(for: book.id).count,
                showAuthors: config.showAuthors,
                showProgress: config.showProgress,
                showRatings: config.showRatings,
                advanceStatus: { viewModel.advanceStatus(id: book.id) }
            )
            .contextMenu {
                Button("Eliminar libro") {
                    viewModel.removeBook(id: book.id)
                }
            }
        }
#if !canImport(SwiftOpenUI)
        .buttonStyle(.plain)
#endif
    }

    /// Un enlace (Binding) para que el detalle edite el libro. No toca los datos:
    /// leer y escribir se traducen a métodos del ViewModel.
    private func binding(for book: Book) -> Binding<Book> {
        Binding(
            get: { viewModel.book(id: book.id) ?? book },
            set: { viewModel.updateBook($0) }
        )
    }

    /// F1 Progreso del libro, si ya tiene.
    private func progress(for book: Book) -> ReadingProgress? {
        return viewModel.progress(for: book.id)
    }

    /// Enlace al progreso del libro para el detalle. Si aún no tiene, empieza en 0 páginas.
    private func progressBinding(for book: Book) -> Binding<ReadingProgress>? {
        return Binding(
            get: { viewModel.progress(for: book.id) ?? ReadingProgress(bookID: book.id, totalPages: 0, currentPage: 0) },
            set: { viewModel.updateProgress($0) }
        )
    }

    /// F2 Notas y citas: enlace a las notas del libro.
    private func notesBinding(for book: Book) -> Binding<[BookNote]> {
        Binding(
            get: { viewModel.notes(for: book.id) },
            set: { viewModel.updateNotes($0, for: book.id) }
        )
    }

    /// F4 Valoraciones y reseñas: enlace a las valoraciones del libro.
    private func reviewsBinding(for book: Book) -> Binding<[BookReview]> {
        Binding(
            get: { viewModel.reviews(for: book.id) },
            set: { viewModel.updateReviews($0, for: book.id) }
        )
    }

    /// Los libros que se ven: los que dejan pasar los filtros de los plugins activos.
    /// Un plugin apagado no filtra, para que un filtro olvidado no esconda libros.
    private var visibleBooks: [Book] {
        PluginRegistry.shared.filteredBooks(viewModel.books)
    }

    /// F2 Cita más reciente para la tarjeta destacada inferior (prototipo BiblioGo).
    private var recentQuote: BookNote? {
        viewModel.notes
            .filter { $0.kind == .quote && !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .max { $0.createdAt <= $1.createdAt }
    }

    private func recentQuoteCard(quote: BookNote) -> some View {
#if !canImport(SwiftOpenUI)
        HStack(alignment: .top, spacing: 14) {
            RoundedRectangle(cornerRadius: 2)
                .fill(Color.bookAccentAdaptive(for: colorScheme))
                .frame(width: 3.5)

            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "quote.opening")
                        .font(.caption2)
                        .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                    Text("CITA GUARDADA RECIENTEMENTE")
                        .font(.caption2.weight(.bold))
                        .tracking(1.1)
                        .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                }

                Text("“\(quote.text)”")
                    .font(.system(.body, design: .serif))
                    .italic()
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if let bookTitle = viewModel.book(id: quote.bookID)?.title {
                    HStack {
                        Text(bookTitle)
                            .font(.caption.weight(.semibold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if let page = quote.page {
                            Text("Pág. \(page)")
                                .font(.caption2.weight(.medium))
                                .foregroundColor(Color.bookSageForeground(for: colorScheme))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                        }
                    }
                }
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
#else
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "quote.opening")
                    .font(.caption)
                    .foregroundColor(Color.bookAccent)
                Text("CITA GUARDADA RECIENTEMENTE")
                    .font(.caption)
                    .bold()
                    .foregroundColor(Color.bookAccent)
            }

            Text("“\(quote.text)”")
                .font(.subheadline)
                .foregroundColor(.primary)
                .padding(.vertical, 2)

            if let bookTitle = viewModel.book(id: quote.bookID)?.title {
                HStack {
                    Text(bookTitle)
                        .font(.caption)
                        .bold()
                        .foregroundColor(.secondary)
                    Spacer()
                    if let page = quote.page {
                        Text("Pág. \(page)")
                            .bookCaption()
                    }
                }
            }
        }
        .padding(.vertical, 4)
#endif
    }
}
