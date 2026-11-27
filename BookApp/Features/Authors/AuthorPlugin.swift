#if Autores
import SwiftUI
import Observation

/// Plugin de O5 Autores (trait `Autores`).
/// - Guarda una ficha por autor (nacionalidad, año de nacimiento y notas) en su propio
///   fichero, authors.json. Se enlaza con los libros por el nombre normalizado del campo
///   `author` del núcleo: `Book` no cambia.
/// - Como plugin de vista, aporta su pantalla «Autores», el filtro por autor encima de la
///   biblioteca, la sección «Sobre el autor» del detalle y su ajuste.
/// Si se borra el último libro de un autor, su ficha se conserva: si vuelve a aparecer
/// un libro suyo, la ficha sigue ahí.
@Observable
final class AuthorPlugin: ViewPlugin {
    let name = "Autores"

    /// Las fichas de autor. Cada cambio se guarda.
    private(set) var data = AuthorData.sample {
        didSet { save() }
    }

    /// Autor elegido en el filtro de la biblioteca (su clave normalizada), o nil.
    /// Es estado de la pantalla: no se guarda.
    var filterAuthor: String?

    /// El ajuste «Mostrar fichas de autor». Es del plugin, no de AppConfig: así el plugin
    /// se añade sin tocar el núcleo.
    var showProfiles: Bool {
        didSet {
            defaults.set(showProfiles, forKey: Self.showProfilesKey)
            // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
            defaults.synchronize()
        }
    }

    @ObservationIgnored private let config: AppConfig
    @ObservationIgnored private let library: BookListViewModel
    @ObservationIgnored private let storageProvider: AuthorStorageProvider
    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var loaded = false

    private static let showProfilesKey = "showAuthorProfiles"

    init(config: AppConfig,
         library: BookListViewModel,
         storageProvider: AuthorStorageProvider = JSONAuthorStorageProvider(),
         defaults: UserDefaults = .standard) {
        self.config = config
        self.library = library
        self.storageProvider = storageProvider
        self.defaults = defaults
        showProfiles = defaults.object(forKey: Self.showProfilesKey) as? Bool ?? true
        Task { await loadAuthors() }
    }

    /// Carga las fichas guardadas, solo la primera vez. Si aún no hay fichero, no hay ninguna.
    func loadAuthors() async {
        guard !loaded else { return }
        loaded = true
        do {
            data = try await storageProvider.loadAuthors()
        } catch {
            print("No se han cargado los autores: \(error)")
        }
    }

    // MARK: - Datos

    /// Los autores de la biblioteca: los nombres distintos de los libros, en orden alfabético.
    var authors: [AuthorSummary] {
        AuthorSummary.authors(in: library.books, profiles: data) { [library] id in
            library.averageRating(for: id)
        }
    }

    /// Un autor de la biblioteca a partir de su clave, si aún tiene libros.
    func author(key: String) -> AuthorSummary? {
        authors.first { $0.key == key }
    }

    /// La ficha de un autor, si tiene.
    func profile(forKey key: String) -> AuthorProfile? {
        data.profile(forKey: key)
    }

    /// La ficha del autor de un libro, si tiene.
    func profile(for book: Book) -> AuthorProfile? {
        let key = AuthorProfile.key(for: book.author ?? "")
        guard !key.isEmpty else { return nil }
        return profile(forKey: key)
    }

    /// Cambia la ficha de un autor; si aún no tenía, la crea.
    func updateProfile(of author: AuthorSummary, _ change: (inout AuthorProfile) -> Void) {
        var updated = data
        if let index = updated.profiles.firstIndex(where: { $0.key == author.key }) {
            change(&updated.profiles[index])
        } else {
            var profile = AuthorProfile(name: author.name)
            change(&profile)
            updated.profiles.append(profile)
        }
        data = updated // un solo cambio: se guarda una vez
    }

    /// Enlace a la nacionalidad, para un TextField (vacío = sin nacionalidad).
    func nationalityBinding(for author: AuthorSummary) -> Binding<String> {
        Binding(
            get: { self.profile(forKey: author.key)?.nationality ?? "" },
            set: { text in
                let value = text.trimmingCharacters(in: .whitespacesAndNewlines)
                self.updateProfile(of: author) { $0.nationality = value.isEmpty ? nil : text }
            }
        )
    }

