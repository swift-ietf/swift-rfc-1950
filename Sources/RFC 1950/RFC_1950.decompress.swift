// RFC_1950.decompress.swift

import RFC_1951
public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration

extension RFC_1950 {
    /// Decompress ZLIB-formatted data
    ///
    /// - Parameters:
    ///   - input: The compressed data in ZLIB format
    ///   - output: Buffer to append decompressed data to
    /// - Throws: `Error` if the data is invalid or corrupted
    ///
    /// ## Example
    ///
    /// ```swift
    /// var decompressed: [Byte] = []
    /// try RFC_1950.decompress(compressed, into: &decompressed)
    /// ```
    public static func decompress<Input, Output>(
        _ input: Input,
        into output: inout Output
    ) throws(Error) where Input: Collection, Input.Element == Byte, Output: RangeReplaceableCollection, Output.Element == Byte {
        guard !input.isEmpty else {
            throw .empty
        }

        // Minimum ZLIB stream: 2 (header) + 1 (empty DEFLATE) + 4 (checksum) = 7 bytes
        // But practically, minimum is 6 bytes for a valid empty stream
        guard input.count >= 6 else {
            throw .tooShort
        }

        let inputArray = Array(input)
        var offset = 0

        // Parse CMF byte
        let cmf = inputArray[offset].underlying
        offset += 1

        let cm = cmf & 0x0F  // Compression method
        let cinfo = (cmf >> 4) & 0x0F  // Window size (for DEFLATE)

        guard cm == 8 else {
            throw .invalidCompressionMethod(Byte(cm))
        }

        guard cinfo <= 7 else {
            throw .invalidWindowSize(Byte(cinfo))
        }

        // Parse FLG byte
        let flg = inputArray[offset].underlying
        offset += 1

        // Verify header checksum
        let headerValue = UInt16(cmf) << 8 | UInt16(flg)
        guard headerValue % 31 == 0 else {
            throw .invalidHeaderChecksum
        }

        let fdict = (flg >> 5) & 0x01  // Preset dictionary flag

        // We don't support preset dictionaries
        guard fdict == 0 else {
            throw .presetDictionaryRequired
        }

        // Extract DEFLATE data (everything except header and trailer)
        let deflateData = inputArray[offset..<(inputArray.count - 4)]

        // Decompress DEFLATE data
        do {
            try RFC_1951.decompress(deflateData, into: &output)
        } catch let error {
            throw .deflateError(error)
        }

        // Verify Adler-32 checksum
        let checksumOffset = inputArray.count - 4
        let expectedChecksum =
            UInt32(inputArray[checksumOffset]) << 24 | UInt32(inputArray[checksumOffset + 1]) << 16
            | UInt32(inputArray[checksumOffset + 2]) << 8 | UInt32(inputArray[checksumOffset + 3])

        let actualChecksum = Adler32.checksum(output)

        guard expectedChecksum == actualChecksum else {
            throw .checksumMismatch(expected: expectedChecksum, actual: actualChecksum)
        }
    }

    /// Convenience: decompress and return new array
    ///
    /// - Parameter input: The compressed data in ZLIB format
    /// - Returns: Decompressed data
    /// - Throws: `Error` if the data is invalid or corrupted
    public static func decompress<Bytes>(
        _ input: Bytes
    ) throws(Error) -> [Byte] where Bytes: Collection, Bytes.Element == Byte {
        var output: [Byte] = []
        try decompress(input, into: &output)
        return output
    }
}
