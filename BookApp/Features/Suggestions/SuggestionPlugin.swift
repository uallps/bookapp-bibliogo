#if Sugerencia
import SwiftUI
import Observation

/// Plugin de O1 Sugerencia de próxima lectura (trait `Sugerencia`).
/// - Como plugin de datos, limpia la sugerencia actual si el libro se borra o cambia de estado.
/// - Como plugin de vista, aporta su pantalla propia en la barra lateral y su ajuste en Ajustes.
@Observable
final class SuggestionPlugin: DataPlugin, ViewPlugin {
    let name = "Sugerencia de próxima lectura"

    /// Criterios de la estrategia por tiempo y extensión. Es estado de la pantalla: no se guarda.
    var criteria = SuggestionCriteria()
    private(set) var currentSuggestion: BookSuggestion?

    /// El ajuste «Mostrar sugerencias de lectura». Es del plugin, no de AppConfig:
    /// así el plugin se añade sin tocar el núcleo.
    var showSuggestions: Bool {
        didSet {
            defaults.set(showSuggestions, forKey: Self.showSuggestionsKey)
            // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
            defaults.synchronize()
        }
    }

    @ObservationIgnored private let library: BookListViewModel
    @ObservationIgnored private let strategy: SuggestionStrategy
    @ObservationIgnored private let defaults: UserDefaults

    private static let showSuggestionsKey = "showReadingSuggestions"

    init(
        library: BookListViewModel,
        strategy: SuggestionStrategy = ActiveSuggestionStrategy.current,
        defaults: UserDefaults = .standard
    ) {
        self.library = library
        self.strategy = strategy
        self.defaults = defaults
        showSuggestions = defaults.object(forKey: Self.showSuggestionsKey) as? Bool ?? true
    }

    var strategyName: String { strategy.strategyName }
    var strategyDescription: String { strategy.strategyDescription }
    var usesTimeAndLength: Bool { ActiveSuggestionStrategy.isTimeAndLength }

    /// Sugerencia visible en pantalla: devuelve únicamente `currentSuggestion` mientras
    /// el libro siga pendiente (nunca recalcula durante el redibujado).
    var displayedSuggestion: BookSuggestion? {
        guard let current = currentSuggestion,
              library.books.contains(where: { $0.id == current.book.id && $0.status == .pendiente }) else {
            return nil
        }
        return current
    }

    /// Calcula la sugerencia una sola vez si no hay ninguna válida (al entrar en la pantalla).
    func ensureSuggestion() {
        if displayedSuggestion == nil {
            suggestNext(avoidCurrent: false)
        }
    }

    /// Genera una nueva sugerencia (evitando repetir la actual cuando hay más de un pendiente).
    func suggestNext(avoidCurrent: Bool = true) {
        let excludedID = avoidCurrent ? currentSuggestion?.book.id : nil
        currentSuggestion = strategy.suggest(
            from: library.books,
            progress: library.progress,
            criteria: criteria,
            excluding: excludedID
        )
    }

    /// Marca el libro sugerido como «Leyendo» y actualiza la sugerencia.
    func startReading(_ book: Book) {
        library.advanceStatus(id: book.id)
        suggestNext(avoidCurrent: false)
    }

    // MARK: - DataPlugin: el registro nos avisa de lo que pasa con los libros

    func didChangeStatus(of book: Book, from oldStatus: ReadingStatus) {
        if currentSuggestion?.book.id == book.id, book.status != .pendiente {
            currentSuggestion = nil
        }
    }

    func didDeleteBook(id: UUID) {
        if currentSuggestion?.book.id == id {
            currentSuggestion = nil
        }
    }

    // MARK: - ViewPlugin: las vistas que el plugin aporta

    var isEnabled: Bool { showSuggestions }

    /// Las sugerencias no añaden vistas en la fila, el detalle ni encima de la biblioteca.
    func bookRowView(for book: Book) -> EmptyView { EmptyView() }
    func bookDetailView(for book: Book) -> EmptyView { EmptyView() }
    func libraryView() -> EmptyView { EmptyView() }

    var screenTitle: String? { "Sugerencia" }
    var screenSystemImage: String { "sparkles" }

    func screenView() -> NextReadingSuggestionView {
        NextReadingSuggestionView(plugin: self)
    }

    func settingsView() -> some View {
        FeatureToggle(
            title: "Mostrar sugerencias de lectura",
            subtitle: "Propone tu próxima lectura pendiente (\(strategyName.lowercased()))",
            systemImage: "sparkles",
            isOn: Binding(
                get: { self.showSuggestions },
                set: { self.showSuggestions = $0 }
            )
        )
    }
}
#endif
