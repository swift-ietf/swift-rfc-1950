internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
internal import Byte_Primitives_Standard_Library_Integration
import RFC_1951

extension RFC_1950 {

    public static func decompress<Input, Output>(
        _ input: Input,
        into output: inout Output
    ) throws(Error)
    where
        Input: Swift.Collection, Input.Element == Byte, Output: RangeReplaceableCollection,
        Output.Element == Byte
    {
        guard !input.isEmpty else {
            throw .empty
        }

        guard input.count >= 6 else {
            throw .tooShort
        }

        let inputArray = Array(input)
        var offset = 0

        let cmf = inputArray[offset].underlying
        offset += 1

        let cm = cmf & 0x0F
        let cinfo = (cmf >> 4) & 0x0F

        guard cm == 8 else {
            throw .invalidCompressionMethod(Byte(cm))
        }

        guard cinfo <= 7 else {
            throw .invalidWindowSize(Byte(cinfo))
        }

        let flg = inputArray[offset].underlying
        offset += 1

        let headerValue = UInt16(bytes: inputArray[0..<2], endianness: .big)!
        guard headerValue % 31 == 0 else {
            throw .invalidHeaderChecksum
        }

        let fdict = (flg >> 5) & 0x01

        guard fdict == 0 else {
            throw .presetDictionaryRequired
        }

        let deflateData = inputArray[offset..<(inputArray.count - 4)]

        let preexistingCount = output.count

        do throws(RFC_1951.Error) {
            try RFC_1951.decompress(deflateData, into: &output)
        } catch {
            throw .deflateError(error)
        }

        let checksumOffset = inputArray.count - 4
        let expectedChecksum = UInt32(
            bytes: inputArray[checksumOffset..<checksumOffset + 4],
            endianness: .big
        )!

        let actualChecksum = Adler32.checksum(output.dropFirst(preexistingCount))

        guard expectedChecksum == actualChecksum else {
            throw .checksumMismatch(expected: expectedChecksum, actual: actualChecksum)
        }
    }

    public static func decompress<Bytes>(
        _ input: Bytes
    ) throws(Error) -> [Byte] where Bytes: Swift.Collection, Bytes.Element == Byte {
        var output: [Byte] = []
        try decompress(input, into: &output)
        return output
    }
}
