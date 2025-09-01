// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenJTalkDictionary",
    platforms: [
        .iOS(.v16),
        .macOS(.v13)
    ],
    products: [        
        .library(
            name: "openjtalkdic",
            targets: ["openjtalkdic"]),
    ],
    targets: [
        .binaryTarget(
            name: "openjtalkdic",
            url: "https://github.com/tattn/open-jtalk-dic-swiftpm/releases/download/v1.11.0/OpenJTalkDictionary.xcframework.zip",
            checksum: "b06552e060c2470ff899e844c6ab4fd87105989943d11c36d3af6083213c2198"
        ),
    ]
)