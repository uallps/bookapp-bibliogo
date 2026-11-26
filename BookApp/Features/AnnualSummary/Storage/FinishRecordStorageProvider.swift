#if ResumenAnual
import Foundation

/// Dónde guarda el plugin las fechas de fin. Mismo patrón que `StorageProvider`.
protocol FinishRecordStorageProvider {
    func loadRecords() async throws -> [FinishRecord]
    func saveRecords(_ records: [FinishRecord]) async throws
}

/// Guarda las fechas en su propio fichero, finished_books.json, junto a books.json.
final class JSONFinishRecordStorageProvider: FinishRecordStorageProvider {
    private let fileURL: URL

    init(filename: String = "finished_books.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadRecords() async throws -> [FinishRecord] {
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([FinishRecord].self, from: data)
    }

    func saveRecords(_ records: [FinishRecord]) async throws {
        let encoder = JSONEncoder()
        // Fechas legibles en el fichero (2026-11-26T18:00:00Z).
        encoder.dateEncodingStrategy = .iso8601
        let encoded = try encoder.encode(records)
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL)
    }
}
#endif
