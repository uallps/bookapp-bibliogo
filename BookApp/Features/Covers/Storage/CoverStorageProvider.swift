#if Portadas
import Foundation

/// Contrato de almacenamiento para las portadas de O7.
protocol CoverStorageProvider {
    func loadEntries() async throws -> [BookCoverEntry]
    func saveEntries(_ entries: [BookCoverEntry]) async throws
    func saveImageData(_ data: Data, for bookID: UUID) throws -> String
    func loadImageData(filename: String) -> Data?
    func deleteImage(filename: String)
}

/// Guarda el índice en `covers.json` y las imágenes en `Documents/covers/`.
final class JSONCoverStorageProvider: CoverStorageProvider {
    private let indexURL: URL
    private let coversDirectoryURL: URL

    init(filename: String = "covers.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        indexURL = documents.appendingPathComponent(filename)
        coversDirectoryURL = documents.appendingPathComponent("covers", isDirectory: true)
    }

    func loadEntries() async throws -> [BookCoverEntry] {
        let data = try Data(contentsOf: indexURL)
        return try JSONDecoder().decode([BookCoverEntry].self, from: data)
    }

    func saveEntries(_ entries: [BookCoverEntry]) async throws {
        let encoded = try JSONEncoder().encode(entries)
        try FileManager.default.createDirectory(
            at: indexURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: indexURL)
    }

    func saveImageData(_ data: Data, for bookID: UUID) throws -> String {
        try FileManager.default.createDirectory(at: coversDirectoryURL, withIntermediateDirectories: true)
        let filename = "\(bookID.uuidString).jpg"
        let destination = coversDirectoryURL.appendingPathComponent(filename)
        try data.write(to: destination)
        return filename
    }

    func loadImageData(filename: String) -> Data? {
        let fileURL = coversDirectoryURL.appendingPathComponent(filename)
        return try? Data(contentsOf: fileURL)
    }

    func deleteImage(filename: String) {
        let fileURL = coversDirectoryURL.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: fileURL)
    }
}
#endif
