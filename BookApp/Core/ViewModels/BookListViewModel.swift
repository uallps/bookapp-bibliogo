import Foundation
import Observation

/// Responsable del listado de libros y de modificar su estado.
/// Las vistas solo dibujan y avisan de las acciones: todo cambio pasa por aquí.
@Observable
final class BookListViewModel {
    /// Libros de ejemplo, para la primera vez que se abre la app.
    private static let dune = Book(title: "Dune", author: "Frank Herbert")
    private static let junco = Book(title: "El infinito en un junco", author: "Irene Vallejo", status: .leyendo)
    private static let klara = Book(title: "Klara y el Sol", author: "Kazuo Ishiguro", status: .terminado)

    /// Cada cambio en la lista (cambiar estado, añadir, borrar o editar en el detalle) se guarda.
    var books: [Book] = [BookListViewModel.dune, BookListViewModel.junco, BookListViewModel.klara] {
        didSet { save() }
    }

    /// F1 Progreso: un registro por libro, enlazado por bookID. Se guarda aparte de los libros.
    /// La propiedad existe en todos los productos para no meter un #if dentro de una
    /// clase @Observable; sin el trait Progreso se queda vacía y no se guarda.
    var progress: [ReadingProgress] = BookListViewModel.sampleProgress {
        didSet { saveProgress() }
    }

#if Progreso
    private static let sampleProgress = [
        ReadingProgress(bookID: junco.id, totalPages: 456, currentPage: 120)
    ]
#else
    private static let sampleProgress: [ReadingProgress] = []
#endif

    @ObservationIgnored private let storageProvider: StorageProvider
    @ObservationIgnored private var loaded = false

    /// Por defecto guarda en JSON; en pruebas se le pasa un MockStorageProvider.
    init(storageProvider: StorageProvider = JSONStorageProvider()) {
        self.storageProvider = storageProvider
        Task { await loadBooks() }
    }

    /// Carga los libros guardados, solo la primera vez que se llama.
    /// Si aún no hay fichero, se quedan los libros de ejemplo.
    func loadBooks() async {
        guard !loaded else { return }
        loaded = true
        do {
            books = try await storageProvider.loadBooks()
        } catch {
            print("No se han cargado libros: \(error)")
        }
#if Progreso
        do {
            progress = try await storageProvider.loadProgress()
        } catch {
            print("No se ha cargado el progreso: \(error)")
        }
#endif
    }

    /// Pasa el libro al estado siguiente: Pendiente → Leyendo → Terminado → Pendiente.
    func advanceStatus(id: UUID) {
        guard let index = books.firstIndex(where: { $0.id == id }) else { return }
        books[index].status = books[index].status.next
    }

    func addBook() {
        books.append(Book(title: "Libro nuevo"))
    }

    func removeBook(id: UUID) {
        books.removeAll { $0.id == id }
#if Progreso
        progress.removeAll { $0.bookID == id }
#endif
    }

    /// El libro con ese id, si sigue en la lista.
    func book(id: UUID) -> Book? {
        books.first { $0.id == id }
    }

    /// Sustituye el libro que tiene el mismo id (la usa el detalle al editar).
    func updateBook(_ book: Book) {
        guard let index = books.firstIndex(where: { $0.id == book.id }) else { return }
        books[index] = book
    }

#if Progreso
    /// El progreso de un libro, si ya tiene.
    func progress(for bookID: UUID) -> ReadingProgress? {
        progress.first { $0.bookID == bookID }
    }

    /// Sustituye el progreso de ese libro, o lo añade si aún no tenía.
    func updateProgress(_ newProgress: ReadingProgress) {
        if let index = progress.firstIndex(where: { $0.bookID == newProgress.bookID }) {
            progress[index] = newProgress
        } else {
            progress.append(newProgress)
        }
    }
#endif

    /// Guarda la lista completa en segundo plano. Aquí `Task` es la tarea asíncrona
    /// de Swift; en TaskApp hay que escribir `_Concurrency.Task` porque su modelo
    /// se llama igual, pero en BookApp no hay ese choque de nombres.
    private func save() {
        let books = books
        Task {
            do {
                try await storageProvider.saveBooks(books: books)
            } catch {
                print("No se han guardado los libros: \(error)")
            }
        }
    }

    private func saveProgress() {
#if Progreso
        let progress = progress
        Task {
            do {
                try await storageProvider.saveProgress(progress: progress)
            } catch {
                print("No se ha guardado el progreso: \(error)")
            }
        }
#endif
    }
}
