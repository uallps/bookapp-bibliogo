#if ResumenAnual
import Foundation

/// O4 Resumen anual: las cifras de un año. Es lógica pura, sin interfaz: recibe los
/// registros y los datos que necesita como funciones, así se puede probar sola.
struct AnnualSummary {
    /// Un libro terminado en el año.
    struct Entry: Identifiable {
        let book: Book
        let finishedAt: Date
        var id: UUID { book.id }
    }

    /// Los libros terminados en un mes.
    struct Month: Identifiable {
        /// 1 = enero ... 12 = diciembre.
        let number: Int
        let entries: [Entry]
        var id: Int { number }
        var name: String { SpanishDate.monthName(number) }
    }

    /// El libro mejor valorado del año.
    struct BestRated {
        let book: Book
        let rating: Double
    }

    let year: Int
    /// Libros terminados en el año, del más antiguo al más reciente.
    let entries: [Entry]
    /// Suma de las páginas (F1 Progreso) de los libros terminados que las tienen.
    let pagesRead: Int
    /// El mejor valorado (F4 Valoraciones). nil si ninguno tiene valoraciones.
    let bestRated: BestRated?

    /// - Parameters:
    ///   - records: las fechas de fin guardadas por el plugin.
    ///   - books: los libros de la biblioteca (los borrados ya no cuentan).
    ///   - pages: páginas totales de un libro, si se conocen.
    ///   - rating: valoración media de un libro, si tiene.
    init(year: Int,
         records: [FinishRecord],
         books: [Book],
         pages: (UUID) -> Int?,
         rating: (UUID) -> Double?,
         calendar: Calendar = .current) {
        let byID = Dictionary(books.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let finished = records
            .filter { calendar.component(.year, from: $0.finishedAt) == year }
            .compactMap { record in
                byID[record.bookID].map { Entry(book: $0, finishedAt: record.finishedAt) }
            }
            .sorted { $0.finishedAt < $1.finishedAt }

        self.year = year
        entries = finished
        pagesRead = finished.reduce(0) { total, entry in
            total + max(pages(entry.book.id) ?? 0, 0)
        }
        bestRated = finished
            .compactMap { entry in rating(entry.book.id).map { BestRated(book: entry.book, rating: $0) } }
            .max { $0.rating < $1.rating }
        months = Self.groupByMonth(finished, calendar: calendar)
    }

    /// Los meses con algún libro terminado, en orden.
    let months: [Month]

    /// El mes con más libros terminados (en empate, el primero). nil si no hay ninguno.
    var busiestMonth: Month? {
        months.max { lhs, rhs in
            lhs.entries.count < rhs.entries.count
                || (lhs.entries.count == rhs.entries.count && lhs.number > rhs.number)
        }
    }

    var finishedCount: Int { entries.count }

    /// Los años que tienen algún libro terminado, más el año actual, del más reciente al más antiguo.
    static func years(in records: [FinishRecord], currentYear: Int, calendar: Calendar = .current) -> [Int] {
        let years = Set(records.map { calendar.component(.year, from: $0.finishedAt) }).union([currentYear])
        return years.sorted(by: >)
    }

    private static func groupByMonth(_ entries: [Entry], calendar: Calendar) -> [Month] {
        let grouped = Dictionary(grouping: entries) { calendar.component(.month, from: $0.finishedAt) }
        return grouped.keys.sorted().map { Month(number: $0, entries: grouped[$0] ?? []) }
    }
}

/// Fechas en español sin depender del idioma del sistema (en Linux y Windows puede no estar).
enum SpanishDate {
    private static let months = [
        "enero", "febrero", "marzo", "abril", "mayo", "junio",
        "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre",
    ]

    /// Nombre del mes (1 = enero), con la inicial en mayúscula.
    static func monthName(_ number: Int) -> String {
        guard (1...12).contains(number) else { return "" }
        let name = months[number - 1]
        return name.prefix(1).uppercased() + name.dropFirst()
    }

    /// Por ejemplo, "26 de noviembre de 2026".
    static func long(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.day, .month, .year], from: date)
        guard let day = parts.day, let month = parts.month, let year = parts.year else { return "" }
        return "\(day) de \(months[month - 1]) de \(year)"
    }

    /// Por ejemplo, "26 nov".
    static func short(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.day, .month], from: date)
        guard let day = parts.day, let month = parts.month else { return "" }
        return "\(day) \(months[month - 1].prefix(3))"
    }
}
#endif
