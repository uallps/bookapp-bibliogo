import SwiftUI

// El tema de la app: colores, iconos, tipografía y componentes visuales en un solo sitio.
// Paleta editorial serena de BiblioGo (verde pino, salvia, crema cálido y dorado).

extension Color {
    /// Color principal de BiblioGo: verde pino / bosque sereno del prototipo.
    static let bookAccent = Color(red: 0.18, green: 0.35, blue: 0.26)
    /// Verde bosque profundo para contrastes y portadas.
    static let bookForestDark = Color(red: 0.12, green: 0.24, blue: 0.18)
    /// Verde salvia claro para etiquetas y píldoras del prototipo.
    static let bookSage = Color(red: 0.88, green: 0.93, blue: 0.89)
    /// Texto oscuro sobre salvia.
    static let bookSageDark = Color(red: 0.14, green: 0.28, blue: 0.20)
    /// Fondo cálido sereno de la aplicación (modo claro).
    static let bookCream = Color(red: 0.965, green: 0.969, blue: 0.953)
    /// Color dorado cálido para estrellas de valoración.
    static let bookStar = Color(red: 0.91, green: 0.63, blue: 0.15)
    /// Fondo suave dorado para píldoras de valoración.
    static let bookStarSoft = Color(red: 0.99, green: 0.95, blue: 0.88)

#if !canImport(SwiftOpenUI)
    /// Fondo general adaptable a modo claro y oscuro.
    static func bookBackground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.09, green: 0.11, blue: 0.10)
            : Color.bookCream
    }

    /// Fondo de tarjeta adaptable a modo claro y oscuro.
    static func bookCard(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.14, green: 0.17, blue: 0.15)
            : Color.white
    }

    /// Fondo de tarjeta secundaria / acento salvia adaptable.
    static func bookSageSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.17, green: 0.24, blue: 0.20)
            : Color.bookSage
    }

    /// Texto principal sobre salvia adaptable.
    static func bookSageForeground(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.78, green: 0.90, blue: 0.82)
            : Color.bookSageDark
    }

    /// Borde sutil de tarjeta adaptable.
    static func bookBorder(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color.white.opacity(0.08)
            : Color.black.opacity(0.06)
    }

    /// Fondo suave dorado adaptable para estrellas.
    static func bookStarSurface(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.28, green: 0.22, blue: 0.12)
            : Color.bookStarSoft
    }

    /// Acento principal adaptable (más luminoso en modo oscuro).
    static func bookAccentAdaptive(for scheme: ColorScheme) -> Color {
        scheme == .dark
            ? Color(red: 0.42, green: 0.68, blue: 0.52)
            : Color.bookAccent
    }
#endif
}

/// Estilo del texto secundario de las filas (autor, estado, progreso).
struct CaptionStyle: ViewModifier {
    var color: Color = .secondary

    func body(content: Content) -> some View {
        content
            .font(.caption)
            .foregroundColor(color)
    }
}

extension View {
    /// Aplica el estilo de texto secundario: `Text("…").bookCaption()`,
    /// o con otro color: `.bookCaption(color: .green)`.
    func bookCaption(color: Color = .secondary) -> some View {
        modifier(CaptionStyle(color: color))
    }

#if !canImport(SwiftOpenUI)
    /// Tarjeta editorial redondeada estilo BiblioGo.
    func biblioCard(scheme: ColorScheme, cornerRadius: CGFloat = 16, padding: CGFloat = 16) -> some View {
        self
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(Color.bookCard(for: scheme))
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(Color.bookBorder(for: scheme), lineWidth: 1)
            )
            .shadow(
                color: scheme == .dark ? Color.black.opacity(0.25) : Color.black.opacity(0.045),
                radius: 10, x: 0, y: 4
            )
    }
#endif
}

extension ReadingStatus {
    /// Icono del botón de la fila. Es aspecto, por eso está aquí y no en el modelo.
    var systemImage: String {
        switch self {
        case .pendiente: return "circle"
        case .leyendo: return "bookmark.fill"
        case .terminado: return "checkmark.circle.fill"
        }
    }

    /// Color del estado en la fila (paleta de BiblioGo).
    var color: Color {
        switch self {
        case .pendiente: return Color(red: 0.50, green: 0.55, blue: 0.52)
        case .leyendo: return Color.bookAccent
        case .terminado: return Color(red: 0.20, green: 0.52, blue: 0.34)
        }
    }
}

