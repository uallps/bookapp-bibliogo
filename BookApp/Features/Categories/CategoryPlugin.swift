import Foundation
import Observation

/// Plugin de F3 Categorías. Guarda las categorías y qué libros tiene cada una en su
/// propio fichero y, como plugin de datos, borra los enlaces de un libro cuando se
/// borra el libro. F3 es común: no lleva trait y se registra siempre.
@Observable
final class CategoryPlugin: DataPlugin {
    let name = "Categorías"

    /// Las categorías y sus enlaces. Cada cambio se guarda.
    private(set) var data = CategoryData.sample {
        didSet { save() }
    }

    @ObservationIgnored private let storageProvider: CategoryStorageProvider
    @ObservationIgnored private var loaded = false

    init(storageProvider: CategoryStorageProvider = JSONCategoryStorageProvider()) {
        self.storageProvider = storageProvider
        Task { await loadCategories() }
    }

    /// Carga las categorías guardadas, solo la primera vez.
    /// Si aún no hay fichero, se quedan las categorías de partida.
    func loadCategories() async {
        guard !loaded else { return }
        loaded = true
        do {
            data = try await storageProvider.loadCategories()
        } catch {
            print("No se han cargado las categorías: \(error)")
        }
    }

    /// Todas las categorías de la biblioteca.
    var categories: [Category] {
        data.categories
    }

    /// Las categorías de un libro.
    func categories(for bookID: UUID) -> [Category] {
        data.categories(for: bookID)
    }

    /// Los ids de las categorías de un libro (lo usa el detalle vía Binding).
    func categoryIDs(for bookID: UUID) -> [UUID] {
        categories(for: bookID).map(\.id)
    }

    /// Los ids de los libros que tienen esa categoría.
    func bookIDs(in categoryID: UUID) -> Set<UUID> {
        data.bookIDs(in: categoryID)
    }

    /// Los libros que se ven en la biblioteca con la categoría elegida en el filtro.
    func filteredBooks(_ books: [Book], selection: String) -> [Book] {
        CategoryFilter.books(books, selection: selection, in: data)
    }

    /// Crea una categoría y devuelve su id. Si ya hay una con ese nombre (sin distinguir
    /// mayúsculas) devuelve la que existe; si el nombre está vacío, nil.
    @discardableResult
    func addCategory(named name: String) -> UUID? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let existing = data.categories.first(where: { $0.name.lowercased() == trimmed.lowercased() }) {
            return existing.id
        }
        let category = Category(name: trimmed)
        data.categories.append(category)
        return category.id
    }

    /// Borra una categoría y todos sus enlaces con los libros.
    func removeCategory(id: UUID) {
        var updated = data
        updated.categories.removeAll { $0.id == id }
        updated.links.removeAll { $0.categoryID == id }
        data = updated // un solo cambio: se guarda una vez
    }

    /// Pone o quita una categoría a un libro.
    func setCategory(_ categoryID: UUID, selected: Bool, for bookID: UUID) {
        let link = BookCategory(bookID: bookID, categoryID: categoryID)
        if selected {
            guard !data.links.contains(link) else { return }
            data.links.append(link)
        } else {
            data.links.removeAll { $0 == link }
        }
    }

    /// Reemplaza todas las categorías de un libro de golpe (lo usa el detalle vía Binding).
    func updateCategories(_ categoryIDs: [UUID], for bookID: UUID) {
        var updated = data
        updated.links.removeAll { $0.bookID == bookID }
        updated.links.append(contentsOf: categoryIDs.map { BookCategory(bookID: bookID, categoryID: $0) })
        data = updated // un solo cambio: se guarda una vez
    }

    // MARK: - DataPlugin: el registro nos avisa al borrar un libro

    func willDeleteBook(_ book: Book) {
        guard data.links.contains(where: { $0.bookID == book.id }) else { return }
        updateCategories([], for: book.id)
        print("\(name): borradas las categorías de «\(book.title)»")
    }

    private func save() {
        let data = data
        Task {
            do {
                try await storageProvider.saveCategories(data)
            } catch {
                print("No se han guardado las categorías: \(error)")
            }
        }
    }
}
