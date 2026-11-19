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

    var body: some View {
        HStack {
            Button(action: advanceStatus) {
                Image(systemName: book.status.systemImage)
                    .foregroundColor(.bookAccent)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading, spacing: 2) {
                Text(book.title)
                if showAuthors, let author = book.author {
                    Text(author)
                        .bookCaption()
                }
                Text(book.status.rawValue)
                    .bookCaption(color: book.status.color)
                if showProgress, let progress {
                    Text(progressText(progress))
                        .bookCaption(color: progress.color)
                }
                if showRatings, let average = averageRating, reviewsCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.orange)
                        Text(ratingText(average: average, count: reviewsCount))
                            .bookCaption(color: .orange)
                    }
                }
            }
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
