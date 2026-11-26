import Foundation

/// Guarda la biblioteca en ficheros JSON en la carpeta Documentos del usuario.
final class JSONStorageProvider: StorageProvider {
    private let fileURL: URL
    private let progressURL: URL
    private let notesURL: URL
    private let reviewsURL: URL

    init(filename: String = "books.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
        progressURL = documents.appendingPathComponent("progress.json")
        notesURL = documents.appendingPathComponent("notes.json")
        reviewsURL = documents.appendingPathComponent("reviews.json")
    }

    func loadBooks() async throws -> [Book] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Book].self, from: data)
    }

    func saveBooks(books: [Book]) async throws {
        try write(JSONEncoder().encode(books), to: fileURL)
    }

    func loadProgress() async throws -> [ReadingProgress] {
        let data = try Data(contentsOf: progressURL)
        return try JSONDecoder().decode([ReadingProgress].self, from: data)
    }

    func saveProgress(progress: [ReadingProgress]) async throws {
        try write(JSONEncoder().encode(progress), to: progressURL)
    }

    func loadNotes() async throws -> [BookNote] {
        let data = try Data(contentsOf: notesURL)
        return try JSONDecoder().decode([BookNote].self, from: data)
    }

    func saveNotes(notes: [BookNote]) async throws {
        try write(JSONEncoder().encode(notes), to: notesURL)
    }

    func loadReviews() async throws -> [BookReview] {
        let data = try Data(contentsOf: reviewsURL)
        return try JSONDecoder().decode([BookReview].self, from: data)
    }

    func saveReviews(reviews: [BookReview]) async throws {
        try write(JSONEncoder().encode(reviews), to: reviewsURL)
    }

    private func write(_ data: Data, to url: URL) throws {
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
