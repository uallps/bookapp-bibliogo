#if ColaLectura
import Foundation
import Observation

/// Plugin de O8 Cola de lectura. Mantiene el orden de los próximos libros en su propio
/// fichero (`reading_queue.json`) y, como `DataPlugin`, actualiza la cola cuando un libro
/// se borra o pasa a estar en lectura / terminado.
@Observable
final class ReadingQueuePlugin: DataPlugin {
    let name = "Cola de lectura"

    /// Orden actual de los libros en cola. Cada cambio se guarda en segundo plano.
    private(set) var data = ReadingQueueData.sample {
        didSet { save() }
    }

    @ObservationIgnored private let storageProvider: ReadingQueueStorageProvider
    @ObservationIgnored private var loaded = false

    init(storageProvider: ReadingQueueStorageProvider = JSONReadingQueueStorageProvider()) {
        self.storageProvider = storageProvider
        Task { await loadQueue() }
    }

    /// Carga la cola guardada la primera vez que se inicia el plugin.
    func loadQueue() async {
        guard !loaded else { return }
        loaded = true
        do {
            data = try await storageProvider.loadQueue()
        } catch {
            print("No se ha cargado la cola de lectura: \(error)")
        }
    }

    /// Devuelve los libros presentes en la cola respetando su orden exacto.
    func queuedBooks(from books: [Book]) -> [Book] {
        let byID = Dictionary(uniqueKeysWithValues: books.map { ($0.id, $0) })
        return data.orderedBookIDs.compactMap { byID[$0] }
    }

    /// Primer libro de la cola (útil para integraciones como O1 Sugerencia).
    func nextBook(in books: [Book]) -> Book? {
        queuedBooks(from: books).first
    }

    /// Libros que aún no están en la cola, priorizando los pendientes.
    func availableBooks(from books: [Book]) -> [Book] {
        let queued = Set(data.orderedBookIDs)
        return books
            .filter { !queued.contains($0.id) }
            .sorted { lhs, rhs in
                (lhs.status == .pendiente) && (rhs.status != .pendiente)
            }
    }

    /// Añade un libro al final de la cola si no estaba ya incluido.
    func enqueue(_ bookID: UUID) {
        guard !data.orderedBookIDs.contains(bookID) else { return }
        data.orderedBookIDs.append(bookID)
    }

    /// Quita un libro de la cola.
    func remove(bookID: UUID) {
        guard data.orderedBookIDs.contains(bookID) else { return }
        data.orderedBookIDs.removeAll { $0 == bookID }
    }

    /// Sube una posición al libro en la cola.
    func moveUp(bookID: UUID) {
        guard let index = data.orderedBookIDs.firstIndex(of: bookID), index > 0 else { return }
        var updated = data.orderedBookIDs
        updated.swapAt(index, index - 1)
        data = ReadingQueueData(orderedBookIDs: updated)
    }

    /// Baja una posición al libro en la cola.
    func moveDown(bookID: UUID) {
        guard let index = data.orderedBookIDs.firstIndex(of: bookID),
              index < data.orderedBookIDs.count - 1 else { return }
        var updated = data.orderedBookIDs
        updated.swapAt(index, index + 1)
        data = ReadingQueueData(orderedBookIDs: updated)
    }

    // MARK: - DataPlugin

    func didDeleteBook(id: UUID) {
        remove(bookID: id)
    }

    func didChangeStatus(of book: Book, from oldStatus: ReadingStatus) {
        // Si el libro pasa a Leyendo o Terminado, sale de la cola de próximos libros.
        if book.status != .pendiente {
            remove(bookID: book.id)
        }
    }

    private func save() {
        let data = data
        Task {
            do {
                try await storageProvider.saveQueue(data)
            } catch {
                print("No se ha guardado la cola de lectura: \(error)")
            }
        }
    }
}
#endif
