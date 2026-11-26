import SwiftUI

struct BookListView: View {
    var viewModel = BookListViewModel()
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config
    /// F3 Categorías: el plugin llega por el entorno.
    @Environment(CategoryPlugin.self) private var categoryPlugin
    /// F3 Categorías: categoría elegida en el filtro (CategoryFilter.all o un uuidString).
    /// Es estado de la pantalla, no se guarda.
    @State private var categoryFilter = CategoryFilter.all

    var body: some View {
        NavigationStack {
            List {
                if config.showCategories, !categoryPlugin.categories.isEmpty {
                    CategoryFilterView(categories: categoryPlugin.categories, selection: $categoryFilter)
                }
                ForEach(visibleBooks) { book in
                    bookRow(book: book)
                }
                if visibleBooks.isEmpty, !viewModel.books.isEmpty {
                    Text("No hay libros en esta categoría")
                        .bookCaption()
                }
            }
            .toolbar {
                Button("Añadir libro") {
                    viewModel.addBook()
                }
            }
            .navigationTitle("Biblioteca")
        }
    }

    /// Una fila: enlace al detalle del libro, con menú contextual para borrarlo.
    private func bookRow(book: Book) -> some View {
        NavigationLink(destination: BookDetailView(
            book: binding(for: book),
            progress: progressBinding(for: book),
            notes: notesBinding(for: book),
            reviews: reviewsBinding(for: book),
            categories: categoriesSection(for: book)
        )) {
            BookRowView(
                book: book,
                progress: progress(for: book),
                averageRating: viewModel.averageRating(for: book.id),
                reviewsCount: viewModel.reviews(for: book.id).count,
                showAuthors: config.showAuthors,
                showProgress: config.showProgress,
                showRatings: config.showRatings,
                advanceStatus: { viewModel.advanceStatus(id: book.id) },
                categoryText: categoryText(for: book)
            )
            .contextMenu {
                Button("Eliminar libro") {
                    viewModel.removeBook(id: book.id)
                }
            }
        }
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

    /// F3 Categorías: los libros que se ven. Con las categorías ocultas en Ajustes se ven
    /// todos, para que un filtro olvidado no esconda libros.
    private var visibleBooks: [Book] {
        guard config.showCategories else { return viewModel.books }
        return categoryPlugin.filteredBooks(viewModel.books, selection: categoryFilter)
    }

    /// F3 Categorías: texto de la fila, por ejemplo "Novela · Clásicos". nil si no tiene.
    private func categoryText(for book: Book) -> String? {
        let names = categoryPlugin.categories(for: book.id).map(\.name)
        guard config.showCategories, !names.isEmpty else { return nil }
        return names.joined(separator: " · ")
    }

    /// F3 Categorías: la sección del detalle, con sus Binding al plugin.
    private func categoriesSection(for book: Book) -> CategoriesSection {
        // Los Binding se usan más tarde (al pulsar): guardan el plugin, no la propiedad del entorno.
        let plugin = categoryPlugin
        return CategoriesSection(
            allCategories: Binding(
                get: { plugin.categories },
                set: { _ in } // la lista de categorías solo cambia con onCreate y onDelete
            ),
            selected: Binding(
                get: { plugin.categoryIDs(for: book.id) },
                set: { plugin.updateCategories($0, for: book.id) }
            ),
            onCreate: { name in
                if let id = plugin.addCategory(named: name) {
                    plugin.setCategory(id, selected: true, for: book.id)
                }
            },
            onDelete: { plugin.removeCategory(id: $0) }
        )
    }
}
