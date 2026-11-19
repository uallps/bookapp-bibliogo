import Foundation
import Observation

/// Feature flags en ejecución: qué características muestra la app.
/// Es configuración de la aplicación, no datos de los libros. Cada flag se guarda en
/// UserDefaults al cambiar, así que se conserva al cerrar y volver a abrir la app.
@Observable
final class AppConfig {
    /// El autor es un atributo opcional del Core: este flag solo decide si se ve en la lista.
    var showAuthors: Bool {
        didSet { store(showAuthors, forKey: "showAuthors") }
    }
    /// F1 Progreso. El ajuste solo aparece en el producto compilado con el trait Progreso.
    var showProgress: Bool {
        didSet { store(showProgress, forKey: "showProgress") }
    }
    /// F4 Valoraciones: decide si se ve la valoración media en la lista.
    var showRatings: Bool {
        didSet { store(showRatings, forKey: "showRatings") }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        showAuthors = defaults.object(forKey: "showAuthors") as? Bool ?? true
        showProgress = defaults.object(forKey: "showProgress") as? Bool ?? true
        showRatings = defaults.object(forKey: "showRatings") as? Bool ?? true
    }

    private func store(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
        // En Linux y Windows, UserDefaults escribe en disco más tarde: lo forzamos ya.
        defaults.synchronize()
    }
}
