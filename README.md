# BookApp (BiblioGo)

Práctica en grupo de **Líneas de Productos Software** (UAL, curso 2026-27): una familia de aplicaciones de seguimiento de lectura que comparten un mismo núcleo y se diferencian en sus características opcionales.

Sigue la estructura del ejemplo del profesor, [TaskApp 2026](https://github.com/uallps/TaskApp-2026): MVVM con `@Observable`, feature flags, traits de compilación y plugins.

## Cómo se ejecuta

El mismo código de la carpeta `BookApp/` funciona en los tres sistemas:

| Sistema | Cómo se ejecuta | Interfaz |
|---|---|---|
| macOS | Abrir `BookApp.xcodeproj` en Xcode, elegir el scheme y pulsar ▶ | SwiftUI de Apple |
| Linux | `swift run BookApp` (necesita `libgtk-4-dev` y `libfontconfig-dev`) | [SwiftOpenUI](https://github.com/uallps/SwiftOpenUI) con GTK 4 |
| Windows | `swift run BookApp` (Swift **6.3.3**, modo desarrollador activado y `git config --global core.symlinks true`) | SwiftOpenUI con Win32 |

## Productos

| Producto | Xcode (Mac) | Linux y Windows |
|---|---|---|
| Base: Core y F1–F5 | scheme `BookApp` | `swift run BookApp` |
| Completo: además, todas las originales | scheme `BookApp Completa` | `swift run --traits Sugerencia,OpenLibrary,ObjetivoAnual,Prestamos,Exportacion BookApp` |
| Base y una original concreta | (añadir su condición al target) | `swift run --traits Prestamos BookApp` |

## Características

| | Característica | Cómo varía |
|---|---|---|
| Core | Biblioteca: libros con título, autor y estado; alta, edición, cambio de estado, borrado y persistencia en JSON | Siempre |
| F1–F5 | Progreso, Notas y citas, Categorías, Valoraciones y Estadísticas | Siempre compiladas; se muestran u ocultan en Ajustes |
| O1 | Sugerencia de próxima lectura (XOR: aleatoria / por tiempo y extensión) | Trait `Sugerencia` |
| O2 | Búsqueda en Open Library | Trait `OpenLibrary` |
| O3 | Objetivo anual | Trait `ObjetivoAnual` |
| O4 | Préstamo de libros | Trait `Prestamos` |
| O5 | Exportación (OR: CSV / Markdown) | Trait `Exportacion` |

El diagrama de características y la memoria de la sesión 3 están en [`docs/`](docs/SESION-03.md).

## Estructura

```
BookApp/
├── Application/       BookApp (@main), AppConfig (feature flags), Theme
├── Core/              Models (Book, ReadingStatus), ViewModels, Views
├── Features/          Una carpeta por característica (Progress, Notes, Categories...)
└── Infrastructure/    Persistence (StorageProvider, JSON, Mock) y Plugins (registro y protocolos)
```

## Flujo de trabajo

- `main`: solo las entregas finales.
- `develop`: integración; aquí llegan las PR.
- `feature/<código>-<nombre>`: una rama por característica, a partir de `develop`.

Cada PR se compila en la CI en macOS, Linux y Windows, con el producto base y con todas las originales.
