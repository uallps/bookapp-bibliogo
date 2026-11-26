#if ColaLectura
import SwiftUI

/// O8 Cola de lectura: vista para ordenar los próximos libros y añadir o quitar títulos.
/// Tiene interfaz editorial BiblioGo en Apple (`appleQueueBody`) y versión compatible con SwiftOpenUI (`openUIQueueBody`).
struct ReadingQueueView: View {
    let books: [Book]
    let onStartReading: (UUID) -> Void

    @Environment(ReadingQueuePlugin.self) private var queuePlugin

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    private var queuedBooks: [Book] {
        queuePlugin.queuedBooks(from: books)
    }

    private var availableBooks: [Book] {
        queuePlugin.availableBooks(from: books)
    }

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleQueueBody
#else
        openUIQueueBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleQueueBody: some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    editorialHeader

                    if let first = queuedBooks.first {
                        nextUpHeroCard(book: first)
                    } else {
                        emptyQueueCard
                    }

                    if !queuedBooks.isEmpty {
                        orderedQueueSection
                    }

                    if !availableBooks.isEmpty {
                        availableBooksSection
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 18)
                .frame(maxWidth: 780)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle("")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private var horizontalPadding: CGFloat {
#if os(macOS)
        return 28
#else
        return 18
#endif
    }

    private var editorialHeader: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "list.number")
                    .font(.caption2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("ESPACIO SERENO · PRÓXIMAS LECTURAS")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }

            Text("Cola de lectura")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)

            Text("Organiza con calma el orden de los libros que te esperan.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func nextUpHeroCard(book: Book) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                BookCoverView(title: book.title, author: book.author, width: 74, height: 106)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("PRÓXIMO EN LA COLA · #1")
                            .font(.caption2.weight(.bold))
                            .tracking(1.1)
                            .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                        Spacer()
                        Image(systemName: "bookmark.circle.fill")
                            .font(.subheadline)
                            .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                    }

                    Text(book.title.isEmpty ? "Sin título" : book.title)
                        .font(.system(.title3, design: .serif).bold())
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    if let author = book.author, !author.isEmpty {
                        Text(author)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Text(book.status.rawValue)
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                        .padding(.top, 2)
                }
            }

            HStack(spacing: 10) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        onStartReading(book.id)
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "book.open.fill")
                            .font(.subheadline)
                        Text("Empezar a leer ahora")
                            .font(.subheadline.weight(.semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 11)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.bookAccent)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        queuePlugin.remove(bookID: book.id)
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .frame(width: 44, height: 42)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.bookSageSurface(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
                .help("Quitar de la cola")
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 20, padding: 18)
    }

    private var emptyQueueCard: some View {
        VStack(spacing: 10) {
            Image(systemName: "list.bullet.rectangle.portrait")
                .font(.system(size: 36))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            Text("Tu cola de lectura está vacía")
                .font(.system(.headline, design: .serif))
            Text("Añade libros desde la lista inferior para decidir qué leerás a continuación.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 26)
    }

    private var orderedQueueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ORDEN DE LECTURA")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(.secondary)
                Spacer()
                Text("\(queuedBooks.count) \(queuedBooks.count == 1 ? "libro" : "libros")")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            VStack(spacing: 10) {
                ForEach(Array(queuedBooks.enumerated()), id: \.element.id) { index, book in
                    queueRowCard(book: book, position: index + 1, total: queuedBooks.count)
                }
            }
        }
    }

    private func queueRowCard(book: Book, position: Int, total: Int) -> some View {
        HStack(spacing: 12) {
            Text("#\(position)")
                .font(.system(.subheadline, design: .serif).bold())
                .foregroundColor(position == 1 ? .white : Color.bookSageForeground(for: colorScheme))
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(position == 1 ? Color.bookAccent : Color.bookSageSurface(for: colorScheme))
                )

            BookCoverView(title: book.title, author: book.author, width: 42, height: 60)

            VStack(alignment: .leading, spacing: 3) {
                Text(book.title.isEmpty ? "Sin título" : book.title)
                    .font(.system(.headline, design: .serif))
                    .lineLimit(1)
                if let author = book.author, !author.isEmpty {
                    Text(author)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        queuePlugin.moveUp(bookID: book.id)
                    }
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.caption.weight(.bold))
                        .foregroundColor(position == 1 ? .secondary.opacity(0.35) : Color.bookSageForeground(for: colorScheme))
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.bookBackground(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
                .disabled(position == 1)
                .help("Subir en la cola")

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        queuePlugin.moveDown(bookID: book.id)
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundColor(position == total ? .secondary.opacity(0.35) : Color.bookSageForeground(for: colorScheme))
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.bookBackground(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
                .disabled(position == total)
                .help("Bajar en la cola")

                Button {
                    withAnimation(.easeInOut(duration: 0.18)) {
                        queuePlugin.remove(bookID: book.id)
                    }
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 30, height: 30)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color.bookBackground(for: colorScheme))
                        )
                }
                .buttonStyle(.plain)
                .help("Quitar de la cola")
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 12)
    }

    private var availableBooksSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("AÑADIR A LA COLA")
                .font(.caption2.weight(.bold))
                .tracking(1.2)
                .foregroundColor(.secondary)

            VStack(spacing: 10) {
                ForEach(availableBooks) { book in
                    HStack(spacing: 12) {
                        BookCoverView(title: book.title, author: book.author, width: 38, height: 54)

                        VStack(alignment: .leading, spacing: 3) {
                            Text(book.title.isEmpty ? "Sin título" : book.title)
                                .font(.system(.subheadline, design: .serif).bold())
                                .lineLimit(1)
                            HStack(spacing: 6) {
                                if let author = book.author, !author.isEmpty {
                                    Text(author)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineLimit(1)
                                }
                                Text("· \(book.status.rawValue)")
                                    .font(.caption2)
                                    .foregroundColor(book.status.color)
                            }
                        }

                        Spacer(minLength: 4)

                        Button {
                            withAnimation(.easeInOut(duration: 0.18)) {
                                queuePlugin.enqueue(book.id)
                            }
                        } label: {
                            Label("Añadir", systemImage: "plus")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(Color.bookSageForeground(for: colorScheme))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(Color.bookSageSurface(for: colorScheme))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .biblioCard(scheme: colorScheme, cornerRadius: 14, padding: 12)
                }
            }
        }
    }
