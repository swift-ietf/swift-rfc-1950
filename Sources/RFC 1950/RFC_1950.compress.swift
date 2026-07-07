// RFC_1950.compress.swift

internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
public import RFC_1951

extension RFC_1950 {
    /// Compress data using ZLIB format (DEFLATE with wrapper)
    ///
    /// - Parameters:
    ///   - input: The data to compress
    ///   - output: Buffer to append compressed data to
    ///   - level: Compression level (default: `.balanced`)
    ///
    /// ## Example
    ///
    /// ```swift
    /// var compressed: [Byte] = []
    /// RFC_1950.compress(data, into: &compressed)
    /// ```
    public static func compress<Input, Output>(
        _ input: Input,
        into output: inout Output,
        level: RFC_1951.Level = .balanced
    ) where Input: Collection, Input.Element == Byte, Output: RangeReplaceableCollection, Output.Element == Byte {
        let inputArray = Array(input)

        // ZLIB header (2 bytes)
        // CMF byte: CM (4 bits) + CINFO (4 bits)
        // CM = 8 (DEFLATE)
        // CINFO = 7 (32K window size, log2(32768) - 8 = 7)
        let cmf: UInt8 = 0x78  // 8 | (7 << 4) = 0x78

        // FLG byte: FCHECK (5 bits) + FDICT (1 bit) + FLEVEL (2 bits)
        // FDICT = 0 (no preset dictionary)
        // FLEVEL encodes compression level:
        //   0 = fastest, 1 = fast, 2 = default, 3 = maximum
        let flevel: UInt8
        switch level {
        case .none: flevel = 0
        case .fast: flevel = 1
        case .balanced: flevel = 2
        case .best: flevel = 3
        }

        // FCHECK is set so that (CMF * 256 + FLG) is a multiple of 31
        let flgWithoutCheck = flevel << 6
        let fcheck = (31 - Int(UInt16(bytes: [Byte(cmf), Byte(flgWithoutCheck)], endianness: .big)! % 31)) % 31
        let flg = flgWithoutCheck | UInt8(fcheck)

        output.append(Byte(cmf))
        output.append(Byte(flg))

        // DEFLATE compressed data
        RFC_1951.compress(inputArray, into: &output, level: level)

        // Adler-32 checksum of uncompressed data (big-endian)
        let checksum = Adler32.checksum(inputArray)
        checksum.bytes(into: &output, endianness: .big)
    }

    /// Convenience: compress and return new array
    ///
    /// - Parameters:
    ///   - input: The data to compress
    ///   - level: Compression level (default: `.balanced`)
    /// - Returns: Compressed data in ZLIB format
    public static func compress<Bytes>(
        _ input: Bytes,
        level: RFC_1951.Level = .balanced
    ) -> [Byte] where Bytes: Collection, Bytes.Element == Byte {
        var output: [Byte] = []
        compress(input, into: &output, level: level)
        return output
    }
}
