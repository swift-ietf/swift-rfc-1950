import Byte
import Testing

@testable import RFC_1950

enum `Adler32 Equivalence Tests` {}

extension `Adler32 Equivalence Tests` {
    @Suite
    struct `Adler-32 over contiguous bytes equals Adler-32 byte by byte` {

        private static func plain(_ bytes: [Byte]) -> UInt32 {
            var a: UInt32 = 1
            var b: UInt32 = 0
            for byte in bytes {
                a = (a + UInt32(byte.underlying)) % 65521
                b = (b + a) % 65521
            }
            return b << 16 | a
        }

        @Test(arguments: [0, 1, 5551, 5552, 5553, 11_104, 100_000])
        func `contiguous, sliced and non-contiguous bytes give the plain checksum`(count: Int) {
            var state: UInt64 = UInt64(count) &+ 1
            let bytes = (0..<count).map { _ in
                state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
                return Byte(UInt8(truncatingIfNeeded: state >> 56) | (count % 2 == 0 ? 0xF0 : 0))
            }
            let expected = Self.plain(bytes)
            #expect(RFC_1950.Adler32.checksum(bytes) == expected)
            #expect(RFC_1950.Adler32.checksum(bytes.lazy.map { $0 }) == expected)
            #expect(RFC_1950.Adler32.checksum(([Byte(7)] + bytes).dropFirst()) == expected)

            var split = RFC_1950.Adler32()
            split.update(bytes.prefix(count / 3))
            split.update(bytes.dropFirst(count / 3).lazy.map { $0 })
            #expect(split.value == expected)
        }
    }
}
