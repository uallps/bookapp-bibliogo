# BookApp (BiblioGo)

Práctica de la asignatura Líneas de Productos Software (UAL), curso 2026-27.
Sigue la misma estructura que el ejemplo del profesor, [TaskApp 2026](https://github.com/uallps/TaskApp-2026),
y está al nivel de su etiqueta `sesion-6`.

El mismo código de la carpeta `BookApp/` funciona en los tres sistemas:

| Sistema | Cómo se ejecuta | Interfaz |
|---|---|---|
| macOS | Abrir `BookApp.xcodeproj` en Xcode y pulsar ▶ | SwiftUI de Apple |
| Linux | `swift run BookApp` (necesita `libgtk-4-dev` y `libfontconfig-dev`) | [SwiftOpenUI](https://github.com/uallps/SwiftOpenUI) con GTK 4 |
| Windows | `swift run BookApp` | SwiftOpenUI con Win32 |

En Linux y Windows, `Package.swift` añade un módulo llamado `SwiftUI` (carpeta `Compat/`)
que reexporta SwiftOpenUI, así que `import SwiftUI` funciona sin cambiar el código.

## Productos

| Producto | Xcode (Mac) | Linux y Windows |
|---|---|---|
| Base | scheme `BookApp` | `swift run BookApp` |
| Con progreso (F1) | scheme `BookApp Progreso` (target con `Progreso` en *Active Compilation Conditions*) | `swift run --traits Progreso BookApp` |

## Qué hay de cada sesión

| Sesión | En TaskApp | En BookApp |
|---|---|---|
| 3 | Model, View y ViewModel con `@Observable` | `Book`, `ReadingStatus`, `BookListViewModel` y `BookListView`. Diagrama y memoria en [`docs/`](docs/SESION-03.md) |
| 4 | Feature flags en ejecución (`AppConfig`) y en compilación (`#if Prioridades`) | `AppConfig` con `showAuthors` y `showProgress`; F1 se compila con `#if Progreso` |
| 5 | Navegación a la vista de detalle | `BookDetailView`: título, autor, estado y, con F1, páginas totales y página actual |
| 6 | Persistencia, ajustes compartidos y tema | `StorageProvider` con JSON (`books.json` y `progress.json`) y Mock; ajustes en UserDefaults; `Theme.swift` |

## Diferencias con TaskApp

- **F1 Progreso va aparte de `Book`.** El enunciado de la sesión 3 pide no acoplar el progreso al libro. Por eso `ReadingProgress` se enlaza por `bookID`, el ViewModel guarda una lista aparte y se persiste en `progress.json`.
- **El botón de la fila avanza el estado** (Pendiente → Leyendo → Terminado → Pendiente), en lugar de marcar o desmarcar una tarea.
- **La prueba de Linux de la CI es solo de arranque.** La de TaskApp pulsa por coordenadas de pantalla, que dependen del diseño de cada app. La prueba con clics de BookApp está en Windows, donde los controles se buscan por su texto.
