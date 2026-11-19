/// Contrato de almacenamiento de la biblioteca. El ViewModel solo conoce este protocolo,
/// así que se puede cambiar dónde se guardan los libros sin tocarlo.
protocol StorageProvider {
    func loadBooks() async throws -> [Book]
    func saveBooks(books: [Book]) async throws

#if Progreso
    /// F1 Progreso: se guarda aparte de los libros, porque no forma parte de Book.
    func loadProgress() async throws -> [ReadingProgress]
    func saveProgress(progress: [ReadingProgress]) async throws
#endif

    /// F2 Notas y citas: se guarda aparte de los libros, enlazadas por bookID.
    func loadNotes() async throws -> [BookNote]
    func saveNotes(notes: [BookNote]) async throws

    /// F4 Valoraciones y reseñas: se guarda aparte de los libros, enlazadas por bookID.
    func loadReviews() async throws -> [BookReview]
    func saveReviews(reviews: [BookReview]) async throws
}
