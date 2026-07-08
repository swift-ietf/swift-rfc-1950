// RFC_1950.Adler32.swift

public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration

extension RFC_1950 {
    /// Adler-32 checksum calculator
    ///
    /// Adler-32 is a checksum algorithm that is faster than CRC-32 but
    /// provides similar error detection for most data corruption scenarios.
    ///
    /// Per RFC 1950 Section 2.2:
    /// - s1 = 1 + D1 + D2 + ... + Dn (mod 65521)
    /// - s2 = (1 + D1) + (1 + D1 + D2) + ... + (1 + D1 + ... + Dn) (mod 65521)
    /// - Adler-32 = s2 * 65536 + s1
    ///
    /// ## Example
    ///
    /// ```swift
    /// // One-shot calculation
    /// let checksum = RFC_1950.Adler32.checksum(data)
    ///
    /// // Incremental calculation
    /// var adler = RFC_1950.Adler32()
    /// adler.update(chunk1)
    /// adler.update(chunk2)
    /// let checksum = adler.value
    /// ```
    public struct Adler32: Sendable, Hashable {
        /// Running sum of all bytes
        private var s1: UInt32

        /// Running sum of s1 values
        private var s2: UInt32

        /// Create a new Adler-32 calculator with the standard initial value
        ///
        /// The initial value is 1 (s1=1, s2=0), which produces checksum 1
        /// for empty input, per RFC 1950.
        public init() {
            self.s1 = 1
            self.s2 = 0
        }

        /// Create an Adler-32 calculator with a custom seed
        ///
        /// - Parameter seed: Initial checksum value (for continuing a previous calculation)
        public init(seed: UInt32) {
            self.s1 = seed & 0xFFFF
            self.s2 = (seed >> 16) & 0xFFFF
        }
    }
}

extension RFC_1950.Adler32 {
    /// Modulo value for Adler-32 (largest prime less than 2^16)
    private static let base: UInt32 = 65521

    /// Update the checksum with additional bytes
    ///
    /// - Parameter bytes: Bytes to include in the checksum
    public mutating func update<Bytes: Collection>(_ bytes: Bytes)
    where Bytes.Element == Byte {
        // Process in chunks to avoid overflow
        // We can process up to 5552 bytes before needing to take modulo
        // (because 255 * 5552 + 65520 < 2^32)
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

    /// The current checksum value
    public var value: UInt32 {
        (s2 << 16) | s1
    }

    /// Calculate checksum for a collection of bytes in one call
    ///
    /// - Parameter bytes: The bytes to checksum
    /// - Returns: The Adler-32 checksum
    public static func checksum<Bytes: Collection>(_ bytes: Bytes) -> UInt32
    where Bytes.Element == Byte {
        var adler = RFC_1950.Adler32()
        adler.update(bytes)
        return adler.value
    }
}
