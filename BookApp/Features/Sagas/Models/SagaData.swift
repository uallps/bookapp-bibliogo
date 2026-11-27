#if Sagas
import Foundation

/// O6 Sagas: una saga o serie de libros (El Señor de los Anillos, Fundación...).
struct Saga: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
}

/// O6 Sagas: un libro dentro de su saga y su número de orden (1, 2, 3...).
/// Es un dato del plugin, no de `Book`: se une al libro por su id.
struct SagaEntry: Codable, Hashable {
    let bookID: UUID
    var sagaID: UUID
    var order: Int
}

/// O6 Sagas: todo lo que guarda el plugin, en un solo fichero (sagas.json), para que
/// nunca haya una entrada guardada sin su saga. Un libro pertenece como mucho a una saga.
/// Es lógica pura, sin interfaz, para poder probarla sola.
struct SagaData: Codable {
    var sagas: [Saga] = []
    var entries: [SagaEntry] = []

    /// Datos de partida: ninguna saga. No se enlazan los libros de ejemplo del Core.
    static let sample = SagaData()

    /// La entrada de un libro, si está en alguna saga.
    func entry(for bookID: UUID) -> SagaEntry? {
        entries.first { $0.bookID == bookID }
    }

    /// La saga de un libro, si tiene.
    func saga(for bookID: UUID) -> Saga? {
        guard let entry = entry(for: bookID) else { return nil }
        return sagas.first { $0.id == entry.sagaID }
    }

    /// Las entradas de una saga, en orden.
    func entries(in sagaID: UUID) -> [SagaEntry] {
        entries.filter { $0.sagaID == sagaID }.sorted { $0.order < $1.order }
    }

    /// Crea una saga y devuelve su id. Si ya hay una con ese nombre (sin distinguir
    /// mayúsculas) devuelve la que existe; si el nombre está vacío, nil.
    mutating func addSaga(named name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = sagas.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return existing.id
        }
        let saga = Saga(name: trimmed)
        sagas.append(saga)
        return saga.id
    }

    /// Borra una saga y saca de ella a todos sus libros.
    mutating func removeSaga(id: UUID) {
        sagas.removeAll { $0.id == id }
        entries.removeAll { $0.sagaID == id }
    }

    /// Mete un libro en una saga (al final) o lo saca de la suya (nil).
    /// Si ya estaba en esa saga no cambia nada; si estaba en otra, deja la otra renumerada.
    mutating func setSaga(_ sagaID: UUID?, for bookID: UUID) {
        let old = entry(for: bookID)
        guard old?.sagaID != sagaID else { return }
        entries.removeAll { $0.bookID == bookID }
        if let old { renumber(old.sagaID) }
        guard let sagaID, sagas.contains(where: { $0.id == sagaID }) else { return }
        entries.append(SagaEntry(bookID: bookID, sagaID: sagaID, order: entries(in: sagaID).count + 1))
    }

    /// Mueve un libro un puesto dentro de su saga: -1 antes, +1 después.
    mutating func move(_ bookID: UUID, by step: Int) {
        guard let entry = entry(for: bookID) else { return }
        var ordered = entries(in: entry.sagaID)
        guard let index = ordered.firstIndex(where: { $0.bookID == bookID }) else { return }
        let target = index + step
        guard ordered.indices.contains(target) else { return }
        ordered.swapAt(index, target)
        apply(order: ordered.map(\.bookID), in: entry.sagaID)
    }

    /// Saca un libro de su saga (por ejemplo, porque se ha borrado) y renumera el resto.
    mutating func removeBook(_ bookID: UUID) {
        guard let old = entry(for: bookID) else { return }
        entries.removeAll { $0.bookID == bookID }
        renumber(old.sagaID)
    }

    /// Deja los números de una saga seguidos: 1, 2, 3...
    mutating func renumber(_ sagaID: UUID) {
        apply(order: entries(in: sagaID).map(\.bookID), in: sagaID)
    }

    private mutating func apply(order bookIDs: [UUID], in sagaID: UUID) {
        for (position, bookID) in bookIDs.enumerated() {
            if let index = entries.firstIndex(where: { $0.bookID == bookID && $0.sagaID == sagaID }) {
                entries[index].order = position + 1
            }
        }
    }
}

/// O6 Sagas: una saga con sus libros de la biblioteca, para las vistas.
struct SagaProgress: Identifiable {
    let saga: Saga
    /// Sus libros, en orden. Los que ya no están en la biblioteca no cuentan.
    let books: [Book]

    var id: UUID { saga.id }

    var finishedCount: Int { books.filter { $0.status == .terminado }.count }

    /// El siguiente por leer: el primero no terminado.
    var nextBook: Book? { books.first { $0.status != .terminado } }

    /// Terminada: tiene libros y todos están terminados.
    var isCompleted: Bool { !books.isEmpty && nextBook == nil }

    /// Por ejemplo, "2 de 3 leídos".
    var progressText: String {
        String(finishedCount) + " de " + String(books.count) + " leídos"
    }

    var booksText: String {
        books.count == 1 ? "1 libro" : String(books.count) + " libros"
    }
}
#endif
