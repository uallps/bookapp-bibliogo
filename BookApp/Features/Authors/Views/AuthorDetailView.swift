#if Autores
import SwiftUI

/// O5 Autores: la ficha de un autor. Se edita su nacionalidad, su año de nacimiento y sus
/// notas, se ven sus libros y se puede filtrar la biblioteca por él.
/// Recibe el plugin y la clave del autor, y lo vuelve a buscar en cada dibujo: así se ve
/// al momento lo que cambie (un libro nuevo, una valoración...).
struct AuthorDetailView: View {
    let plugin: AuthorPlugin
    let authorKey: String

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    private let goneText = "Este autor ya no tiene libros en la biblioteca."
    private let filterOnText = "Filtro activo: en la Biblioteca solo se ven sus libros."

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleBody
#else
        openUIBody
#endif
    }

    private var isFiltering: Bool {
        plugin.filterAuthor == authorKey
    }

#if !canImport(SwiftOpenUI)
    // MARK: - Apple

    @ViewBuilder
    private var appleBody: some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if let author = plugin.author(key: authorKey) {
                        appleHeader(author)
                        appleProfileCard(author)
                        appleBooksCard(author)
                    } else {
                        Text(verbatim: goneText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 16)
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 18)
                .frame(maxWidth: 740)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(plugin.author(key: authorKey)?.name ?? "Autor")
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

    private func appleHeader(_ author: AuthorSummary) -> some View {
        HStack(alignment: .center, spacing: 16) {
            AuthorInitialsView(name: author.name, size: 64)
            VStack(alignment: .leading, spacing: 6) {
                Text("FICHA DE AUTOR")
                    .font(.caption2.weight(.bold))
                    .tracking(1.2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text(verbatim: author.name)
                    .font(.system(.title2, design: .serif).bold())
                Text(verbatim: author.infoText)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer(minLength: 0)
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 20, padding: 18)
    }

    private func appleProfileCard(_ author: AuthorSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Ficha", systemImage: AuthorProfile.systemImage)
                .font(.caption.weight(.bold))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            appleField("Nacionalidad", prompt: "Por ejemplo, española", text: plugin.nationalityBinding(for: author))
            appleField("Año de nacimiento", prompt: "Por ejemplo, 1920", text: plugin.birthYearBinding(for: author))
            appleField("Notas", prompt: "Lo que quieras recordar de este autor", text: plugin.notesBinding(for: author))
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }

    private func appleField(_ title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            TextField(prompt, text: text)
                .textFieldStyle(.plain)
                .font(.subheadline)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.bookBackground(for: colorScheme))
                )
        }
    }

    private func appleBooksCard(_ author: AuthorSummary) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Sus libros", systemImage: "books.vertical")
                    .font(.caption.weight(.bold))
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Spacer()
                Text(verbatim: author.booksText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            ForEach(author.books) { book in
                HStack(spacing: 12) {
                    BookCoverView(title: book.title, author: book.author, width: 34, height: 48)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: book.title.isEmpty ? "Sin título" : book.title)
                            .font(.system(.subheadline, design: .serif).weight(.semibold))
                            .lineLimit(1)
                        Label(book.status.rawValue, systemImage: book.status.systemImage)
                            .font(.caption)
                            .foregroundColor(book.status.color)
                    }
                    Spacer(minLength: 0)
                }
            }

            Button {
                withAnimation(.easeInOut(duration: 0.16)) {
                    if isFiltering { plugin.clearFilter() } else { plugin.showInLibrary(author) }
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: isFiltering ? "xmark.circle" : "line.3.horizontal.decrease.circle")
                    Text(isFiltering ? "Quitar el filtro de la biblioteca" : "Ver sus libros en la biblioteca")
                        .font(.subheadline.weight(.semibold))
                }
                .foregroundColor(isFiltering ? Color.bookSageForeground(for: colorScheme) : .white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 11)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isFiltering ? Color.bookSageSurface(for: colorScheme) : Color.bookAccent)
                )
            }
            .buttonStyle(.plain)

            if isFiltering {
                Text(verbatim: filterOnText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }
#endif

    // MARK: - Linux y Windows

    @ViewBuilder
    private var openUIBody: some View {
        if let author = plugin.author(key: authorKey) {
            Form {
                Section(header: Text("Ficha")) {
                    Text(author.name)
                        .font(.headline)
                    Text(author.infoText)
                        .bookCaption()
                    TextField("Nacionalidad", text: plugin.nationalityBinding(for: author))
                    TextField("Año de nacimiento", text: plugin.birthYearBinding(for: author))
                    TextField("Notas", text: plugin.notesBinding(for: author))
                }
                Section(header: Text("Sus libros")) {
                    ForEach(author.books) { book in
                        HStack(spacing: 8) {
                            Text(book.title)
                            Text(book.status.rawValue)
                                .bookCaption(color: book.status.color)
                        }
                    }
                    if isFiltering {
                        Text(filterOnText)
                            .bookCaption()
                        Button("Quitar el filtro de la biblioteca") {
                            plugin.clearFilter()
                        }
                    } else {
                        Button("Ver sus libros en la biblioteca") {
                            plugin.showInLibrary(author)
                        }
                    }
                }
            }
            .navigationTitle(author.name)
        } else {
            Text(goneText)
                .bookCaption()
        }
    }
}
#endif