extension ReadingProgress {
    /// Color del progreso: verde al terminar.
    var color: Color {
        percentage >= 100 ? Color(red: 0.20, green: 0.52, blue: 0.34) : Color.bookAccent
    }
}

extension NoteKind {
    /// Icono que identifica visualmente el tipo de anotación.
    var systemImage: String {
        switch self {
        case .note:  return "note.text"
        case .quote: return "quote.opening"
        }
    }

    /// Color distintivo para notas y citas (paleta BiblioGo).
    var color: Color {
        switch self {
        case .note:  return Color.bookAccent
        case .quote: return Color(red: 0.48, green: 0.34, blue: 0.46)
        }
    }
}

#if !canImport(SwiftOpenUI)
/// Portada artesanal generada determinísticamente a partir del título del libro.
/// Aporta riqueza visual estilo editorial sin necesidad de imágenes externas.
struct BookCoverView: View {
    let title: String
    let author: String?
    var width: CGFloat = 54
    var height: CGFloat = 78

    private var palette: (top: Color, bottom: Color, ink: Color) {
        let palettes: [(Color, Color, Color)] = [
            // Salvia suave
            (Color(red: 0.85, green: 0.91, blue: 0.86), Color(red: 0.72, green: 0.82, blue: 0.75), Color(red: 0.14, green: 0.27, blue: 0.20)),
            // Arena / Pergamino cálido
            (Color(red: 0.94, green: 0.90, blue: 0.83), Color(red: 0.85, green: 0.78, blue: 0.68), Color(red: 0.33, green: 0.24, blue: 0.16)),
            // Azul pizarra sereno
            (Color(red: 0.84, green: 0.89, blue: 0.93), Color(red: 0.70, green: 0.78, blue: 0.85), Color(red: 0.16, green: 0.25, blue: 0.35)),
            // Terracota empolvada
            (Color(red: 0.93, green: 0.85, blue: 0.82), Color(red: 0.84, green: 0.71, blue: 0.66), Color(red: 0.38, green: 0.19, blue: 0.15)),
            // Lavanda literaria
            (Color(red: 0.89, green: 0.86, blue: 0.92), Color(red: 0.77, green: 0.72, blue: 0.83), Color(red: 0.27, green: 0.20, blue: 0.35)),
            // Bosque profundo
            (Color(red: 0.22, green: 0.39, blue: 0.30), Color(red: 0.14, green: 0.27, blue: 0.20), Color(red: 0.93, green: 0.95, blue: 0.92)),
        ]
        let hash = title.unicodeScalars.reduce(0) { ($0 &* 31) &+ Int($1.value) }
        return palettes[abs(hash) % palettes.count]
    }

    private var initials: String {
        let words = title.split(separator: " ").filter { !$0.isEmpty }
        if words.count >= 2 {
            return "\(words[0].prefix(1))\(words[1].prefix(1))".uppercased()
        }
        return String(title.prefix(2)).uppercased()
    }

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [palette.top, palette.bottom],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            // Lomo sutil en el borde izquierdo
            Rectangle()
                .fill(Color.black.opacity(0.08))
                .frame(width: max(4, width * 0.09))
                .padding(.leading, 4)

            VStack(spacing: 4) {
                Spacer(minLength: 4)
                Text(initials.isEmpty ? "B" : initials)
                    .font(.system(size: width * 0.32, weight: .semibold, design: .serif))
                    .foregroundColor(palette.ink)
                if width >= 70, let author, !author.isEmpty {
                    Text(author.split(separator: " ").last.map(String.init) ?? author)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(palette.ink.opacity(0.75))
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                }
                Spacer(minLength: 4)
                RoundedRectangle(cornerRadius: 1)
                    .fill(palette.ink.opacity(0.28))
                    .frame(width: width * 0.42, height: 1.5)
                    .padding(.bottom, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.leading, 4)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 0.75)
        )
        .shadow(color: Color.black.opacity(0.10), radius: 5, x: 0, y: 3)
    }
}

/// Barra de progreso minimalista y elegante estilo BiblioGo.
struct BiblioProgressBar: View {
    let progress: Double // 0.0 ... 1.0
    var color: Color = .bookAccent
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(color.opacity(0.16))
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(geo.size.width, geo.size.width * progress)))
            }
        }
        .frame(height: height)
    }
}
#endif
