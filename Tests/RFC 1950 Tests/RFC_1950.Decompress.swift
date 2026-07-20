// RFC_1950.Decompress.swift

import Byte_Primitives
import Testing

@testable import RFC_1950

extension RFC_1950 {
    @Suite struct Decompress {
        @Suite struct `Edge Case` {}
    }
}

extension RFC_1950.Decompress.`Edge Case` {
    @Test
    func `decompress appends to a non-empty output buffer`() throws {
        let payload = "Hello, World!".utf8.map(Byte.init)
        let compressed = RFC_1950.compress(payload)

        var output: [Byte] = [0xDE, 0xAD, 0xBE]
        try RFC_1950.decompress(compressed, into: &output)

        #expect(output == [0xDE, 0xAD, 0xBE] + payload)
    }

    @Test
    func `decompress into empty buffer still verifies checksum`() throws {
        let payload = [Byte](repeating: 0x41, count: 64)
        var compressed = RFC_1950.compress(payload)

        // Corrupt the Adler-32 trailer (last 4 bytes)
        let last = compressed.count - 1
        compressed[last] = Byte(compressed[last].underlying &+ 1)

        var output: [Byte] = []
        #expect(throws: RFC_1950.Error.self) {
            try RFC_1950.decompress(compressed, into: &output)
        }
    }
}
