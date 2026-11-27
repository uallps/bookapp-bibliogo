#if Autores
import Foundation

/// Dónde guarda el plugin las fichas de autor. Mismo patrón que `StorageProvider`.
protocol AuthorStorageProvider {
    func loadAuthors() async throws -> AuthorData
    func saveAuthors(_ data: AuthorData) async throws
}

/// Guarda las fichas en su propio fichero, authors.json, junto a books.json.
final class JSONAuthorStorageProvider: AuthorStorageProvider {
    private let fileURL: URL

    init(filename: String = "authors.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadAuthors() async throws -> AuthorData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(AuthorData.self, from: data)
    }

    func saveAuthors(_ data: AuthorData) async throws {
        let encoded = try JSONEncoder().encode(data)
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL)
    }
}
#endif
