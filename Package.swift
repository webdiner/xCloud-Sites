// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "xCloudSites",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "xCloudSites",
            path: "Sources/xCloudSites"
        )
    ]
)
