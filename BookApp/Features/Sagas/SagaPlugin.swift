#if Sagas
import SwiftUI
import Observation

/// Plugin de O6 Sagas y series (trait `Sagas`).
/// - Guarda las sagas y el orden de sus libros en su propio fichero, sagas.json.
///   Un libro pertenece como mucho a una saga; `Book` no cambia.
/// - Como plugin de datos, saca de su saga un libro borrado y renumera el resto.
/// - Como plugin de vista, aporta «Saga · nº 2» en la fila, la sección del detalle para
///   elegir saga y orden, su pantalla «Sagas» y su ajuste.
/// - Para otras originales (Resumen anual, Logros), dentro de `#if Sagas`:
///   `saga(for:)`, `nextBook(in:)`, `completedSagas(books:)` y `progress(of:)`.
@Observable
final class SagaPlugin: DataPlugin, ViewPlugin {
    let name = "Sagas"

    /// Las sagas y sus libros. Cada cambio se guarda.
    private(set) var data = SagaData.sample {
        didSet { save() }
    }

    /// El ajuste «Mostrar sagas». Es del plugin, no de AppConfig: así el plugin se añade
    /// sin tocar el núcleo.
    var showSagas: Bool {
        didSet {
            defaults.set(showSagas, forKey: Self.showSagasKey)
            // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
            defaults.synchronize()
        }
    }

    @ObservationIgnored private let library: BookListViewModel
    @ObservationIgnored private let storageProvider: SagaStorageProvider
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var loaded = false

    private static let showSagasKey = "showSagas"

    init(library: BookListViewModel,
         storageProvider: SagaStorageProvider = JSONSagaStorageProvider(),
         defaults: UserDefaults = .standard) {
        self.library = library
        self.storageProvider = storageProvider
        self.defaults = defaults
        showSagas = defaults.object(forKey: Self.showSagasKey) as? Bool ?? true
        Task { await loadSagas() }
    }

    /// Carga las sagas guardadas, solo la primera vez. Si aún no hay fichero, no hay ninguna.
    func loadSagas() async {
        guard !loaded else { return }
        loaded = true
        do {
            data = try await storageProvider.loadSagas()
        } catch {
            print("No se han cargado las sagas: \(error)")
        }
    }

    // MARK: - Consultas (también para otras originales)

    /// Todas las sagas, en el orden en que se crearon.
    var sagas: [Saga] { data.sagas }

    /// La saga de un libro, si tiene.
    func saga(for bookID: UUID) -> Saga? {
        data.saga(for: bookID)
    }

    /// El número de un libro dentro de su saga (1, 2...), si está en alguna.
    func order(of bookID: UUID) -> Int? {
        data.entry(for: bookID)?.order
    }

