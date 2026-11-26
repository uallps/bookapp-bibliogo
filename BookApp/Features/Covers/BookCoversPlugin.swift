#if Portadas
import Foundation
import Observation

/// Plugin de O7 Foto de la portada.
/// Descarga automáticamente las portadas desde internet al arrancar o al añadir/editar libros,
/// y permite cambiarlas manualmente desde el detalle de cada libro.
@Observable
final class BookCoversPlugin: DataPlugin {
    /// Referencia compartida para que `BookCoverView` pueda mostrar la portada real
    /// en cualquier pantalla sin requerir cambios en las vistas de la lista.
    static weak var active: BookCoversPlugin?

    let name = "Portadas"

    private(set) var entries: [BookCoverEntry] = [] {
        didSet { saveEntries() }
    }

    /// Caché en memoria de bytes de imagen por `bookID` para renderizado inmediato.
    private(set) var imageDataByBookID: [UUID: Data] = [:]

    /// Libros que actualmente están buscando portada en internet.
    private(set) var loadingBookIDs: Set<UUID> = []

    /// Último mensaje de estado al buscar o cambiar la portada.
    var statusMessage: String?

    /// Libros ya intentados automáticamente para esa combinación `(título, autor)` sin éxito,
    /// para no repetir peticiones innecesarias en cada redibujo.
    @ObservationIgnored private var attemptedQueries: [UUID: String] = [:]
    @ObservationIgnored private let storageProvider: CoverStorageProvider
    @ObservationIgnored private var loaded = false

    init(storageProvider: CoverStorageProvider = JSONCoverStorageProvider()) {
        self.storageProvider = storageProvider
        BookCoversPlugin.active = self
        Task { await loadCovers() }
    }

    func loadCovers() async {
        guard !loaded else { return }
        loaded = true
        do {
            let loadedEntries = try await storageProvider.loadEntries()
            var cache: [UUID: Data] = [:]
            for entry in loadedEntries {
                if let data = storageProvider.loadImageData(filename: entry.localFilename) {
                    cache[entry.bookID] = data
                }
            }
            imageDataByBookID = cache
            entries = loadedEntries
        } catch {
            print("No se han cargado las portadas: \(error)")
        }
    }

    /// Devuelve los datos de la imagen de portada para un libro por su `bookID`.
    func imageData(for bookID: UUID) -> Data? {
        imageDataByBookID[bookID]
    }

    /// Busca por título y autor (para `BookCoverView` cuando no recibe `bookID`).
    func imageData(title: String, author: String?) -> Data? {
        let normalizedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let normalizedAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard let entry = entries.first(where: {
            $0.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedTitle
                && ($0.author?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == normalizedAuthor || normalizedAuthor == nil)
        }) else {
            return nil
        }
        return imageDataByBookID[entry.bookID]
    }

    func entry(for bookID: UUID) -> BookCoverEntry? {
        entries.first { $0.bookID == bookID }
    }

    func isLoading(_ bookID: UUID) -> Bool {
        loadingBookIDs.contains(bookID)
    }

    /// Guarda una imagen elegida manualmente por el usuario o descargada de internet.
    func setCover(data: Data, for book: Book, remoteURL: String? = nil, isCustom: Bool = false) {
        do {
            let filename = try storageProvider.saveImageData(data, for: book.id)
            let entry = BookCoverEntry(
                bookID: book.id,
                title: book.title,
                author: book.author,
                localFilename: filename,
                remoteURL: remoteURL,
                isCustom: isCustom
            )
            imageDataByBookID[book.id] = data
            var updated = entries
            updated.removeAll { $0.bookID == book.id }
            updated.append(entry)
            entries = updated
        } catch {
            print("No se pudo guardar la imagen de portada: \(error)")
        }
    }

    /// Elimina la portada de un libro.
    func removeCover(for bookID: UUID) {
        if let existing = entry(for: bookID) {
            storageProvider.deleteImage(filename: existing.localFilename)
        }
        imageDataByBookID.removeValue(forKey: bookID)
        entries.removeAll { $0.bookID == bookID }
    }

    /// Busca y descarga la portada desde internet por título y autor.
    func fetchCoverFromInternet(for book: Book, isManual: Bool = true) async {
        let cleanTitle = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return }
        guard !loadingBookIDs.contains(book.id) else { return }

        loadingBookIDs.insert(book.id)
        if isManual { statusMessage = nil }
        defer { loadingBookIDs.remove(book.id) }

        let sig = querySignature(for: book)
        attemptedQueries[book.id] = sig

        if let result = await CoverSearchService.fetchCover(title: book.title, author: book.author) {
            setCover(data: result.imageData, for: book, remoteURL: result.sourceURL, isCustom: false)
            if isManual {
                statusMessage = "Portada actualizada desde internet."
            }
        } else if isManual {
            statusMessage = "No se encontró portada en internet para «\(book.title)»."
        }
    }

    /// Sincroniza automáticamente las portadas de todos los libros:
    /// - Descarga la portada si el libro aún no tiene ninguna.
    /// - Si se editó el título o autor de un libro con portada automática, busca la nueva portada.
    /// - Respeta las portadas subidas manualmente (`isCustom == true`).
    func syncCovers(for books: [Book]) async {
        await loadCovers()

        for book in books {
            let cleanTitle = book.title.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !cleanTitle.isEmpty, cleanTitle.lowercased() != "libro nuevo" else { continue }

            let sig = querySignature(for: book)
            if let existing = entry(for: book.id) {
                if existing.isCustom { continue }
                let existingSig = "\(existing.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())|\(existing.author?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? "")"
                if existingSig == sig && imageData(for: book.id) != nil {
                    continue
                }
            }

            if attemptedQueries[book.id] == sig {
                continue
            }

            await fetchCoverFromInternet(for: book, isManual: false)
        }
    }

    // MARK: - DataPlugin

    func didDeleteBook(id: UUID) {
        attemptedQueries.removeValue(forKey: id)
        removeCover(for: id)
    }

    private func querySignature(for book: Book) -> String {
        let t = book.title.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let a = book.author?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return "\(t)|\(a)"
    }

    private func saveEntries() {
        let entries = entries
        Task {
            do {
                try await storageProvider.saveEntries(entries)
            } catch {
                print("No se han guardado las portadas: \(error)")
            }
        }
    }
}
#endif
