#if ColaLectura
import Foundation

/// Dónde guarda el plugin la cola de lectura. Mismo patrón que `CategoryStorageProvider`.
protocol ReadingQueueStorageProvider {
    func loadQueue() async throws -> ReadingQueueData
    func saveQueue(_ data: ReadingQueueData) async throws
}

/// Guarda la cola de lectura en su propio fichero, `reading_queue.json`, junto a `books.json`.
final class JSONReadingQueueStorageProvider: ReadingQueueStorageProvider {
    private let fileURL: URL

    init(filename: String = "reading_queue.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadQueue() async throws -> ReadingQueueData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(ReadingQueueData.self, from: data)
    }

    func saveQueue(_ data: ReadingQueueData) async throws {
        let encoded = try JSONEncoder().encode(data)
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL)
    }
}
#endif
