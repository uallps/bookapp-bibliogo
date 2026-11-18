import SwiftUI

/// Detalle de un libro. Recibe un enlace (@Binding) al libro de la lista:
/// lo que se edita aquí cambia el libro del ViewModel, sin copias.
struct BookDetailView: View {
    @Binding var book: Book
    /// F1 Progreso: nil en el producto sin el trait Progreso.
    let progress: Binding<ReadingProgress>?

    var body: some View {
        Form {
            TextField("Título del libro", text: $book.title)
            TextField("Autor (opcional)", text: authorBinding)
            Picker("Estado", selection: $book.status) {
                Text(ReadingStatus.pendiente.rawValue).tag(ReadingStatus.pendiente)
                Text(ReadingStatus.leyendo.rawValue).tag(ReadingStatus.leyendo)
                Text(ReadingStatus.terminado.rawValue).tag(ReadingStatus.terminado)
            }
#if Progreso
            if let progress {
                ProgressSection(progress: progress)
            }
#endif
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
