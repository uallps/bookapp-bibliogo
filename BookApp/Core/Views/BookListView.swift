import SwiftUI

struct BookListView: View {
    var viewModel = BookListViewModel()
    /// La configuración la crea la app y llega por el entorno: es la misma que edita Ajustes.
    @Environment(AppConfig.self) private var config

    var body: some View {
        NavigationStack {
            List {
                if config.showStatistics {
                    StatisticsSection(statistics: viewModel.statistics)
                }
                ForEach(viewModel.books) { book in
                    bookRow(book: book)
                }
            }
            .toolbar {
                NavigationLink(destination: StatisticsView(statistics: viewModel.statistics)) {
                    Label("Estadísticas", systemImage: "checklist")
                }
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
            notes: notesBinding(for: book)
        )) {
            BookRowView(
                book: book,
                progress: progress(for: book),
                showAuthors: config.showAuthors,
                showProgress: config.showProgress,
                advanceStatus: { viewModel.advanceStatus(id: book.id) }
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

    /// F1 Progreso del libro. Sin el trait Progreso no hay progreso: nil.
    private func progress(for book: Book) -> ReadingProgress? {
#if Progreso
        return viewModel.progress(for: book.id)
#else
        return nil
#endif
    }

    /// Enlace al progreso del libro para el detalle. Si aún no tiene, empieza en 0 páginas.
    /// Sin el trait Progreso devuelve nil y el detalle no muestra la sección.
    private func progressBinding(for book: Book) -> Binding<ReadingProgress>? {
#if Progreso
        return Binding(
            get: { viewModel.progress(for: book.id) ?? ReadingProgress(bookID: book.id, totalPages: 0, currentPage: 0) },
            set: { viewModel.updateProgress($0) }
        )
#else
        return nil
#endif
    }

    /// F2 Notas y citas: enlace a las notas del libro.
    private func notesBinding(for book: Book) -> Binding<[BookNote]> {
        Binding(
            get: { viewModel.notes(for: book.id) },
            set: { viewModel.updateNotes($0, for: book.id) }
        )
    }
}
