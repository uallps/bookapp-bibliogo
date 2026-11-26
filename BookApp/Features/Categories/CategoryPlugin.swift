import SwiftUI
import Observation

/// Plugin de F3 Categorías. Guarda las categorías y qué libros tiene cada una en su
/// propio fichero; como plugin de datos, borra los enlaces de un libro cuando se
/// borra el libro; como plugin de vista, aporta las categorías de la fila, la sección
/// del detalle, el filtro de la biblioteca y su ajuste. F3 es común: no lleva trait
/// y se registra siempre.
@Observable
final class CategoryPlugin: DataPlugin, ViewPlugin {
    let name = "Categorías"

    /// Las categorías y sus enlaces. Cada cambio se guarda.
    private(set) var data = CategoryData.sample {
        didSet { save() }
    }

    /// Categoría elegida en el filtro de la biblioteca (CategoryFilter.all o un uuidString).
    /// Es estado de la pantalla: no se guarda.
    var filterSelection = CategoryFilter.all

    @ObservationIgnored private let config: AppConfig
    @ObservationIgnored private let storageProvider: CategoryStorageProvider
    @ObservationIgnored private var loaded = false

    init(config: AppConfig, storageProvider: CategoryStorageProvider = JSONCategoryStorageProvider()) {
        self.config = config
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

    // MARK: - ViewPlugin: las vistas que el plugin aporta

    /// El ajuste «Mostrar categorías».
    var isEnabled: Bool { config.showCategories }

    /// En la fila, las categorías del libro: por ejemplo "Novela · Clásicos".
    @ViewBuilder
    func bookRowView(for book: Book) -> some View {
        let names = categories(for: book.id).map(\.name)
        if !names.isEmpty {
            CategoryRowLabel(text: names.joined(separator: " · "))
        }
    }

    /// En el detalle, la sección para elegir y crear categorías.
    func bookDetailView(for book: Book) -> some View {
        CategoriesSection(
            allCategories: Binding(
                get: { self.categories },
                set: { _ in } // la lista de categorías solo cambia con onCreate y onDelete
            ),
            selected: Binding(
                get: { self.categoryIDs(for: book.id) },
                set: { self.updateCategories($0, for: book.id) }
            ),
            onCreate: { name in
                if let id = self.addCategory(named: name) {
                    self.setCategory(id, selected: true, for: book.id)
                }
            },
            onDelete: { self.removeCategory(id: $0) }
        )
    }

    /// En Ajustes, «Mostrar categorías».
    func settingsView() -> some View {
        FeatureToggle(
            title: "Mostrar categorías",
            subtitle: "Filtrar y mostrar etiquetas de género en la biblioteca",
            systemImage: Category.systemImage,
            isOn: Binding(
                get: { self.config.showCategories },
                set: { self.config.showCategories = $0 }
            )
        )
    }

    /// Encima de la biblioteca, el filtro por categoría (si ya hay alguna).
    @ViewBuilder
    func libraryView() -> some View {
        if !categories.isEmpty {
            CategoryFilterView(
                categories: categories,
                selection: Binding(
                    get: { self.filterSelection },
                    set: { self.filterSelection = $0 }
                )
            )
        }
    }

    /// Los libros de la categoría elegida en el filtro.
    func filterBooks(_ books: [Book]) -> [Book] {
        CategoryFilter.books(books, selection: filterSelection, in: data)
    }

    /// Las categorías no tienen pantalla propia.
    func screenView() -> EmptyView { EmptyView() }

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
