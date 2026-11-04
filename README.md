# swift-rfc-1950

Use this package when you need to read or write zlib streams: DEFLATE data with a two-byte header and an Adler-32 trailer. Start from `RFC_1950.compress(_:level:)` and `RFC_1950.decompress(_:)`. If you already have raw DEFLATE data and only need the framing, use `RFC_1950.wrap(deflated:level:originalData:into:)` and `RFC_1950.unwrap(_:)`. For raw DEFLATE with no framing, use swift-rfc-1951. For a checksum alone, use `RFC_1950.Adler32`.

## Laws

- Compressing writes the method byte `0x78`, which is DEFLATE with a 32 KiB window. The level you pass is recorded in the header. Decompressing ignores the recorded level, so streams from zlib at any level decode.
- Decompressing refuses input shorter than six bytes, a method other than DEFLATE, a window larger than 32 KiB, a header whose check bits are wrong, and any stream that asks for a preset dictionary. Preset dictionaries are not supported.
- The last four bytes are always read as the big-endian Adler-32 of the decompressed data, and a mismatch throws.
- Decompressing appends to the output you pass. The checksum covers only the bytes this call appended. If the checksum does not match, those bytes have already been appended when the error is thrown.
- `RFC_1950.unwrap(_:)` checks the header the same way but does not check the Adler-32 trailer. It returns the bytes between the header and the trailer.
- `RFC_1950.wrap(deflated:level:originalData:into:)` takes the checksum from `originalData` and does not check that `deflated` is its compressed form.
- `RFC_1950.Adler32` starts at 1, so the checksum of no bytes is 1. Feeding bytes in several `RFC_1950.Adler32.update(_:)` calls gives the same value as one call over all of them.
