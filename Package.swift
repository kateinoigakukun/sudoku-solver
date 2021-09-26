// swift-tools-version:5.4
import PackageDescription
let package = Package(
    name: "SudokuSolver",
    products: [
        .executable(name: "SudokuSolver", targets: ["SudokuSolver"])
    ],
    dependencies: [
        .package(name: "JavaScriptKit", url: "https://github.com/swiftwasm/JavaScriptKit", from: "0.10.1"),
        .package(name: "ChibiSAT", url: "https://github.com/kateinoigakukun/chibi-sat", .revision("13979f30824934078c606bf61012fe83cc52241e")),
        .package(name: "swift-algorithms", url: "https://github.com/apple/swift-algorithms", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "SudokuSolver",
            dependencies: [
                .product(name: "JavaScriptKit", package: "JavaScriptKit"),
                .target(name: "SudokuSolverKit"),
            ]),
        .target(name: "SudokuSolverKit", dependencies: [
            .product(name: "Algorithms", package: "swift-algorithms"),
            .product(name: "ChibiSAT", package: "ChibiSAT"),
        ]),
        .testTarget(
            name: "SudokuSolverTests",
            dependencies: ["SudokuSolverKit"]),
    ]
)
