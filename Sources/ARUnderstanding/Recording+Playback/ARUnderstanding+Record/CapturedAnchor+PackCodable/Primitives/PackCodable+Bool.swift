//
//  PackCodable+Bool.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/11/25.
//

import Foundation

extension Bool: PackEncodable {
    public func pack() throws -> Data {
        .init(repeating: self ? 1 : 0, count: 1)
    }
}

extension Bool: PackDecodable {
    public static func unpack(data: Data) throws -> (Bool, Int) {
        guard !data.isEmpty else { throw UnpackError.needsMoreData(1) }
        let number: UInt8 = data[0]
        return (number == 1, 1)
    }
}
