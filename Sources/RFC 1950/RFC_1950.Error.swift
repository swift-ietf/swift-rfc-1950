public import Byte_Primitives

extension RFC_1950 {

    public enum Error: Swift.Error, Sendable, Equatable {

        case empty

        case tooShort

        case invalidCompressionMethod(_ value: Byte)

        case invalidWindowSize(_ cinfo: Byte)

        case invalidHeaderChecksum

        case presetDictionaryRequired

        case checksumMismatch(expected: UInt32, actual: UInt32)

        case deflateError(RFC_1951.Error)
    }
}

extension RFC_1950.Error: CustomStringConvertible {
    public var description: String {
        switch self {
        case .empty:
            return "Input data is empty"

        case .tooShort:
            return "Input data too short for ZLIB format (minimum 6 bytes)"

        case .invalidCompressionMethod(let value):
            return "Invalid compression method: \(value) (expected 8 for DEFLATE)"

        case .invalidWindowSize(let cinfo):
            return "Invalid window size: CINFO=\(cinfo) (maximum is 7)"

        case .invalidHeaderChecksum:
            return "Invalid ZLIB header checksum (FCHECK)"

        case .presetDictionaryRequired:
            return "ZLIB stream requires preset dictionary (not supported)"

        case .checksumMismatch(let expected, let actual):
            return
                "Adler-32 checksum mismatch: expected 0x\(String(expected, radix: 16)), got 0x\(String(actual, radix: 16))"

        case .deflateError(let error):
            return "DEFLATE error: \(error)"
        }
    }
}
