public import Byte
internal import Byte_Standard_Library_Integration

extension RFC_1950 {

    public struct Adler32: Sendable, Hashable {

        private var s1: UInt32

        private var s2: UInt32

        public init() {
            self.s1 = 1
            self.s2 = 0
        }

        public init(seed: UInt32) {
            self.s1 = seed & 0xFFFF
            self.s2 = (seed >> 16) & 0xFFFF
        }
    }
}

extension RFC_1950.Adler32 {

    private static let base: UInt32 = 65521

    public mutating func update<Bytes: Swift.Collection>(_ bytes: Bytes)
    where Bytes.Element == Byte {

        let chunkSize = 5552

        var iterator = bytes.makeIterator()
        var remaining = bytes.count

        while remaining > 0 {
            let batchSize = min(remaining, chunkSize)
            remaining -= batchSize

            for _ in 0..<batchSize {
                if let byte = iterator.next() {
                    s1 += UInt32(byte)
                    s2 += s1
                }
            }

            s1 %= Self.base
            s2 %= Self.base
        }
    }

    public var value: UInt32 {
        (s2 << 16) | s1
    }

    public static func checksum<Bytes: Swift.Collection>(_ bytes: Bytes) -> UInt32
    where Bytes.Element == Byte {
        var adler = RFC_1950.Adler32()
        adler.update(bytes)
        return adler.value
    }
}
