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
            url: "https://github.com/tattn/open-jtalk-dic-swiftpm/releases/download/v1.11/OpenJTalkDictionary.xcframework.zip",
            checksum: "76be3ad874042fe8e013ee354b56a3d414e9d484768c84b3d7392401e29eea04"
        ),
    ]
)