//
//  PackCodable+Double.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

extension Int: PackEncodable {
    public func pack() throws -> Data {
        .init(underlying: UInt64(bitPattern: Int64(self)).bigEndian)
    }
}

extension Int: PackDecodable {
    public static func unpack(data: Data) throws -> (Int, Int) {
        let bytes = MemoryLayout<UInt64>.size
        guard data.count >= bytes else { throw UnpackError.needsMoreData(bytes) }
        let value = UInt64(bigEndian: data.interpreted())
        let number = Int(Int64(bitPattern: value))
        return (number, bytes)
    }
}