    /// Una saga con sus libros de la biblioteca, en orden.
    func progress(of saga: Saga, books: [Book]? = nil) -> SagaProgress {
        let books = books ?? library.books
        let byID = Dictionary(books.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let ordered = data.entries(in: saga.id).compactMap { byID[$0.bookID] }
        return SagaProgress(saga: saga, books: ordered)
    }

    /// Todas las sagas con sus libros, para la pantalla.
    var allProgress: [SagaProgress] {
        sagas.map { progress(of: $0) }
    }

    /// Los libros de una saga, en orden.
    func books(in sagaID: UUID) -> [Book] {
        guard let saga = sagas.first(where: { $0.id == sagaID }) else { return [] }
        return progress(of: saga).books
    }

    /// El siguiente libro por leer de una saga: el primero no terminado.
    func nextBook(in sagaID: UUID) -> Book? {
        guard let saga = sagas.first(where: { $0.id == sagaID }) else { return nil }
        return progress(of: saga).nextBook
    }

    /// Las sagas terminadas: tienen libros y todos están terminados.
    func completedSagas(books: [Book]) -> [Saga] {
        sagas.filter { progress(of: $0, books: books).isCompleted }
    }

    // MARK: - Cambios

    /// Crea una saga y devuelve su id (la que ya existe si el nombre se repite).
    @discardableResult
    func addSaga(named name: String) -> UUID? {
        var updated = data
        let id = updated.addSaga(named: name)
        data = updated // un solo cambio: se guarda una vez
        return id
    }

    /// Borra una saga; sus libros se quedan sin saga.
    func removeSaga(id: UUID) {
        var updated = data
        updated.removeSaga(id: id)
        data = updated
    }

    /// Mete un libro en una saga (al final) o lo saca de la suya (nil).
    func setSaga(_ sagaID: UUID?, for bookID: UUID) {
        var updated = data
        updated.setSaga(sagaID, for: bookID)
        data = updated
    }

    /// Crea una saga con ese nombre y mete en ella el libro.
    func createSaga(named name: String, for bookID: UUID) {
        var updated = data
        guard let id = updated.addSaga(named: name) else { return }
        updated.setSaga(id, for: bookID)
        data = updated
    }

    /// Mueve un libro un puesto en su saga: -1 antes, +1 después.
    func move(_ bookID: UUID, by step: Int) {
        var updated = data
        updated.move(bookID, by: step)
        data = updated
    }

    /// Selección del Picker del detalle: "ninguna" o el uuidString de la saga.
    /// Es un String para que las etiquetas coincidan también con SwiftOpenUI.
    static let noSaga = "ninguna"

    func selectionBinding(for bookID: UUID) -> Binding<String> {
        Binding(
            get: { self.saga(for: bookID)?.id.uuidString ?? Self.noSaga },
            set: { self.setSaga(UUID(uuidString: $0), for: bookID) }
        )
    }

    // MARK: - DataPlugin: el registro nos avisa al borrar un libro

    func didDeleteBook(id: UUID) {
        guard data.entry(for: id) != nil else { return }
        var updated = data
        updated.removeBook(id)
        data = updated
        print("\(name): libro borrado, saga renumerada")
    }

    // MARK: - ViewPlugin: las vistas que el plugin aporta

    var isEnabled: Bool { showSagas }

    /// En la fila, "Nombre de la saga · nº 2".
    @ViewBuilder
    func bookRowView(for book: Book) -> some View {
        if let saga = saga(for: book.id), let order = order(of: book.id) {
            SagaRowLabel(text: saga.name + " · nº " + String(order))
        }
    }

    /// En el detalle, la sección para elegir la saga, crear una y cambiar el orden.
    func bookDetailView(for book: Book) -> some View {
        let current = saga(for: book.id)
        return SagaSection(
            sagas: sagas,
            selection: selectionBinding(for: book.id),
            order: order(of: book.id),
            count: current.map { books(in: $0.id).count } ?? 0,
            onCreate: { self.createSaga(named: $0, for: book.id) },
            onMove: { self.move(book.id, by: $0) }
        )
    }

    /// En Ajustes, «Mostrar sagas».
    func settingsView() -> some View {
        FeatureToggle(
            title: "Mostrar sagas",
            subtitle: "Agrupar libros en sagas ordenadas y ver cuál toca leer después",
            systemImage: Saga.systemImage,
            isOn: Binding(
                get: { self.showSagas },
                set: { self.showSagas = $0 }
            )
        )
    }

    /// Las sagas no añaden nada encima de la biblioteca.
    func libraryView() -> EmptyView { EmptyView() }

    var screenTitle: String? { "Sagas" }
    var screenSystemImage: String { Saga.systemImage }

    /// Su pantalla: cada saga con sus libros y el siguiente por leer.
    func screenView() -> some View {
        SagasView(plugin: self)
    }

    private func save() {
        let data = data
        Task {
            do {
                try await storageProvider.saveSagas(data)
            } catch {
                print("No se han guardado las sagas: \(error)")
            }
        }
    }
}
#endif
