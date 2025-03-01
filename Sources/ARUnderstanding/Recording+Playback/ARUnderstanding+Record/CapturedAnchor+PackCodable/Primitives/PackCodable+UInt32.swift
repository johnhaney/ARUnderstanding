//
//  PackCodable+Double.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

extension UInt32: PackEncodable {
    public func pack() throws -> Data {
        .init(underlying: UInt32(bitPattern: Int32(self)).bigEndian)
    }
}

extension UInt32: PackDecodable {
    public static func unpack(data: Data) throws -> (UInt32, Int) {
        let bytes = MemoryLayout<UInt32>.size
        guard data.count >= bytes else { throw UnpackError.needsMoreData(bytes) }
        let value = Int32(bigEndian: data.interpreted())
        let number = UInt32(bitPattern: value)
        return (number, bytes)
    }
}
