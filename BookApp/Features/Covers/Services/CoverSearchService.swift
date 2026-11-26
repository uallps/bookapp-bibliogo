#if Portadas
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Resultado de buscar una portada en internet.
struct FetchedCoverResult {
    let imageData: Data
    let sourceURL: String
}

/// Busca y descarga la portada de un libro a partir de su título y autor
/// usando Open Library (y Google Books como respaldo).
enum CoverSearchService {
    static func fetchCover(title: String, author: String?) async -> FetchedCoverResult? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return nil }
        let cleanAuthor = author?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = await searchOpenLibrary(title: cleanTitle, author: cleanAuthor),
           let data = await downloadImage(from: url) {
            return FetchedCoverResult(imageData: data, sourceURL: url.absoluteString)
        }

        if let url = await searchGoogleBooks(title: cleanTitle, author: cleanAuthor),
           let data = await downloadImage(from: url) {
            return FetchedCoverResult(imageData: data, sourceURL: url.absoluteString)
        }

        return nil
    }

    // MARK: - Open Library

    private static func searchOpenLibrary(title: String, author: String?) async -> URL? {
        var components = URLComponents(string: "https://openlibrary.org/search.json")
        var queryItems = [
            URLQueryItem(name: "title", value: title),
            URLQueryItem(name: "limit", value: "5")
        ]
        if let author, !author.isEmpty {
            queryItems.append(URLQueryItem(name: "author", value: author))
        }
        components?.queryItems = queryItems

        guard let url = components?.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(OpenLibraryResponse.self, from: data)
            if let coverID = response.docs.compactMap(\.cover_i).first {
                return URL(string: "https://covers.openlibrary.org/b/id/\(coverID)-L.jpg")
            }
        } catch {
            print("Open Library error: \(error)")
        }
        return nil
    }

    // MARK: - Google Books (respaldo)

    private static func searchGoogleBooks(title: String, author: String?) async -> URL? {
        var query = "intitle:\(title)"
        if let author, !author.isEmpty {
            query += "+inauthor:\(author)"
        }
        var components = URLComponents(string: "https://www.googleapis.com/books/v1/volumes")
        components?.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "5")
        ]

        guard let url = components?.url else { return nil }
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(GoogleBooksResponse.self, from: data)
            for item in response.items ?? [] {
                if let raw = item.volumeInfo.imageLinks?.thumbnail ?? item.volumeInfo.imageLinks?.smallThumbnail {
                    let https = raw.replacingOccurrences(of: "http://", with: "https://")
                    if let imageURL = URL(string: https) {
                        return imageURL
                    }
                }
            }
        } catch {
            print("Google Books error: \(error)")
        }
        return nil
    }

    private static func downloadImage(from url: URL) async -> Data? {
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                return nil
            }
            return data.isEmpty ? nil : data
        } catch {
            print("Error descargando portada: \(error)")
            return nil
        }
    }
}

private struct OpenLibraryResponse: Decodable {
    let docs: [OpenLibraryDoc]
}

private struct OpenLibraryDoc: Decodable {
    let cover_i: Int?
}

private struct GoogleBooksResponse: Decodable {
    let items: [GoogleBookItem]?
}

private struct GoogleBookItem: Decodable {
    let volumeInfo: GoogleVolumeInfo
}

private struct GoogleVolumeInfo: Decodable {
    let imageLinks: GoogleImageLinks?
}

private struct GoogleImageLinks: Decodable {
    let thumbnail: String?
    let smallThumbnail: String?
}
#endif
