# swift-rfc-1950

![Development Status](https://img.shields.io/badge/status-active--development-blue.svg)

ZLIB stream framing over DEFLATE-compressed data, as specified in RFC 1950.

## Standard Reference

- **RFC**: 1950
- **Title**: ZLIB Compressed Data Format Specification

## Installation

Add the package to your `Package.swift` dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/swift-ietf/swift-rfc-1950.git", from: "0.1.0")
]
```

Add the product to a target that needs it:

```swift
.target(
    name: "YourTarget",
    dependencies: [
        .product(name: "RFC 1950", package: "swift-rfc-1950")
    ]
)
```

## License

Apache 2.0. See [LICENSE.md](LICENSE.md).
