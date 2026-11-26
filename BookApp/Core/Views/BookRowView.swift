import SwiftUI

/// Fila de un libro. No conoce el ViewModel: recibe los datos, los flags y la acción.
struct BookRowView: View {
    let book: Book
    let progress: ReadingProgress?
    var averageRating: Double? = nil
    var reviewsCount: Int = 0
    let showAuthors: Bool
    let showProgress: Bool
    var showRatings: Bool = true
    let advanceStatus: () -> Void
    /// F3 Categorías: por ejemplo "Novela · Clásicos". nil si no hay o no se muestran.
    var categoryText: String? = nil

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleCardBody
#else
        openUIBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleCardBody: some View {
        HStack(alignment: .center, spacing: 14) {
            BookCoverView(title: book.title, author: book.author, width: 52, height: 74)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text(book.status.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(book.status == .leyendo ? .white : Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(book.status == .leyendo ? Color.bookAccent : Color.bookSageSurface(for: colorScheme))
                        )

                    if showRatings, let average = averageRating, reviewsCount > 0 {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.bookStar)
                                .font(.system(size: 9))
                            Text(ratingText(average: average, count: reviewsCount))
                                .font(.caption2.weight(.semibold))
                                .foregroundColor(.bookStar)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(
                            Capsule()
                                .fill(Color.bookStarSurface(for: colorScheme))
                        )
                    }
                }

                Text(book.title.isEmpty ? "Sin título" : book.title)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                if showAuthors, let author = book.author, !author.isEmpty {
                    Text(author)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                if let categoryText {
                    HStack(spacing: 4) {
                        Image(systemName: Category.systemImage)
                            .font(.system(size: 9))
                            .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                        Text(categoryText)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                            .lineLimit(1)
                    }
                }

                if showProgress, let progress, progress.totalPages > 0 {
                    VStack(alignment: .leading, spacing: 4) {
                        BiblioProgressBar(
                            progress: Double(progress.percentage) / 100.0,
                            color: progress.color,
                            height: 5
                        )
                        Text("\(progress.percentage)% · Pág. \(progress.currentPage) de \(progress.totalPages)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer(minLength: 4)

            Button(action: advanceStatus) {
                Image(systemName: book.status.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(book.status == .leyendo ? Color.bookAccentAdaptive(for: colorScheme) : book.status.color)
                    .frame(width: 34, height: 34)
                    .background(
                        Circle()
                            .fill(Color.bookSageSurface(for: colorScheme))
                    )
            }
            .buttonStyle(.plain)
            .help("Cambiar estado de lectura")
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 14)
    }
#endif

    private var openUIBody: some View {
        HStack(spacing: 12) {
            Button(action: advanceStatus) {
                Image(systemName: book.status.systemImage)
                    .font(.title3)
                    .foregroundColor(book.status.color)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(book.status.rawValue)
                        .font(.caption2)
                        .bold()
                        .foregroundColor(book.status == .leyendo ? .white : Color.bookSageDark)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(book.status == .leyendo ? Color.bookAccent : Color.bookSage)
                        .cornerRadius(4)

                    if showRatings, let average = averageRating, reviewsCount > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.bookStar)
                                .font(.caption2)
                            Text(ratingText(average: average, count: reviewsCount))
                                .bookCaption(color: .bookStar)
                        }
                    }
                }

                Text(book.title)
                    .font(.headline)

                if showAuthors, let author = book.author {
                    Text(author)
                        .font(.subheadline)
                        .bookCaption()
                }

                if showProgress, let progress {
                    Text(progressText(progress))
                        .bookCaption(color: progress.color)
                }

                if let categoryText {
                    HStack(spacing: 3) {
                        Image(systemName: Category.systemImage)
                            .foregroundColor(Category.color)
                        Text(categoryText)
                            .bookCaption(color: Category.color)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }

    /// Texto con la media de valoración y el recuento de reseñas.
    private func ratingText(average: Double, count: Int) -> String {
        String(format: "%.1f (%d)", average, count)
    }

    /// Texto del progreso. Se monta como String para que el % se muestre tal cual
    /// en todas las plataformas.
    private func progressText(_ progress: ReadingProgress) -> String {
        "Progreso: \(progress.percentage) % (\(progress.currentPage) de \(progress.totalPages) págs.)"
    }
}
