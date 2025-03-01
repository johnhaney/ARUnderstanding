//
//  PackCodable+Double.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

extension Double: PackEncodable {
    public func pack() throws -> Data {
        .init(underlying: bitPattern.bigEndian)
    }
}

extension Double: PackDecodable {
    public static func unpack(data: Data) throws -> (Double, Int) {
        let bytes = MemoryLayout<UInt64>.size
        guard data.count >= bytes else { throw UnpackError.needsMoreData(bytes) }
        let value = UInt64(bigEndian: data.interpreted())
        return (Double(bitPattern: value), bytes)
    }
}
