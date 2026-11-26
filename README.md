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
| Completo: además, todas las originales | scheme `BookApp Completa` | `swift run --traits Sugerencia,Logros,Importacion,ResumenAnual,Autores,Sagas,Portadas,ColaLectura,Exportacion,Gastos BookApp` |
| Base y una original concreta | (añadir su condición al target) | `swift run --traits Sagas BookApp` |

## Características

| | Característica | Cómo varía | Responsable |
|---|---|---|---|
| Core | Biblioteca: libros con título, autor y estado; alta, edición, cambio de estado, borrado y persistencia en JSON | Siempre | |
| F1 | Progreso de lectura | Siempre compilada; se muestra u oculta en Ajustes | Hugo |
| F2 | Notas y citas | Ídem | Sergio |
| F3 | Categorías | Ídem | Arturo |
| F4 | Valoraciones | Ídem | Javier |
| F5 | Estadísticas | Ídem | Iván |
| O1 | Sugerencia de próxima lectura (XOR: aleatoria / por tiempo y extensión) | Trait `Sugerencia` | Sergio |
| O2 | Logros e insignias: solo aparecen los de las características incluidas en el producto | Trait `Logros` | Sergio |
| O3 | Importación de libros desde CSV, con el mismo formato que la exportación | Trait `Importacion` | Hugo |
| O4 | Resumen anual: libros terminados, páginas y lo más destacado de un año | Trait `ResumenAnual` | Hugo |
| O5 | Autores: ficha de cada autor y filtro por autor | Trait `Autores` | Arturo |
| O6 | Sagas y series: libros agrupados en orden y cuál toca leer después | Trait `Sagas` | Arturo |
| O7 | Foto de la portada | Trait `Portadas` | Javier |
| O8 | Cola de lectura: orden de los próximos libros | Trait `ColaLectura` | Javier |
| O9 | Exportación (OR: CSV / Markdown) | Trait `Exportacion` | Iván |
| O10 | Gasto en libros: precio de cada libro y gasto por año | Trait `Gastos` | Iván |

Algunas originales se aprovechan de otras cuando están en el mismo producto: la sugerencia propone el primer libro de la cola de lectura, el resumen anual incluye el gasto del año y las sagas terminadas, y la importación lee lo que genera la exportación.

El diagrama de características de la sesión 3, con la primera versión de las originales, está en [`docs/`](docs/SESION-03.md).

## Dos interfaces

En Mac la app usa la interfaz de BiblioGo (vistas `apple…Body`, bajo `#if !canImport(SwiftOpenUI)`); en Linux y Windows, una versión más sencilla (vistas `openUI…Body`). Cada característica tiene que integrarse en las dos. La CI prueba con clics la de Windows; la de Mac hay que revisarla a mano.

## Estructura

```
BookApp/
├── Application/       BookApp (@main), AppConfig (feature flags), Theme
├── Core/              Models (Book, ReadingStatus), ViewModels, Views
├── Features/          Una carpeta por característica (Progress, Notes, Categories...)
└── Infrastructure/    Persistence (StorageProvider, JSON, Mock) y Plugins (registro y protocolos)
```

## Plugins

Cada característica original es un plugin en su carpeta de `Features/`. El núcleo no nombra ningún plugin: los pide al registro (`PluginRegistry.shared`) y muestra lo que le devuelve. El único sitio donde aparece cada plugin es su registro en `BookApp.swift`, dentro de su trait.

| Protocolo | Para qué | Métodos |
|---|---|---|
| `DataPlugin` | Mantener sus datos al día | `willDeleteBook`, `didDeleteBook`, `didChangeStatus` |
| `ViewPlugin` | Aportar vistas en puntos fijos | `bookRowView(for:)`, `bookDetailView(for:)`, `settingsView()`, `libraryView()`, `filterBooks(_:)`, `screenTitle` y `screenView()` |

Todos los métodos tienen una versión por defecto que no hace nada, así que cada plugin implementa solo lo que necesita. `isEnabled` decide si sus vistas se ven (normalmente, un ajuste); su ajuste se ve siempre. F3 Categorías es el ejemplo completo.

- Si el plugin necesita los libros o cambiarlos (por ejemplo, empezar a leer uno), recibe la biblioteca al crearse: `MiPlugin(config: config, library: viewModel)`.
- Los plugins ya no se ponen en el entorno con `.environment(...)`: sus vistas reciben el plugin o sus datos como parámetros.

## Flujo de trabajo

- `main`: solo las entregas finales.
- `develop`: integración; aquí llegan las PR.
- `feat-<usuario>`: la rama de cada miembro, a partir de `develop`. Cuando tiene sus dos características, PR a `develop`.
- `<usuario>/feat-<nombre>`: una rama por característica, a partir de la rama del miembro. Se fusiona en ella y se borra.

Cada PR se compila en la CI en macOS, Linux y Windows, con el producto base y con todas las originales.
