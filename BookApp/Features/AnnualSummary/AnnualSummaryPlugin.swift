#if ResumenAnual
import SwiftUI
import Observation

/// Plugin de O4 Resumen anual (trait `ResumenAnual`).
/// - Como plugin de datos, apunta la fecha en que se termina cada libro (la app no la
///   guardaba) y la quita si el libro deja de estar terminado o se borra.
/// - Como plugin de vista, aporta su pantalla en la barra lateral, la fecha de fin en el
///   detalle del libro y su ajuste.
@Observable
final class AnnualSummaryPlugin: DataPlugin, ViewPlugin {
    let name = "Resumen anual"

    /// Las fechas de fin. Cada cambio se guarda.
    private(set) var records: [FinishRecord] = [] {
        didSet { save() }
    }

    /// El año que se ve en la pantalla. Es estado de la pantalla: no se guarda.
    var selectedYear: Int

    /// El ajuste «Mostrar resumen anual». Es del plugin, no de AppConfig: así el plugin
    /// se añade sin tocar el núcleo.
    var showSummary: Bool {
        didSet {
            defaults.set(showSummary, forKey: Self.showSummaryKey)
            // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
            defaults.synchronize()
        }
    }

    @ObservationIgnored private let library: BookListViewModel
    @ObservationIgnored private let storageProvider: FinishRecordStorageProvider
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let calendar: Calendar
    @ObservationIgnored private var loaded = false

    private static let showSummaryKey = "showAnnualSummary"

    init(library: BookListViewModel,
         storageProvider: FinishRecordStorageProvider = JSONFinishRecordStorageProvider(),
         defaults: UserDefaults = .standard,
         calendar: Calendar = .current) {
        self.library = library
        self.storageProvider = storageProvider
        self.defaults = defaults
        self.calendar = calendar
        selectedYear = calendar.component(.year, from: Date())
        showSummary = defaults.object(forKey: Self.showSummaryKey) as? Bool ?? true
        Task { await loadRecords() }
    }

    /// Carga las fechas guardadas, solo la primera vez. Si aún no hay fichero, no hay ninguna.
    func loadRecords() async {
        guard !loaded else { return }
        loaded = true
        do {
            records = try await storageProvider.loadRecords()
        } catch {
            print("No se han cargado las fechas de fin: \(error)")
        }
    }

    // MARK: - Datos

    /// Cuándo se terminó un libro, si se sabe.
    func finishDate(for bookID: UUID) -> Date? {
        records.first { $0.bookID == bookID }?.finishedAt
    }

    /// Apunta (o cambia) la fecha de fin de un libro.
    func setFinishDate(_ date: Date, for bookID: UUID) {
        var updated = records.filter { $0.bookID != bookID }
        updated.append(FinishRecord(bookID: bookID, finishedAt: date))
        records = updated // un solo cambio: se guarda una vez
    }

    /// Quita la fecha de fin de un libro.
    func removeFinishDate(for bookID: UUID) {
        guard finishDate(for: bookID) != nil else { return }
        records.removeAll { $0.bookID == bookID }
    }

    /// El resumen del año elegido en la pantalla.
    var summary: AnnualSummary {
        AnnualSummary(
            year: selectedYear,
            records: records,
            books: library.books,
            pages: { [library] id in library.progress(for: id)?.totalPages },
            rating: { [library] id in library.averageRating(for: id) },
            calendar: calendar
        )
    }

    /// Los años que se pueden ver: los que tienen algún libro terminado y el actual.
    var years: [Int] {
        AnnualSummary.years(in: records, currentYear: calendar.component(.year, from: Date()), calendar: calendar)
    }

    /// Libros terminados de los que no se sabe la fecha (los que ya estaban terminados
    /// antes de añadir el resumen). No cuentan en ningún año.
    var booksWithoutDate: [Book] {
        library.books.filter { $0.status == .terminado && finishDate(for: $0.id) == nil }
    }

    /// Pasa al año anterior (+1: al siguiente) de los que tienen datos.
    func moveYear(by step: Int) {
        let ordered = years.sorted()
        guard let index = ordered.firstIndex(of: selectedYear) else {
            selectedYear = ordered.last ?? selectedYear
            return
        }
        let next = index + step
        guard ordered.indices.contains(next) else { return }
        selectedYear = ordered[next]
    }

    var canMoveToPreviousYear: Bool { years.min().map { selectedYear > $0 } ?? false }
    var canMoveToNextYear: Bool { years.max().map { selectedYear < $0 } ?? false }

    // MARK: - DataPlugin: el registro nos avisa de lo que pasa con los libros

    func didChangeStatus(of book: Book, from oldStatus: ReadingStatus) {
        if book.status == .terminado, oldStatus != .terminado {
            setFinishDate(Date(), for: book.id)
            print("\(name): «\(book.title)» terminado hoy")
        } else if oldStatus == .terminado, book.status != .terminado {
            // Vuelve a estar pendiente o en lectura: ya no cuenta como terminado.
            removeFinishDate(for: book.id)
        }
    }

    func didDeleteBook(id: UUID) {
        removeFinishDate(for: id)
    }

    // MARK: - ViewPlugin: las vistas que el plugin aporta

    var isEnabled: Bool { showSummary }

    /// El resumen no añade nada a la fila ni encima de la biblioteca.
    func bookRowView(for book: Book) -> EmptyView { EmptyView() }
    func libraryView() -> EmptyView { EmptyView() }

    var screenTitle: String? { "Resumen anual" }
    var screenSystemImage: String { "calendar" }

    func screenView() -> some View {
        AnnualSummaryView(plugin: self)
    }

    /// En el detalle, cuándo se terminó (o un botón para apuntarlo si no se sabe).
    @ViewBuilder
    func bookDetailView(for book: Book) -> some View {
        if book.status == .terminado {
            FinishDateSection(
                finishedAt: finishDate(for: book.id),
                markFinishedToday: { self.setFinishDate(Date(), for: book.id) }
            )
        }
    }

    func settingsView() -> some View {
        FeatureToggle(
            title: "Mostrar resumen anual",
            subtitle: "Tu año lector: libros terminados, páginas y lo más destacado",
            systemImage: "calendar",
            isOn: Binding(
                get: { self.showSummary },
                set: { self.showSummary = $0 }
            )
        )
    }

    private func save() {
        let records = records
        Task {
            do {
                try await storageProvider.saveRecords(records)
            } catch {
                print("No se han guardado las fechas de fin: \(error)")
            }
        }
    }
}
#endif
