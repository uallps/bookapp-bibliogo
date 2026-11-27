#if Autores
import SwiftUI

/// O5 Autores: pantalla propia del plugin, en la barra lateral. Lista los autores de la
/// biblioteca con su número de libros y su valoración media; al entrar en uno se edita su
/// ficha. Recibe el plugin (no lo busca en el entorno).
struct AuthorsView: View {
    let plugin: AuthorPlugin

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    private let emptyText = "Aún no hay autores. Escribe el autor de un libro en su detalle y aparecerá aquí."

    var body: some View {
        let authors = plugin.authors
#if !canImport(SwiftOpenUI)
        return appleBody(authors: authors)
#else
        return openUIBody(authors: authors)
#endif
    }

#if !canImport(SwiftOpenUI)
    // MARK: - Apple

    private func appleBody(authors: [AuthorSummary]) -> some View {
        ZStack {
            Color.bookBackground(for: colorScheme)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    appleHeader(count: authors.count)

                    if authors.isEmpty {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "person.crop.circle.badge.questionmark")
                                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                            Text(verbatim: emptyText)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Spacer(minLength: 0)
                        }
                        .biblioCard(scheme: colorScheme, cornerRadius: 16, padding: 16)
                    } else {
                        let columns: [GridItem] = {
#if os(macOS)
                            return [GridItem(.adaptive(minimum: 300), spacing: 12)]
#else
                            return [GridItem(.flexible(), spacing: 12)]
#endif
                        }()
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(authors) { author in
                                NavigationLink(destination: AuthorDetailView(plugin: plugin, authorKey: author.key)) {
                                    appleAuthorCard(author)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 18)
                .frame(maxWidth: 840)
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

    private func appleHeader(count: Int) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "person.2.fill")
                    .font(.caption2)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
                Text("ESPACIO SERENO · AUTORES")
                    .font(.caption2.weight(.bold))
                    .tracking(1.3)
                    .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))
            }
            Text("Tus autores")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .foregroundColor(.primary)
            Text(verbatim: count == 1 ? "1 autor en tu biblioteca." : String(count) + " autores en tu biblioteca.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }

    private func appleAuthorCard(_ author: AuthorSummary) -> some View {
        let profile = plugin.profile(forKey: author.key)
        return HStack(spacing: 14) {
            AuthorInitialsView(name: author.name, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: author.name)
                    .font(.system(.headline, design: .serif))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                if let summary = profile?.summaryText, !summary.isEmpty {
                    Text(verbatim: summary)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                HStack(spacing: 6) {
                    Text(verbatim: author.booksText)
                        .font(.caption2.weight(.bold))
                        .foregroundColor(Color.bookSageForeground(for: colorScheme))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookSageSurface(for: colorScheme)))
                    if let rating = author.ratingText {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill")
                                .font(.system(size: 9))
                            Text(verbatim: rating)
                                .font(.caption2.weight(.bold))
                        }
                        .foregroundColor(.bookStar)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.bookStarSurface(for: colorScheme)))
                    }
                }
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
        }
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 14)
        .contentShape(Rectangle())
    }
#endif

    // MARK: - Linux y Windows

    private func openUIBody(authors: [AuthorSummary]) -> some View {
        List {
            if authors.isEmpty {
                Text(emptyText)
                    .bookCaption()
            }
            ForEach(authors) { author in
                NavigationLink(destination: AuthorDetailView(plugin: plugin, authorKey: author.key)) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(author.name)
                        Text(author.infoText)
                            .bookCaption()
                    }
                }
            }
        }
        .navigationTitle("Autores")
    }
}
#endif
