internal import Binary_Endianness_Primitives
internal import Binary_Primitives_Standard_Library_Integration
public import Byte_Primitives
public import RFC_1951

extension RFC_1950 {

    public static func wrap<Deflated, Original, Output>(
        deflated: Deflated,
        level: RFC_1951.Level,
        originalData: Original,
        into output: inout Output
    )
    where
        Deflated: Swift.Collection, Deflated.Element == Byte, Original: Swift.Collection,
        Original.Element == Byte, Output: RangeReplaceableCollection, Output.Element == Byte
    {

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

        output.append(contentsOf: deflated)

        let checksum = Adler32.checksum(originalData)
        checksum.bytes(into: &output, endianness: .big)
    }
}
