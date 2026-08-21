internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
import RFC_1951

extension RFC_1950 {

    public static func unwrap<Input>(
        _ input: Input
    ) throws(Error) -> ArraySlice<Byte> where Input: Swift.Collection, Input.Element == Byte {
        guard !input.isEmpty else {
            throw .empty
        }

        guard input.count >= 6 else {
            throw .tooShort
        }

        let inputArray = Array(input)

        let cmf = inputArray[0].underlying
        let cm = cmf & 0x0F
        let cinfo = (cmf >> 4) & 0x0F

        guard cm == 8 else {
            throw .invalidCompressionMethod(Byte(cm))
        }

        guard cinfo <= 7 else {
            throw .invalidWindowSize(Byte(cinfo))
        }

        let flg = inputArray[1].underlying
        let headerValue = UInt16(bytes: inputArray[0..<2], endianness: .big)!
        guard headerValue % 31 == 0 else {
            throw .invalidHeaderChecksum
        }

        let fdict = (flg >> 5) & 0x01
        guard fdict == 0 else {
            throw .presetDictionaryRequired
        }

        return inputArray[2..<(inputArray.count - 4)]
    }
}
