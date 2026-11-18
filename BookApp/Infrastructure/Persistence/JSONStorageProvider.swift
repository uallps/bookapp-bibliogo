import Foundation

/// Guarda la biblioteca en ficheros JSON en la carpeta Documentos del usuario.
final class JSONStorageProvider: StorageProvider {
    private let fileURL: URL
#if Progreso
    private let progressURL: URL
#endif

    init(filename: String = "books.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
#if Progreso
        progressURL = documents.appendingPathComponent("progress.json")
#endif
    }

    func loadBooks() async throws -> [Book] {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode([Book].self, from: data)
    }

    func saveBooks(books: [Book]) async throws {
        try write(JSONEncoder().encode(books), to: fileURL)
    }

#if Progreso
    func loadProgress() async throws -> [ReadingProgress] {
        let data = try Data(contentsOf: progressURL)
        return try JSONDecoder().decode([ReadingProgress].self, from: data)
    }

    func saveProgress(progress: [ReadingProgress]) async throws {
        try write(JSONEncoder().encode(progress), to: progressURL)
    }
#endif

    private func write(_ data: Data, to url: URL) throws {
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: url)
    }
}
