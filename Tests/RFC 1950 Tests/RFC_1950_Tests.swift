import Byte_Primitives
import Testing

@testable import RFC_1950

extension RFC_1950 {
    @Suite struct Unit {

        @Test
        func `Single byte round-trip`() throws {
            let input: [Byte] = [0x42]
            let compressed = RFC_1950.compress(input)
            let decompressed = try RFC_1950.decompress(compressed)
            #expect(decompressed == input)
        }

        @Test
        func `Short text round-trip`() throws {
            let input = "Hello, World!".utf8.map(Byte.init)
            let compressed = RFC_1950.compress(input)
            let decompressed = try RFC_1950.decompress(compressed)
            #expect(decompressed == input)
        }

        @Test
        func `Highly compressible data round-trip`() throws {
            let input = [Byte](repeating: 0x41, count: 1000)
            let compressed = RFC_1950.compress(input)
            let decompressed = try RFC_1950.decompress(compressed)
            #expect(decompressed == input)
        }

        @Test
        func `Binary data with all byte values`() throws {
            var input: [Byte] = []
            for byte: UInt8 in 0...255 {
                input.append(Byte(byte))
            }

            let compressed = RFC_1950.compress(input)
            let decompressed = try RFC_1950.decompress(compressed)
            #expect(decompressed == input)
        }

        @Test
        func `ZLIB header is valid`() throws {
            let input = "Test".utf8.map(Byte.init)
            let compressed = RFC_1950.compress(input)

            #expect(compressed.count >= 6)

            let cmf = compressed[0].underlying
            let flg = compressed[1].underlying

            #expect(cmf & 0x0F == 8, "Compression method should be 8 (DEFLATE)")

            #expect((cmf >> 4) <= 7, "Window size should be valid")

            let headerValue = UInt16(cmf) << 8 | UInt16(flg)
            #expect(headerValue % 31 == 0, "Header checksum should be valid")
        }

        @Test
        func `Adler-32 of empty data`() {
            let checksum = RFC_1950.Adler32.checksum([Byte]())
            #expect(checksum == 1, "Adler-32 of empty data should be 1")
        }

        @Test
        func `Adler-32 of known values`() {

            let input = "Wikipedia".utf8.map(Byte.init)
            let checksum = RFC_1950.Adler32.checksum(input)
            #expect(checksum == 0x11E6_0398)
        }

        @Test
        func `Adler-32 incremental matches one-shot`() {
            let input = "Hello, World!".utf8.map(Byte.init)

            let oneShot = RFC_1950.Adler32.checksum(input)

            var adler = RFC_1950.Adler32()
            adler.update(Array(input.prefix(5)))
            adler.update(Array(input.dropFirst(5)))
            let incremental = adler.value

            #expect(oneShot == incremental)
        }

        @Test(
            arguments: [
                RFC_1951.Level.none,
                RFC_1951.Level.fast,
                RFC_1951.Level.balanced,
                RFC_1951.Level.best,
            ]
        )
        func `All compression levels produce valid output`(level: RFC_1951.Level) throws {
            let input = "The quick brown fox jumps over the lazy dog.".utf8.map(Byte.init)
            let compressed = RFC_1950.compress(input, level: level)
            let decompressed = try RFC_1950.decompress(compressed)
            #expect(decompressed == input)
        }

        @Test
        func `Empty input throws error`() {
            #expect(throws: RFC_1950.Error.empty) {
                _ = try RFC_1950.decompress([Byte]())
            }
        }

        @Test
        func `Too short input throws error`() {
            #expect(throws: RFC_1950.Error.tooShort) {
                _ = try RFC_1950.decompress([0x78, 0x9C, 0x00] as [Byte])
            }
        }

        @Test
        func `Invalid compression method throws error`() {

            let invalid: [Byte] = [0x70, 0x00, 0x00, 0x00, 0x00, 0x01]
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

            let invalid: [Byte] = [0x78, 0x00, 0x00, 0x00, 0x00, 0x01]
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
            let input = "Test".utf8.map(Byte.init)
            var compressed = RFC_1950.compress(input)

            let last = compressed.count - 1
            compressed[last] = Byte(compressed[last].underlying ^ 0xFF)

            #expect {
                _ = try RFC_1950.decompress(compressed)
            } throws: { error in
                if case RFC_1950.Error.checksumMismatch = error {
                    return true
                }
                return false
            }
        }

        @Test
        func `Unwrap extracts DEFLATE data`() throws {
            let input = "Test data".utf8.map(Byte.init)
            let zlib = RFC_1950.compress(input)

            let deflate = try RFC_1950.unwrap(zlib)

            let decompressed = try RFC_1951.decompress(deflate)
            #expect(decompressed == input)
        }

        @Test
        func `Wrap produces valid ZLIB`() throws {
            let original = "Test data".utf8.map(Byte.init)
            let deflated = RFC_1951.compress(original)

            var zlib: [Byte] = []
            RFC_1950.wrap(deflated: deflated, level: .balanced, originalData: original, into: &zlib)

            let decompressed = try RFC_1950.decompress(zlib)
            #expect(decompressed == original)
        }

        @Test
        func `Streaming API appends to existing buffer`() throws {
            let input = "Hello".utf8.map(Byte.init)
            var output: [Byte] = [0xFF, 0xFE]
            RFC_1950.compress(input, into: &output)

            #expect(output[0] == 0xFF)
            #expect(output[1] == 0xFE)
            #expect(output.count > 2)
        }
    }
}
