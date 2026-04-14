// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PenroseTiling",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PenroseTiling",
            path: "Sources/PenroseTiling",
            resources: [
                .copy("verts_5Dprojection.txt"),
                .copy("indices_5Dprojection.txt"),
                .copy("faces_5Dprojection.txt"),
            ]
        )
    ]
)
