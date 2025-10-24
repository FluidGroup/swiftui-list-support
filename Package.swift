// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swiftui-list-support",
  platforms: [
    .macOS(.v15),
    .iOS(.v17)
  ],
  products: [
    // Products define the executables and libraries a package produces, making them visible to other packages.
    .library(
      name: "DynamicList",
      targets: ["DynamicList"]
    ),
    .library(
      name: "ChatUI",
      targets: ["ChatUI"]
    ),
    .library(
      name: "CollectionView",
      targets: ["CollectionView"]
    ),
    .library(
      name: "ScrollTracking",
      targets: ["ScrollTracking"]
    ),
    .library(
      name: "StickyHeader",
      targets: ["StickyHeader"]
    ),
    .library(
      name: "RefreshControl",
      targets: ["RefreshControl"]
    ),
    .library(
      name: "SelectableForEach",
      targets: ["SelectableForEach"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/FluidGroup/swift-indexed-collection", from: "0.2.1"),
    .package(url: "https://github.com/siteline/swiftui-introspect", from: "26.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "DynamicList",
      dependencies: [
      ]
    ),
    .target(
      name: "CollectionView",
      dependencies: [
        "ScrollTracking",
      ]
    ),
    .target(
      name: "ChatUI",
      dependencies: [
        .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
      ]
    ),
    .target(
      name: "ScrollTracking",
      dependencies: [
        .product(name: "SwiftUIIntrospect", package: "swiftui-introspect")
      ]
    ),
    .target(
      name: "StickyHeader",
      dependencies: [
      ]
    ),
    .target(
      name: "RefreshControl",
      dependencies: [
      ]
    ),
    .target(
      name: "SelectableForEach",
      dependencies: [
        .product(name: "IndexedCollection", package: "swift-indexed-collection"),
      ]
    ),
    .testTarget(
      name: "DynamicListTests",
      dependencies: ["DynamicList"]
    ),
  ],
  swiftLanguageModes: [.v6]
)
