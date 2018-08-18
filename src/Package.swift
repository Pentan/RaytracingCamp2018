// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Fluttershy",
    products: [
        .executable(name: "Fluttershy", targets: ["Fluttershy"]),
        .library(name: "FlutterCore", targets: ["FlutterCore"]),
        //.library(name: "LinearAlgebra", targets: ["LinearAlgebra"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "Fluttershy",
            dependencies: ["FlutterCore", "LinearAlgebra"]),
        .target(
            name: "FlutterCore",
            dependencies: ["LinearAlgebra"]),
        .target(
            name: "LinearAlgebra",
            dependencies: []),
        
        .testTarget(
            name: "FlutterCoreTests",
            dependencies: ["FlutterCore", "LinearAlgebra"]),
    ]
)
