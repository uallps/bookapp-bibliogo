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
    // F1–F5 forman parte de todos los productos; las originales O1–O10 son opcionales.
    // En Xcode, el target «BookApp Completa» activa todas las originales.
    traits: [
        .trait(name: "Sugerencia",   description: "O1: sugerencia de próxima lectura"),
        .trait(name: "Logros",       description: "O2: logros e insignias"),
        .trait(name: "Importacion",  description: "O3: importación de libros desde CSV"),
        .trait(name: "ResumenAnual", description: "O4: resumen del año lector"),
        .trait(name: "Autores",      description: "O5: fichas de autor y filtro por autor"),
        .trait(name: "Sagas",        description: "O6: sagas y series"),
        .trait(name: "Portadas",     description: "O7: foto de la portada"),
        .trait(name: "ColaLectura",  description: "O8: cola de lectura"),
        .trait(name: "Exportacion",  description: "O9: exportación a CSV y Markdown"),
        .trait(name: "Gastos",       description: "O10: gasto en libros"),
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
