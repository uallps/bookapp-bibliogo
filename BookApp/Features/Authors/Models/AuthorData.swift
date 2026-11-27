#if Autores
import Foundation

/// O5 Autores: todo lo que guarda el plugin, las fichas de autor, en authors.json.
struct AuthorData: Codable {
    var profiles: [AuthorProfile] = []

    /// Datos de partida: ninguna ficha. No se crean fichas para los autores de los
    /// libros de ejemplo, para que el plugin no dependa de los datos de ejemplo del Core.
    static let sample = AuthorData()

    /// La ficha de un autor a partir de su clave (nombre normalizado).
    func profile(forKey key: String) -> AuthorProfile? {
        profiles.first { $0.key == key }
    }
}

/// O5 Autores: un autor de la biblioteca, calculado a partir de los libros.
/// No se guarda: los autores de la app son los nombres distintos de los libros.
struct AuthorSummary: Identifiable {
    let key: String
    let name: String
    let books: [Book]
    /// Media de las valoraciones medias (F4) de sus libros que tienen alguna.
    let averageRating: Double?

    var id: String { key }

    var booksText: String {
        books.count == 1 ? "1 libro" : "\(books.count) libros"
    }

    var ratingText: String? {
        averageRating.map { String(format: "%.1f", $0) }
    }

    /// Por ejemplo, "2 libros · 4.5 ★".
    var infoText: String {
        if let ratingText {
            return booksText + " · " + ratingText + " ★"
        }
        return booksText
    }

    /// Agrupa los libros por autor (los que no tienen autor no cuentan), en orden alfabético.
    static func authors(in books: [Book],
                        profiles: AuthorData,
                        rating: (UUID) -> Double?) -> [AuthorSummary] {
        var order: [String] = []
        var groups: [String: [Book]] = [:]
        for book in books {
            let key = AuthorProfile.key(for: book.author ?? "")
            guard !key.isEmpty else { continue }
            if groups[key] == nil { order.append(key) }
            groups[key, default: []].append(book)
        }
        return order.compactMap { key -> AuthorSummary? in
            guard let books = groups[key], let first = books.first else { return nil }
            let name = profiles.profile(forKey: key)?.name ?? AuthorProfile.tidy(first.author ?? "")
            let ratings = books.compactMap { rating($0.id) }
            let average = ratings.isEmpty ? nil : ratings.reduce(0, +) / Double(ratings.count)
            return AuthorSummary(key: key, name: name, books: books, averageRating: average)
        }
        .sorted { $0.name.lowercased() < $1.name.lowercased() }
    }
}
#endif
