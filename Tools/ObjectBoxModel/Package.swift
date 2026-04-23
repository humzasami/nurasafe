// swift-tools-version: 5.9
// Mini-package used only to run ObjectBox code generator for NuraSafe.
// From repo root: cd Tools/ObjectBoxModel && swift package plugin --allow-writing-to-package-directory objectbox-generator --target ObjectBoxModel --no-statistics

import PackageDescription

let package = Package(
    name: "ObjectBoxModel",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "ObjectBoxModel", targets: ["ObjectBoxModel"])
    ],
    dependencies: [
        .package(url: "https://github.com/objectbox/objectbox-swift-spm.git", from: "5.2.0")
    ],
    targets: [
        .target(
            name: "ObjectBoxModel",
            dependencies: [
                .product(name: "ObjectBox.xcframework", package: "objectbox-swift-spm")
            ],
            path: "Sources",
            plugins: [
                .plugin(name: "ObjectBoxPlugin", package: "objectbox-swift-spm")
            ]
        )
    ]
)
