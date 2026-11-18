import SwiftUI

/// F2 Notas y citas: sección del detalle que lista y permite añadir notas/citas de un libro.
struct NotesSection: View {
    /// Lista de notas de este libro: las edita in-situ.
    @Binding var notes: [BookNote]
    let bookID: UUID

    var body: some View {
        Section(header: notesSectionHeader) {
            ForEach($notes) { $note in
                NoteRowView(note: $note)
            }
            .onDelete { offsets in
                notes.remove(atOffsets: offsets)
            }
            Button(action: addNote) {
                Label("Añadir nota", systemImage: "note.text.badge.plus")
            }
            Button(action: addQuote) {
                Label("Añadir cita", systemImage: "quote.opening")
            }
        }
    }

    // MARK: - Helpers

    private var notesSectionHeader: some View {
        HStack {
            Text("Notas y citas")
            Spacer()
            if !notes.isEmpty {
                Text("\(notes.count)")
                    .bookCaption()
            }
        }
    }

    private func addNote() {
        notes.append(BookNote(bookID: bookID, kind: .note))
    }

    private func addQuote() {
        notes.append(BookNote(bookID: bookID, kind: .quote))
    }
}

/// Fila editable de una nota o cita individual.
private struct NoteRowView: View {
    @Binding var note: BookNote

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(note.kind.rawValue, systemImage: note.kind.systemImage)
                .bookCaption()

#if !canImport(SwiftOpenUI)
            TextField(note.kind == .quote ? "Texto de la cita…" : "Escribe tu nota…",
                      text: $note.text, axis: .vertical)
                .lineLimit(3...6)
#else
            TextField(note.kind == .quote ? "Texto de la cita…" : "Escribe tu nota…",
                      text: $note.text)
#endif

            pageField
        }
        .padding(.vertical, 4)
    }

    private var pageField: some View {
        HStack {
            Image(systemName: "book.pages")
                .bookCaption()
            TextField("Página (opcional)", text: pageBinding)
                .bookCaption()
#if os(iOS)
                .keyboardType(.numberPad)
#endif
        }
    }

    private var pageBinding: Binding<String> {
        Binding(
            get: { note.page.map(String.init) ?? "" },
            set: { newValue in
                let digits = newValue.filter { $0.isNumber }
                note.page = digits.isEmpty ? nil : Int(digits)
            }
        )
    }
}
