/// Almacenamiento en memoria, para pruebas y vistas previas: no escribe nada en disco.
final class MockStorageProvider: StorageProvider {
    private var storedBooks: [Book] = [
        Book(title: "Libro de prueba 1"),
        Book(title: "Libro de prueba 2", author: "Autora de prueba", status: .terminado)
    ]

    func loadBooks() async throws -> [Book] {
        storedBooks
    }

    func saveBooks(books: [Book]) async throws {
        storedBooks = books
    }

    private var storedProgress: [ReadingProgress] = []

    func loadProgress() async throws -> [ReadingProgress] {
        storedProgress
    }

    func saveProgress(progress: [ReadingProgress]) async throws {
        storedProgress = progress
    }

    private var storedNotes: [BookNote] = []

    func loadNotes() async throws -> [BookNote] {
        storedNotes
    }

    func saveNotes(notes: [BookNote]) async throws {
        storedNotes = notes
    }

    private var storedReviews: [BookReview] = []

    func loadReviews() async throws -> [BookReview] {
        storedReviews
    }

    func saveReviews(reviews: [BookReview]) async throws {
        storedReviews = reviews
    }
}