    /// Enlace al año de nacimiento, para un TextField: solo se quedan las cifras.
    func birthYearBinding(for author: AuthorSummary) -> Binding<String> {
        Binding(
            get: { self.profile(forKey: author.key)?.birthYear.map { String($0) } ?? "" },
            set: { text in
                let digits = String(text.filter(\.isNumber).prefix(4))
                self.updateProfile(of: author) { $0.birthYear = Int(digits) }
            }
        )
    }

    /// Enlace a las notas, para un TextField.
    func notesBinding(for author: AuthorSummary) -> Binding<String> {
        Binding(
            get: { self.profile(forKey: author.key)?.notes ?? "" },
            set: { text in self.updateProfile(of: author) { $0.notes = text } }
        )
    }

    // MARK: - Filtro por autor

    /// El autor del filtro, si hay filtro y ese autor sigue teniendo libros.
    /// Si ya no tiene (se han borrado o cambiado), el filtro no se aplica: mejor ver
    /// todos los libros que una lista vacía sin explicación.
    var activeFilter: AuthorSummary? {
        guard let filterAuthor else { return nil }
        return author(key: filterAuthor)
    }

    /// Activa el filtro de la biblioteca con los libros de ese autor.
    func showInLibrary(_ author: AuthorSummary) {
        filterAuthor = author.key
    }

    func clearFilter() {
        filterAuthor = nil
    }

    // MARK: - ViewPlugin: las vistas que el plugin aporta

    /// Con los autores ocultos (ajuste del núcleo) no se filtra ni se muestra nada.
    var isEnabled: Bool { config.showAuthors && showProfiles }

    /// En la fila no se añade nada: el autor ya se ve.
    func bookRowView(for book: Book) -> EmptyView { EmptyView() }

    /// En el detalle, «Sobre el autor», si su autor tiene ficha con algún dato.
    @ViewBuilder
    func bookDetailView(for book: Book) -> some View {
        if let profile = profile(for: book), profile.hasInfo {
            AboutAuthorSection(profile: profile)
        }
    }

    /// En Ajustes, «Mostrar fichas de autor».
    func settingsView() -> some View {
        FeatureToggle(
            title: "Mostrar fichas de autor",
            subtitle: "Ficha de cada autor y filtro de la biblioteca por autor",
            systemImage: AuthorProfile.systemImage,
            isOn: Binding(
                get: { self.showProfiles },
                set: { self.showProfiles = $0 }
            )
        )
    }

    /// Encima de la biblioteca: en Linux y Windows, solo si hay un filtro activo (una fila
    /// «Autor: X» para quitarlo); en Mac, además, un menú para elegir autor.
    @ViewBuilder
    func libraryView() -> some View {
#if !canImport(SwiftOpenUI)
        if !authors.isEmpty {
            AuthorFilterView(
                activeName: activeFilter?.name,
                authors: authors,
                onSelect: { self.showInLibrary($0) },
                onClear: { self.clearFilter() }
            )
        }
#else
        if let active = activeFilter {
            AuthorFilterView(
                activeName: active.name,
                authors: [],
                onSelect: { self.showInLibrary($0) },
                onClear: { self.clearFilter() }
            )
        }
#endif
    }

    /// Los libros del autor del filtro.
    func filterBooks(_ books: [Book]) -> [Book] {
        guard let key = activeFilter?.key else { return books }
        return books.filter { AuthorProfile.key(for: $0.author ?? "") == key }
    }

    var screenTitle: String? { "Autores" }
    var screenSystemImage: String { "person.2" }

    /// Su pantalla: la lista de autores.
    func screenView() -> some View {
        AuthorsView(plugin: self)
    }

    private func save() {
        let data = data
        Task {
            do {
                try await storageProvider.saveAuthors(data)
            } catch {
                print("No se han guardado los autores: \(error)")
            }
        }
    }
}
#endif
