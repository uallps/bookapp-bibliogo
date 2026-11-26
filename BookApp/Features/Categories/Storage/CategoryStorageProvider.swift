import Foundation

/// Dónde guarda el plugin sus categorías. Mismo patrón que `StorageProvider`.
protocol CategoryStorageProvider {
    func loadCategories() async throws -> CategoryData
    func saveCategories(_ data: CategoryData) async throws
}

/// Guarda las categorías y sus enlaces en su propio fichero, categories.json, junto a books.json.
final class JSONCategoryStorageProvider: CategoryStorageProvider {
    private let fileURL: URL

    init(filename: String = "categories.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadCategories() async throws -> CategoryData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(CategoryData.self, from: data)
    }

    func saveCategories(_ data: CategoryData) async throws {
        let encoded = try JSONEncoder().encode(data)
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL)
    }
}
