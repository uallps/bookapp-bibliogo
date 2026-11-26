import SwiftUI

/// F2 Notas y citas: sección del detalle que lista y permite añadir notas/citas de un libro.
struct NotesSection: View {
    /// Lista de notas de este libro: las edita in-situ.
    @Binding var notes: [BookNote]
    let bookID: UUID

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleNotesCard
#else
        openUINotesSection
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleNotesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Notas y citas", systemImage: "quote.opening")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                if !notes.isEmpty {
                    Text("\(notes.count)")
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                }
            }

            if notes.isEmpty {
                Text("Guarda aquí tus reflexiones personales o citas favoritas de esta lectura.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                VStack(spacing: 10) {
                    ForEach($notes) { $note in
                        AppleNoteItemView(note: $note) {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                notes.removeAll { $0.id == note.id }
                            }
                        }
                    }
                }
            }

            HStack(spacing: 10) {
                Button(action: addNote) {
                    Label("Añadir nota", systemImage: "note.text.badge.plus")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Color.bookSageSurface(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)

                Button(action: addQuote) {
                    Label("Añadir cita", systemImage: "quote.opening")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 11, style: .continuous)
                                .fill(Color.bookSageSurface(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }
#endif

    private var openUINotesSection: some View {
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

#if !canImport(SwiftOpenUI)
private struct AppleNoteItemView: View {
    @Binding var note: BookNote
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            if note.kind == .quote {
                RoundedRectangle(cornerRadius: 2)
                    .fill(note.kind.color)
                    .frame(width: 3)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label(note.kind.rawValue, systemImage: note.kind.systemImage)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(note.kind.color)
                    Spacer()
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }

                TextField(
                    note.kind == .quote ? "Texto de la cita…" : "Escribe tu nota…",
                    text: $note.text,
                    axis: .vertical
                )
                .textFieldStyle(.plain)
                .font(note.kind == .quote ? .system(.subheadline, design: .serif).italic() : .subheadline)
                .lineLimit(2...6)

                HStack(spacing: 6) {
                    Image(systemName: "book.pages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    TextField("Página (opcional)", text: pageBinding)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.secondary)
#if os(iOS)
                        .keyboardType(.numberPad)
#endif
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.bookBackground(for: colorScheme))
        )
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
#endif

/// Fila editable de una nota o cita individual (SwiftOpenUI).
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
