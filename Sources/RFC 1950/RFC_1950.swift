// RFC_1950.swift

/// RFC 1950: ZLIB Compressed Data Format Specification version 3.3
///
/// ZLIB is a wrapper format around DEFLATE compression that adds:
/// - A 2-byte header with compression method and flags
/// - An optional preset dictionary identifier
/// - An Adler-32 checksum for integrity verification
///
/// ## Key Types
///
/// - ``Adler32``: Incremental Adler-32 checksum calculator
///
/// ## Example
///
/// ```swift
/// // Compress data with ZLIB wrapper
/// var compressed: [Byte] = []
/// RFC_1950.compress(input, into: &compressed)
///
/// // Decompress ZLIB data
/// var decompressed: [Byte] = []
/// try RFC_1950.decompress(compressed, into: &decompressed)
/// ```
///
/// ## See Also
///
/// - [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950)
/// - [RFC 1951](https://www.rfc-editor.org/rfc/rfc1951) - DEFLATE compression
public enum RFC_1950 {}
