// swift-tools-version: 5.9
//
// AstrologMac — Swift Package
//
// `AstrologKit` is the pure-Swift core: it builds type-safe `astrolog` CLI
// argument vectors and runs the binary as a subprocess. It has no UI and no
// platform-GUI dependencies, so it builds and tests anywhere a Swift toolchain
// is present (`swift build` / `swift test`) — including from CI or Linux.
//
// The SwiftUI `.app` shell is added separately on the Mac (Xcode app target or
// an XcodeGen spec) and depends on this library. See ../HANDOFF.md.

import PackageDescription

let package = Package(
    name: "AstrologMac",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(name: "AstrologKit", targets: ["AstrologKit"])
    ],
    targets: [
        .target(
            name: "AstrologKit"
        ),
        .testTarget(
            name: "AstrologKitTests",
            dependencies: ["AstrologKit"]
        )
    ]
)
