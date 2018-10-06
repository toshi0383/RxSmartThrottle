// swift-tools-version:4.0
// Managed by ice

import PackageDescription

let package = Package(
    name: "RxSmartThrottle",
    products: [
        .library(name: "RxSmartThrottle", targets: ["RxSmartThrottle"]),
    ],
    dependencies: [
        .package(url: "https://github.com/ReactiveX/RxSwift", from: "4.3.1"),
    ],
    targets: [
        .target(name: "RxSmartThrottle", dependencies: ["RxSwift"]),
        .testTarget(name: "RxSmartThrottleTests", dependencies: ["RxSmartThrottle", "RxTest"]),
    ]
)
