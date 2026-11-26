// swift-tools-version: 6.2
// Paquete para Linux y Windows. Compila la MISMA carpeta BookApp/ que usa Xcode
// (en Mac se abre BookApp.xcodeproj y se usa el SwiftUI de Apple).
import PackageDescription

#if os(Linux)
let backend: Target.Dependency = .product(name: "BackendGTK4", package: "SwiftOpenUI")
#elseif os(Windows)
let backend: Target.Dependency = .product(name: "BackendWin32", package: "SwiftOpenUI")
#else
let backend: Target.Dependency? = nil
#endif

let package = Package(
    name: "BookApp",
    // Productos de la línea: cada trait activo es una variable de compilación (#if Prestamos...).
    // F1–F5 forman parte de todos los productos; las originales O1–O5 son opcionales.
    // En Xcode, el target «BookApp Completa» activa todas las originales.
    traits: [
        .trait(name: "Sugerencia",    description: "O1: sugerencia de próxima lectura"),
        .trait(name: "OpenLibrary",   description: "O2: búsqueda en Open Library"),
        .trait(name: "ObjetivoAnual", description: "O3: objetivo anual de lectura"),
        .trait(name: "Prestamos",     description: "O4: préstamo de libros"),
        .trait(name: "Exportacion",   description: "O5: exportación a CSV y Markdown"),
    ],
    dependencies: [
        .package(url: "https://github.com/uallps/SwiftOpenUI.git", branch: "uallps"),
    ],
    targets: [
        // Sustituye al SwiftUI de Apple: `import SwiftUI` trae SwiftOpenUI y su backend.
        .target(
            name: "SwiftUI",
            dependencies: [.product(name: "SwiftOpenUI", package: "SwiftOpenUI")] + [backend].compactMap { $0 },
            path: "Compat/SwiftUI"
        ),
        // Mismos ajustes de Swift que el proyecto de Xcode.
        .executableTarget(
            name: "BookApp",
            dependencies: ["SwiftUI"],
            path: "BookApp",
            exclude: ["Assets.xcassets"],
            swiftSettings: [
                .swiftLanguageMode(.v5),
                .defaultIsolation(MainActor.self),
                .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
                .enableUpcomingFeature("InferIsolatedConformances"),
                .enableUpcomingFeature("MemberImportVisibility"),
            ]
        ),
    ]
)
