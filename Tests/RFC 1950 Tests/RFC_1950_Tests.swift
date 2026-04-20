// RFC_1950_Tests.swift

import Testing

@testable import RFC_1950

@Suite("RFC 1950 - ZLIB Compression")
struct RFC1950Tests {

    // MARK: - Round-trip Tests

    @Test
    func `Single byte round-trip`() throws {
        let input: [UInt8] = [0x42]
        let compressed = RFC_1950.compress(input)
        let decompressed = try RFC_1950.decompress(compressed)
        #expect(decompressed == input)
    }

    @Test
    func `Short text round-trip`() throws {
        let input = Array("Hello, World!".utf8)
        let compressed = RFC_1950.compress(input)
        let decompressed = try RFC_1950.decompress(compressed)
        #expect(decompressed == input)
    }

    @Test
    func `Highly compressible data round-trip`() throws {
        let input = [UInt8](repeating: 0x41, count: 1000)
        let compressed = RFC_1950.compress(input)
        let decompressed = try RFC_1950.decompress(compressed)
        #expect(decompressed == input)
    }

    @Test
    func `Binary data with all byte values`() throws {
        var input: [UInt8] = []
        for byte: UInt8 in 0...255 {
            input.append(byte)
        }

        let compressed = RFC_1950.compress(input)
        let decompressed = try RFC_1950.decompress(compressed)
        #expect(decompressed == input)
    }

    // MARK: - ZLIB Header Tests

    @Test
    func `ZLIB header is valid`() throws {
        let input = Array("Test".utf8)
        let compressed = RFC_1950.compress(input)

        // First two bytes are CMF and FLG
        #expect(compressed.count >= 6)

        let cmf = compressed[0]
        let flg = compressed[1]

        // CM should be 8 (DEFLATE)
        #expect(cmf & 0x0F == 8, "Compression method should be 8 (DEFLATE)")

        // CINFO should be <= 7
        #expect((cmf >> 4) <= 7, "Window size should be valid")

        // Header checksum: (CMF * 256 + FLG) % 31 == 0
        let headerValue = UInt16(cmf) << 8 | UInt16(flg)
        #expect(headerValue % 31 == 0, "Header checksum should be valid")
    }

    // MARK: - Adler-32 Tests

    @Test
    func `Adler-32 of empty data`() {
        let checksum = RFC_1950.Adler32.checksum([])
        #expect(checksum == 1, "Adler-32 of empty data should be 1")
    }

    @Test
    func `Adler-32 of known values`() {
        // "Wikipedia" example from Wikipedia article on Adler-32
        let input = Array("Wikipedia".utf8)
        let checksum = RFC_1950.Adler32.checksum(input)
        #expect(checksum == 0x11E6_0398)
    }

    @Test
    func `Adler-32 incremental matches one-shot`() {
        let input = Array("Hello, World!".utf8)

        // One-shot
        let oneShot = RFC_1950.Adler32.checksum(input)

        // Incremental
        var adler = RFC_1950.Adler32()
        adler.update(Array(input.prefix(5)))
        adler.update(Array(input.dropFirst(5)))
        let incremental = adler.value

        #expect(oneShot == incremental)
    }

    // MARK: - Compression Level Tests

    @Test(
        "All compression levels produce valid output",
        arguments: [
            RFC_1951.Level.none,
            RFC_1951.Level.fast,
            RFC_1951.Level.balanced,
            RFC_1951.Level.best,
        ]
    )
    func compressionLevels(level: RFC_1951.Level) throws {
        let input = Array("The quick brown fox jumps over the lazy dog.".utf8)
        let compressed = RFC_1950.compress(input, level: level)
        let decompressed = try RFC_1950.decompress(compressed)
        #expect(decompressed == input)
    }

    // MARK: - Error Tests

    @Test
    func `Empty input throws error`() {
        #expect(throws: RFC_1950.Error.empty) {
            _ = try RFC_1950.decompress([])
        }
    }

    @Test
    func `Too short input throws error`() {
        #expect(throws: RFC_1950.Error.tooShort) {
            _ = try RFC_1950.decompress([0x78, 0x9C, 0x00])
        }
    }

    @Test
    func `Invalid compression method throws error`() {
        // CMF with CM=0 (invalid, should be 8)
        let invalid: [UInt8] = [0x70, 0x00, 0x00, 0x00, 0x00, 0x01]
        #expect {
            _ = try RFC_1950.decompress(invalid)
        } throws: { error in
            if case RFC_1950.Error.invalidCompressionMethod = error {
                return true
            }
            return false
        }
    }

    @Test
    func `Invalid header checksum throws error`() {
        // Valid CMF (0x78) but wrong FLG that fails checksum
        let invalid: [UInt8] = [0x78, 0x00, 0x00, 0x00, 0x00, 0x01]
        #expect {
            _ = try RFC_1950.decompress(invalid)
        } throws: { error in
            if case RFC_1950.Error.invalidHeaderChecksum = error {
                return true
            }
            return false
        }
    }

    @Test
    func `Checksum mismatch throws error`() throws {
        let input = Array("Test".utf8)
        var compressed = RFC_1950.compress(input)

        // Corrupt the Adler-32 checksum (last 4 bytes)
        compressed[compressed.count - 1] ^= 0xFF

        #expect {
            _ = try RFC_1950.decompress(compressed)
        } throws: { error in
            if case RFC_1950.Error.checksumMismatch = error {
                return true
            }
            return false
        }
    }

    // MARK: - Wrap/Unwrap Tests

    @Test
    func `Unwrap extracts DEFLATE data`() throws {
        let input = Array("Test data".utf8)
        let zlib = RFC_1950.compress(input)

        let deflate = try RFC_1950.unwrap(zlib)

        // Should be able to decompress with RFC_1951
        let decompressed = try RFC_1951.decompress(deflate)
        #expect(decompressed == input)
    }

    @Test
    func `Wrap produces valid ZLIB`() throws {
        let original = Array("Test data".utf8)
        let deflated = RFC_1951.compress(original)

        var zlib: [UInt8] = []
        RFC_1950.wrap(deflated: deflated, level: .balanced, originalData: original, into: &zlib)

        // Should be valid ZLIB
        let decompressed = try RFC_1950.decompress(zlib)
        #expect(decompressed == original)
    }

    // MARK: - API Tests

    @Test
    func `Streaming API appends to existing buffer`() throws {
        let input = Array("Hello".utf8)
        var output: [UInt8] = [0xFF, 0xFE]
        RFC_1950.compress(input, into: &output)

        #expect(output[0] == 0xFF)
        #expect(output[1] == 0xFE)
        #expect(output.count > 2)
    }
}
