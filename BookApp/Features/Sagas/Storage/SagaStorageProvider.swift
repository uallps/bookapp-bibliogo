#if Sagas
import Foundation

/// Dónde guarda el plugin sus sagas. Mismo patrón que `StorageProvider`.
protocol SagaStorageProvider {
    func loadSagas() async throws -> SagaData
    func saveSagas(_ data: SagaData) async throws
}

/// Guarda las sagas y sus libros en su propio fichero, sagas.json, junto a books.json.
final class JSONSagaStorageProvider: SagaStorageProvider {
    private let fileURL: URL

    init(filename: String = "sagas.json") {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = documents.appendingPathComponent(filename)
    }

    func loadSagas() async throws -> SagaData {
        let data = try Data(contentsOf: fileURL)
        return try JSONDecoder().decode(SagaData.self, from: data)
    }

    func saveSagas(_ data: SagaData) async throws {
        let encoded = try JSONEncoder().encode(data)
        // La carpeta Documentos no existe en todos los sistemas (por ejemplo, un Linux mínimo).
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try encoded.write(to: fileURL)
    }
}
#endif
