#if Sugerencia
import SwiftUI
import Observation

/// Plugin de O1 Sugerencia de próxima lectura.
/// Cumple ViewPlugin para aportar su pantalla propia en la barra lateral sin que el núcleo la conozca.
@Observable
final class SuggestionPlugin: ViewPlugin {
    let name = "Sugerencia de próxima lectura"

    var criteria = SuggestionCriteria()
    private(set) var currentSuggestion: BookSuggestion?

    @ObservationIgnored private let library: BookListViewModel
    @ObservationIgnored private let strategy: SuggestionStrategy

    init(
        library: BookListViewModel,
        strategy: SuggestionStrategy = ActiveSuggestionStrategy.current
    ) {
        self.library = library
        self.strategy = strategy
    }

    var strategyName: String { strategy.strategyName }
    var strategyDescription: String { strategy.strategyDescription }
    var usesTimeAndLength: Bool { ActiveSuggestionStrategy.isTimeAndLength }

    /// Calcula una sugerencia inicial o actualiza la actual si el libro ya no está pendiente.
    func ensureSuggestion(books: [Book], progress: [ReadingProgress]) {
        if let current = currentSuggestion,
           books.contains(where: { $0.id == current.book.id && $0.status == .pendiente }) {
            return
        }
        suggestNext(books: books, progress: progress, avoidCurrent: false)
    }

    /// Genera una nueva sugerencia (evitando repetir la actual cuando hay más de un pendiente).
    func suggestNext(books: [Book], progress: [ReadingProgress], avoidCurrent: Bool = true) {
        let excludedID = avoidCurrent ? currentSuggestion?.book.id : nil
        currentSuggestion = strategy.suggest(
            from: books,
            progress: progress,
            criteria: criteria,
            excluding: excludedID
        )
    }

    // MARK: - ViewPlugin

    typealias ScreenContent = NextReadingSuggestionView
    var screenTitle: String? { "Sugerencia" }
    var screenSystemImage: String { "sparkles" }

    @ViewBuilder
    func screenView() -> NextReadingSuggestionView {
        NextReadingSuggestionView(viewModel: library, plugin: self)
    }
}
#endif
