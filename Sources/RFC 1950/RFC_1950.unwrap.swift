// RFC_1950.unwrap.swift

import RFC_1951
public import Byte_Primitives

extension RFC_1950 {
    /// Unwrap ZLIB data to get raw DEFLATE stream
    ///
    /// Use this when you need the raw DEFLATE data without decompressing it.
    ///
    /// - Parameter input: ZLIB-formatted data
    /// - Returns: The raw DEFLATE data (without ZLIB header and trailer)
    /// - Throws: `Error` if the ZLIB header is invalid
    ///
    /// ## Example
    ///
    /// ```swift
    /// let deflated = try RFC_1950.unwrap(zlibData)
    /// // Now you have raw DEFLATE data
    /// ```
    public static func unwrap<Input>(
        _ input: Input
    ) throws(Error) -> ArraySlice<Byte> where Input: Collection, Input.Element == Byte {
        guard !input.isEmpty else {
            throw .empty
        }

        guard input.count >= 6 else {
            throw .tooShort
        }

        let inputArray = Array(input)

        // Parse and validate CMF byte
        let cmf = inputArray[0].underlying
        let cm = cmf & 0x0F
        let cinfo = (cmf >> 4) & 0x0F

        guard cm == 8 else {
            throw .invalidCompressionMethod(cm)
        }

        guard cinfo <= 7 else {
            throw .invalidWindowSize(cinfo)
        }

        // Parse and validate FLG byte
        let flg = inputArray[1].underlying
        let headerValue = UInt16(cmf) << 8 | UInt16(flg)
        guard headerValue % 31 == 0 else {
            throw .invalidHeaderChecksum
        }

        let fdict = (flg >> 5) & 0x01
        guard fdict == 0 else {
            throw .presetDictionaryRequired
        }

        // Return DEFLATE data (skip 2-byte header, exclude 4-byte trailer)
        return inputArray[2..<(inputArray.count - 4)]
    }
}
