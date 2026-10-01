// swift-tools-version: 6.2

import PackageDescription

// FlickrKit 2.0, the Swift rewrite. The Objective-C 1.x sources under Classes/ are not part of
// the package; 1.x stays available from master and the v1.1.0 tag.
let package = Package(
    name: "FlickrKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(name: "FlickrKit", targets: ["FlickrKit"])
    ],
    targets: [
        .target(name: "FlickrKit"),
        .testTarget(name: "FlickrKitTests", dependencies: ["FlickrKit"])
    ]
)
