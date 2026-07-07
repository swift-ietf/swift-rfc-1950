// RFC_1950.wrap.swift

internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
public import RFC_1951

extension RFC_1950 {
    /// Wrap already-DEFLATE-compressed data in ZLIB format
    ///
    /// Use this when you have raw DEFLATE data and want to add the ZLIB wrapper.
    ///
    /// - Parameters:
    ///   - deflated: DEFLATE-compressed data (raw, without ZLIB wrapper)
    ///   - level: The compression level used for the DEFLATE data
    ///   - originalData: The original uncompressed data (needed for Adler-32 checksum)
    ///   - output: Buffer to append ZLIB-wrapped data to
    ///
    /// ## Example
    ///
    /// ```swift
    /// let deflated = RFC_1951.compress(original)
    /// var zlib: [Byte] = []
    /// RFC_1950.wrap(deflated: deflated, level: .balanced, originalData: original, into: &zlib)
    /// ```
    public static func wrap<Deflated, Original, Output>(
        deflated: Deflated,
        level: RFC_1951.Level,
        originalData: Original,
        into output: inout Output
    ) where Deflated: Collection, Deflated.Element == Byte, Original: Collection, Original.Element == Byte, Output: RangeReplaceableCollection, Output.Element == Byte {
        // CMF byte: CM=8 (DEFLATE), CINFO=7 (32K window)
        let cmf: UInt8 = 0x78

        // FLG byte with FLEVEL
        let flevel: UInt8
        switch level {
        case .none: flevel = 0
        case .fast: flevel = 1
        case .balanced: flevel = 2
        case .best: flevel = 3
        }

        let flgWithoutCheck = flevel << 6
        let fcheck = (31 - Int(UInt16(bytes: [Byte(cmf), Byte(flgWithoutCheck)], endianness: .big)! % 31)) % 31
        let flg = flgWithoutCheck | UInt8(fcheck)

        output.append(Byte(cmf))
        output.append(Byte(flg))

        // DEFLATE data
        output.append(contentsOf: deflated)

        // Adler-32 checksum of original uncompressed data (big-endian)
        let checksum = Adler32.checksum(originalData)
        checksum.bytes(into: &output, endianness: .big)
    }
}
