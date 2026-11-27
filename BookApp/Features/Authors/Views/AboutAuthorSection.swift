#if Autores
import SwiftUI

extension AuthorProfile {
    /// O5: icono de los autores (ajuste, detalle y filtro).
    static let systemImage = "person.text.rectangle"

    /// Por ejemplo, "Estadounidense · nacido en 1920" (sin separador de miles en el año).
    var summaryText: String {
        var parts: [String] = []
        if let nationality, !nationality.isEmpty { parts.append(nationality) }
        if let birthYear { parts.append("nacido en " + String(birthYear)) }
        return parts.joined(separator: " · ")
    }
}

/// O5 Autores en el detalle de un libro: «Sobre el autor», con su nacionalidad, su año
/// de nacimiento y sus notas. Recibe la ficha, no el plugin.
struct AboutAuthorSection: View {
    let profile: AuthorProfile

#if !canImport(SwiftOpenUI)
    @Environment(\.colorScheme) private var colorScheme
#endif

    var body: some View {
#if !canImport(SwiftOpenUI)
        appleBody
#else
        openUIBody
#endif
    }

#if !canImport(SwiftOpenUI)
    private var appleBody: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Sobre el autor", systemImage: AuthorProfile.systemImage)
                .font(.caption.weight(.bold))
                .foregroundColor(Color.bookAccentAdaptive(for: colorScheme))

            HStack(spacing: 12) {
                AuthorInitialsView(name: profile.name, size: 40)
                VStack(alignment: .leading, spacing: 2) {
                    Text(verbatim: profile.name)
                        .font(.system(.headline, design: .serif))
                    if !profile.summaryText.isEmpty {
                        Text(verbatim: profile.summaryText)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }

            if !profile.notes.isEmpty {
                Text(verbatim: profile.notes)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .biblioCard(scheme: colorScheme, cornerRadius: 18, padding: 18)
    }
#endif

    private var openUIBody: some View {
        Section(header: Text("Sobre el autor")) {
            Text(profile.name)
            if !profile.summaryText.isEmpty {
                Text(profile.summaryText)
                    .bookCaption()
            }
            if !profile.notes.isEmpty {
                Text(profile.notes)
                    .bookCaption()
            }
        }
    }
}

#if !canImport(SwiftOpenUI)
/// Círculo con las iniciales del autor (estilo BiblioGo).
struct AuthorInitialsView: View {
    let name: String
    var size: CGFloat = 44

    @Environment(\.colorScheme) private var colorScheme

    private var initials: String {
        let words = name.split(separator: " ")
        let letters = words.prefix(2).compactMap { $0.first }
        return String(letters).uppercased()
    }

    var body: some View {
        Text(verbatim: initials)
            .font(.system(size: size * 0.38, weight: .bold, design: .serif))
            .foregroundColor(Color.bookSageForeground(for: colorScheme))
            .frame(width: size, height: size)
            .background(Circle().fill(Color.bookSageSurface(for: colorScheme)))
    }
}
#endif
#endif