#endif

    private var openUIQueueBody: some View {
        List {
            Section(header: Text("Orden de lectura")) {
                if queuedBooks.isEmpty {
                    Text("No hay libros en la cola de lectura.")
                        .bookCaption()
                } else {
                    ForEach(Array(queuedBooks.enumerated()), id: \.element.id) { index, book in
                        HStack(spacing: 8) {
                            Text("\(index + 1). \(book.title)")
                                .font(.headline)
                            Spacer()
                            if index == 0 {
                                Button("Empezar") {
                                    onStartReading(book.id)
                                }
                            }
                            if index > 0 {
                                Button("Subir") {
                                    queuePlugin.moveUp(bookID: book.id)
                                }
                            }
                            if index < queuedBooks.count - 1 {
                                Button("Bajar") {
                                    queuePlugin.moveDown(bookID: book.id)
                                }
                            }
                            Button("Quitar") {
                                queuePlugin.remove(bookID: book.id)
                            }
                        }
                    }
                }
            }

            if !availableBooks.isEmpty {
                Section(header: Text("Añadir a la cola")) {
                    ForEach(availableBooks) { book in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(book.title)
                                Text(book.status.rawValue)
                                    .bookCaption(color: book.status.color)
                            }
                            Spacer()
                            Button("Añadir") {
                                queuePlugin.enqueue(book.id)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Cola de lectura")
    }
}
#endif
