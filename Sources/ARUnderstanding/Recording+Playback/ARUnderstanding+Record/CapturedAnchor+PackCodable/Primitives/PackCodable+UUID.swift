//
//  File.swift
//  ARUnderstanding
//
//  Created by John Haney on 2/22/25.
//

import Foundation

extension UUID: PackEncodable {
    public func pack() throws -> Data {
        let uuid = uuid
        return Data([
            uuid.0,
            uuid.1,
            uuid.2,
            uuid.3,
            uuid.4,
            uuid.5,
            uuid.6,
            uuid.7,
            uuid.8,
            uuid.9,
            uuid.10,
            uuid.11,
            uuid.12,
            uuid.13,
            uuid.14,
            uuid.15,
        ])
    }
}

extension UUID: PackDecodable {
    public static func unpack(data: Data) throws -> (UUID, Int) {
        guard data.count >= 16 else { throw UnpackError.needsMoreData(16) }
        let uuid: uuid_t = (
            data[data.startIndex + 0],
            data[data.startIndex + 1],
            data[data.startIndex + 2],
            data[data.startIndex + 3],
            data[data.startIndex + 4],
            data[data.startIndex + 5],
            data[data.startIndex + 6],
            data[data.startIndex + 7],
            data[data.startIndex + 8],
            data[data.startIndex + 9],
            data[data.startIndex + 10],
            data[data.startIndex + 11],
            data[data.startIndex + 12],
            data[data.startIndex + 13],
            data[data.startIndex + 14],
            data[data.startIndex + 15]
            )
        return (UUID(uuid: uuid), 16)
    }
}
