import SwiftUI

/// Detalle de un libro. Recibe un enlace (@Binding) al libro de la lista:
/// lo que se edita aquí cambia el libro del ViewModel, sin copias.
struct BookDetailView: View {
    @Binding var book: Book
    /// F1 Progreso del libro.
    let progress: Binding<ReadingProgress>?
    /// F2 Notas y citas: notas de este libro.
    @Binding var notes: [BookNote]
    /// F4 Valoraciones y reseñas: valoraciones de este libro.
    @Binding var reviews: [BookReview]
    /// F3 Categorías: la sección ya preparada por la lista. nil si no se muestra.
    var categories: CategoriesSection? = nil

    var body: some View {
        Form {
            TextField("Título del libro", text: $book.title)
            TextField("Autor (opcional)", text: authorBinding)
            Picker("Estado", selection: $book.status) {
                Text(ReadingStatus.pendiente.rawValue).tag(ReadingStatus.pendiente)
                Text(ReadingStatus.leyendo.rawValue).tag(ReadingStatus.leyendo)
                Text(ReadingStatus.terminado.rawValue).tag(ReadingStatus.terminado)
            }
            if let progress {
                ProgressSection(progress: progress)
            }
            NotesSection(notes: $notes, bookID: book.id)
            RatingsSection(reviews: $reviews, bookID: book.id)
            if let categories {
                categories
            }
        }
        .navigationTitle(book.title)
    }

    /// El autor es opcional: el campo vacío se guarda como nil.
    private var authorBinding: Binding<String> {
        Binding(
            get: { book.author ?? "" },
            set: { book.author = $0.isEmpty ? nil : $0 }
        )
    }
}
