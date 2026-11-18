import SwiftUI

/// Fila de un libro. No conoce el ViewModel: recibe los datos, los flags y la acción.
struct BookRowView: View {
    let book: Book
    let progress: ReadingProgress?
    let showAuthors: Bool
    let showProgress: Bool
    let advanceStatus: () -> Void

    var body: some View {
        HStack {
            Button(action: advanceStatus) {
                Image(systemName: book.status.systemImage)
                    .foregroundColor(.bookAccent)
            }
            .buttonStyle(.plain)
            VStack(alignment: .leading) {
                Text(book.title)
                if showAuthors, let author = book.author {
                    Text(author)
                        .bookCaption()
                }
                Text(book.status.rawValue)
                    .bookCaption(color: book.status.color)
#if Progreso
                if showProgress, let progress {
                    Text(progressText(progress))
                        .bookCaption(color: progress.color)
                }
#endif
            }
        }
    }

    /// Texto del progreso. Se monta como String para que el % se muestre tal cual
    /// en todas las plataformas.
    private func progressText(_ progress: ReadingProgress) -> String {
        "Progreso: \(progress.percentage) % (\(progress.currentPage) de \(progress.totalPages) págs.)"
    }
}
