#if Sugerencia
import Foundation

/// Tiempo disponible que el lector quiere dedicar a su próxima lectura.
enum AvailableTime: String, CaseIterable, Hashable, Identifiable {
    case short = "Un rato (≤ 2 h)"
    case medium = "Fin de semana (3–6 h)"
    case long = "Sin prisa (6+ h)"

    var id: String { rawValue }

    /// Páginas máximas recomendadas para el tiempo disponible (~35 págs/hora).
    var maxRecommendedPages: Int {
        switch self {
        case .short: return 150
        case .medium: return 350
        case .long: return Int.max
        }
    }

    /// Extensión objetivo orientativa para ordenar candidatos.
    var targetPages: Int {
        switch self {
        case .short: return 120
        case .medium: return 260
        case .long: return 500
        }
    }
}

/// Extensión preferida del libro según su número de páginas (F1 Progreso).
enum PreferredLength: String, CaseIterable, Hashable, Identifiable {
    case any = "Cualquiera"
    case short = "Corto (≤ 200 págs.)"
    case medium = "Medio (201–400 págs.)"
    case long = "Largo (> 400 págs.)"

    var id: String { rawValue }

    func matches(pages: Int) -> Bool {
        switch self {
        case .any: return true
        case .short: return pages <= 200
        case .medium: return pages > 200 && pages <= 400
        case .long: return pages > 400
        }
    }
}

/// Criterios de entrada para la estrategia por tiempo y extensión.
struct SuggestionCriteria: Equatable {
    var availableTime: AvailableTime = .medium
    var preferredLength: PreferredLength = .any
}

/// Resultado de una sugerencia de próxima lectura.
struct BookSuggestion: Equatable {
    let book: Book
    let totalPages: Int?
    let reason: String
    let estimatedReadingTime: String?

    static func == (lhs: BookSuggestion, rhs: BookSuggestion) -> Bool {
        lhs.book.id == rhs.book.id &&
        lhs.totalPages == rhs.totalPages &&
        lhs.reason == rhs.reason &&
        lhs.estimatedReadingTime == rhs.estimatedReadingTime
    }
}

/// Estrategia de sugerencia de próxima lectura (O1).
/// El grupo XOR del modelo de características obliga a que cada producto
/// active una única estrategia: aleatoria o por tiempo y extensión.
protocol SuggestionStrategy {
    var strategyName: String { get }
    var strategyDescription: String { get }
    func suggest(
        from books: [Book],
        progress: [ReadingProgress],
        criteria: SuggestionCriteria,
        excluding excludedBookID: UUID?
    ) -> BookSuggestion?
}

/// O1a: Sugerencia aleatoria entre los libros en estado Pendiente.
struct RandomSuggestionStrategy: SuggestionStrategy {
    let strategyName = "Aleatoria"
    let strategyDescription = "Elige al azar un libro de tu lista de pendientes."

    func suggest(
        from books: [Book],
        progress: [ReadingProgress],
        criteria: SuggestionCriteria,
        excluding excludedBookID: UUID?
    ) -> BookSuggestion? {
        let pending = books.filter { $0.status == .pendiente }
        guard !pending.isEmpty else { return nil }

        let pool = (pending.count > 1 && excludedBookID != nil)
            ? pending.filter { $0.id != excludedBookID }
            : pending

        guard let chosen = pool.randomElement() else { return nil }
        let pages = progress.first(where: { $0.bookID == chosen.id && $0.totalPages > 0 })?.totalPages
        let estimate = pages.map { Self.formatReadingTime(pages: $0) }
        let countText = pending.count == 1 ? "tu único libro pendiente" : "tus \(pending.count) libros pendientes"

        return BookSuggestion(
            book: chosen,
            totalPages: pages,
            reason: "Elegido al azar entre \(countText).",
            estimatedReadingTime: estimate
        )
    }

    static func formatReadingTime(pages: Int) -> String {
        let minutes = max(15, Int((Double(pages) / 35.0) * 60.0))
        if minutes < 60 {
            return "~\(minutes) min"
        }
        let hours = Double(minutes) / 60.0
        return String(format: "~%.1f h", hours)
    }
}

/// O1b: Sugerencia por tiempo disponible y extensión (requiere F1 Progreso).
struct TimeAndLengthSuggestionStrategy: SuggestionStrategy {
    let strategyName = "Por tiempo y extensión"
    let strategyDescription = "Propone el libro pendiente que mejor encaja con tu tiempo y extensión."

    func suggest(
        from books: [Book],
        progress: [ReadingProgress],
        criteria: SuggestionCriteria,
        excluding excludedBookID: UUID?
    ) -> BookSuggestion? {
        let pending = books.filter { $0.status == .pendiente }
        guard !pending.isEmpty else { return nil }

        let withPages: [(book: Book, pages: Int)] = pending.compactMap { book in
            guard let entry = progress.first(where: { $0.bookID == book.id }), entry.totalPages > 0 else {
                return nil
            }
            return (book, entry.totalPages)
        }

        if withPages.isEmpty {
            let pool = (pending.count > 1 && excludedBookID != nil)
                ? pending.filter { $0.id != excludedBookID }
                : pending
            guard let fallback = pool.randomElement() else { return nil }
            return BookSuggestion(
                book: fallback,
                totalPages: nil,
                reason: "Aún no hay páginas registradas en Progreso; te proponemos este pendiente.",
                estimatedReadingTime: nil
            )
        }

        let exactMatches = withPages.filter { item in
            criteria.preferredLength.matches(pages: item.pages) &&
            item.pages <= criteria.availableTime.maxRecommendedPages
        }

        let candidates: [(book: Book, pages: Int)]
        let isExactMatch: Bool
        if !exactMatches.isEmpty {
            candidates = exactMatches
            isExactMatch = true
        } else {
            candidates = withPages
            isExactMatch = false
        }

        let ranked = candidates.sorted { lhs, rhs in
            abs(lhs.pages - criteria.availableTime.targetPages) < abs(rhs.pages - criteria.availableTime.targetPages)
        }

        let filteredPool = (ranked.count > 1 && excludedBookID != nil)
            ? ranked.filter { $0.book.id != excludedBookID }
            : ranked

        guard let chosen = filteredPool.first else { return nil }
        let estimate = RandomSuggestionStrategy.formatReadingTime(pages: chosen.pages)
        let reason = isExactMatch
            ? "\(chosen.pages) págs. (\(estimate)) · Encaja con \(criteria.availableTime.rawValue.lowercased())."
            : "\(chosen.pages) págs. (\(estimate)) · Es la opción más cercana a tus criterios."

        return BookSuggestion(
            book: chosen.book,
            totalPages: chosen.pages,
            reason: reason,
            estimatedReadingTime: estimate
        )
    }
}

/// Selección XOR en tiempo de compilación: una única estrategia activa por producto.
enum ActiveSuggestionStrategy {
    #if SugerenciaAleatoria
    static let current: SuggestionStrategy = RandomSuggestionStrategy()
    static let isTimeAndLength = false
    #else
    static let current: SuggestionStrategy = TimeAndLengthSuggestionStrategy()
    static let isTimeAndLength = true
    #endif
}
#endif
