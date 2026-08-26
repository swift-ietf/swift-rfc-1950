internal import Binary_Endianness
internal import Binary_Standard_Library_Integration
public import Byte
public import RFC_1951

extension RFC_1950 {

    public static func compress<Input, Output>(
        _ input: Input,
        into output: inout Output,
        level: RFC_1951.Level = .balanced
    )
    where
        Input: Swift.Collection, Input.Element == Byte, Output: RangeReplaceableCollection,
        Output.Element == Byte
    {
        let inputArray = Array(input)

        let cmf: UInt8 = 0x78

        let flevel: UInt8
        switch level {
        case .none: flevel = 0
        case .fast: flevel = 1
        case .balanced: flevel = 2
        case .best: flevel = 3
        }

        let flgWithoutCheck = flevel << 6
        let fcheck =
            (31 - Int(UInt16(bytes: [Byte(cmf), Byte(flgWithoutCheck)], endianness: .big)! % 31))
            % 31
        let flg = flgWithoutCheck | UInt8(fcheck)

        output.append(Byte(cmf))
        output.append(Byte(flg))

        RFC_1951.compress(inputArray, into: &output, level: level)

        let checksum = Adler32.checksum(inputArray)
        checksum.bytes(into: &output, endianness: .big)
    }

    public static func compress<Bytes>(
        _ input: Bytes,
        level: RFC_1951.Level = .balanced
    ) -> [Byte] where Bytes: Swift.Collection, Bytes.Element == Byte {
        var output: [Byte] = []
        compress(input, into: &output, level: level)
        return output
    }
}
