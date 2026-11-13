public import Byte

extension RFC_1950 {

    public struct Adler32: Sendable, Hashable {

        @usableFromInline
        var s1: UInt32

        @usableFromInline
        var s2: UInt32

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

    @usableFromInline
    static var base: UInt32 { 65521 }

    @inlinable
    public mutating func update<Bytes: Swift::Collection>(_ bytes: Bytes)
    where Bytes.Element == Byte {

        let contiguous: Void? = bytes.withContiguousStorageIfAvailable { buffer in
            unsafe update(contiguous: buffer)
        }
        guard contiguous == nil else { return }

        let chunkSize = 5552

        var iterator = bytes.makeIterator()
        var remaining = bytes.count

        while remaining > 0 {
            let batchSize = min(remaining, chunkSize)
            remaining -= batchSize

            for _ in 0..<batchSize {
                if let byte = iterator.next() {
                    s1 += UInt32(byte.underlying)
                    s2 += s1
                }
            }

            s1 %= Self.base
            s2 %= Self.base
        }
    }

    @usableFromInline
    mutating func update(contiguous buffer: UnsafeBufferPointer<Byte>) {
        var a = s1
        var b = s2
        var index = 0
        while index < buffer.count {
            let end = min(index &+ 5552, buffer.count)
            while index < end {
                a &+= UInt32(unsafe buffer[index].underlying)
                b &+= a
                index &+= 1
            }
            a %= Self.base
            b %= Self.base
        }
        s1 = a
        s2 = b
    }

    public var value: UInt32 {
        (s2 << 16) | s1
    }

    @inlinable
    public static func checksum<Bytes: Swift::Collection>(_ bytes: Bytes) -> UInt32
    where Bytes.Element == Byte {
        var adler = RFC_1950.Adler32()
        adler.update(bytes)
        return adler.value
    }
}
