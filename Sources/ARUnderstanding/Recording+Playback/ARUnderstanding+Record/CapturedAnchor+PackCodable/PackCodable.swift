//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

enum UnpackError: Error {
    case needsMoreData(Int)
    case failed
}

enum PackError: Error {
    case failed
}

protocol PackEncodable {
    func pack() throws -> Data
}

protocol PackDecodable {
    static func unpack(data: Data) throws -> (Self, Int)
}

extension PackDecodable {
    public static func unpack(data: Data, count: Int) throws -> ([Self], Int) {
        guard count >= .zero
        else {
            throw UnpackError.failed
        }
        guard count > .zero else { return ([], .zero) }
        var offset: Int = 0
        let result = try (1...count).map { _ in
            let (value, consumed) = try Self.unpack(data: data[(data.startIndex + offset)...])
            offset += consumed
            return value
        }
        return (result, offset)
    }
}

protocol PackCodable: PackEncodable, PackDecodable {}

//
//protocol PackDataDecodable {
//    static func unpack(data: Data) throws -> Self
//}
//
//extension PackDecodable: PackDataDecodable {
//    static func unpack(data: Data) throws -> Self {
//        let packed: Packed = try Packed.unpack(data: data)
//        let item = try Self.unpack(packed: packed)
//        return item
//    }
//}
//
//protocol PackDataEncodable {
//    static func packData(item: Self) throws -> Data
//}
//
//extension PackEncodable: PackDataEncodable {
//    static func packData(item: Self) throws -> Data {
//        let packed: Packed = self.pack(item: item)
//        let data: Data = Packed.packData(item: packed)
//        return data
//    }
//}
//
//protocol PackDecodableExpectedSize: PackDecodable {
//    static func expectedPackedLength(data: Data) -> Int
//}
//
//extension PackEncodable {
//    func packAppending(_ output: Data) throws {
//        let data = try Self.packData(item: self)
//        output.append(data)
//    }
//}
//
//extension PackDecodable where Packed == Data {
////    init?(packedData: Data, offset: inout Int = 0) {
////        guard let (unpacked, bytesConsumed) = try? Self.unpack(data: packedData[offset...])
////        else { return nil }
////        offset += bytesConsumed
////        self = unpacked
////    }
//    
//}
//
//protocol PackCodable: PackEncodable, PackDecodable {}

extension Data {
    init<T>(underlying value: T) {
        var target = value
        self = Swift.withUnsafeBytes(of: &target) {
            Data($0)
        }
    }
    
    func interpreted<T>(as type: T.Type = T.self) -> T {
        Data(self).withUnsafeBytes {
            $0.baseAddress!.load(as: T.self)
        }
    }
}
