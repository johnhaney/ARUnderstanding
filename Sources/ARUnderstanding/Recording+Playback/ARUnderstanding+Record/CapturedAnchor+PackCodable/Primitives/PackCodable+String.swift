//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 10/26/25.
//

import Foundation

extension String: PackEncodable {
    public func pack() throws -> Data {
        try self.count.pack() + Data(self.utf8)
    }
}

extension String: PackDecodable {
    public static func unpack(data: Data) throws -> (String, Int) {
        let (count, bytes) = try Int.unpack(data: data)
        var offset = bytes
        guard data.count >= offset + count else {
            throw UnpackError.needsMoreData(offset + count - data.count)
        }
        let stringData = data[offset..<offset+count]
        offset += count
        guard let string = String(data: stringData, encoding: .utf8)
        else {
            throw UnpackError.failed
        }
        return (string, offset)
    }
}
